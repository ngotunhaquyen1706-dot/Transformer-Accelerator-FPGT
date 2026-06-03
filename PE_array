// ============================================================================
// PE Array
// ----------------------------------------------------------------------------
// Top-level systolic array consisting of array_m rows and array_n columns.
//
// Data flow:
//   - Activations (x) enter from the left side.
//   - Weights are preloaded into each PE.
//   - Partial sums propagate vertically through PE rows.
//   - Final accumulated results are aligned and exported through PE_out_packed.
//
// Matrix multiplication behavior:
//
//          W00 W01 W02 ...
// X0  -->  PE  PE  PE
// X1  -->  PE  PE  PE
// X2  -->  PE  PE  PE
// ...
//
// Each PE performs:
//      psum_out = psum_in + x * w
//
// ============================================================================

module PE_array
(
    clk,
    rst_n,
    set_w,
    x_packed,
    w_packed,
    PE_out_packed
);

parameter integer data_width = 8;
parameter integer array_m = 16;          // Number of PE rows
parameter integer array_n = 16;          // Number of PE columns
parameter integer log2_array_m = 4;

input wire clk;
input wire rst_n;
input wire set_w;

// Packed activation inputs
// Contains array_m activations
input [data_width*array_m-1:0] x_packed;

// Packed weight matrix
// Contains array_m × array_n weights
input [array_m*array_n*data_width-1:0] w_packed;

// Final output vector
output [array_n*(log2_array_m+data_width*2)-1:0] PE_out_packed;

// --------------------------------------------------------------------------
// Internal Signals

// Weight vector for each PE row
wire [array_n*data_width-1:0] w_line_array [array_m-1:0];

// Partial sum buses between PE rows
// psum_in_packed_array[0] is initialized to zero
wire [array_n*(log2_array_m+data_width*2)-1:0]
     psum_in_packed_array [array_m:0];

// Unpacked activation inputs
wire [data_width-1:0] x_array [array_m-1:0];

// Final accumulated results from the last PE row
wire [array_n*(log2_array_m+data_width*2)-1:0]
     psum_in_packed_last;

assign psum_in_packed_last = psum_in_packed_array[array_m];

genvar i;

generate
    for(i=array_n-1;i>=0;i=i-1) begin : buf_out

        // Rightmost column already has the maximum latency
        // No extra delay is required.
        if(i==array_n-1) begin

            assign PE_out_packed[
                (log2_array_m+data_width*2)*i +:
                (log2_array_m+data_width*2)
            ] =
            psum_in_packed_last[
                (log2_array_m+data_width*2)*i +:
                (log2_array_m+data_width*2)
            ];

        end
        else begin

            // Delay chain used to synchronize outputs
            // from earlier columns.
            reg [(log2_array_m+data_width*2)-1:0]
                out_buf [array_n-2-i:0];

            always @(posedge clk or negedge rst_n) begin
                if(~rst_n)
                    out_buf[0] <= 0;
                else
                    out_buf[0] <=
                        psum_in_packed_last[
                            i*(log2_array_m+data_width*2) +:
                            (log2_array_m+data_width*2)
                        ];
            end

            genvar k;

            // Additional pipeline stages
            for(k=1;k<=array_n-2-i;k=k+1)
            begin : out_buf_for

                always @(posedge clk or negedge rst_n) begin
                    if(~rst_n)
                        out_buf[k] <= 0;
                    else
                        out_buf[k] <= out_buf[k-1];
                end
            end

            assign PE_out_packed[
                i*(log2_array_m+data_width*2) +:
                (log2_array_m+data_width*2)
            ] = out_buf[array_n-2-i];

        end
    end
endgenerate

// --------------------------------------------------------------------------
// First partial sums are initialized to zero
assign psum_in_packed_array[0] = 0;

// --------------------------------------------------------------------------
// Unpack x inputs and weight rows
generate
    for(i=0;i<array_m;i=i+1)
    begin : packed_to_array_1

        // Extract activation for row i
        assign x_array[i] =
            x_packed[data_width*i +: data_width];

        // Extract weight vector for row i
        assign w_line_array[i] =
            w_packed[
                (array_n*data_width)*i +:
                (array_n*data_width)
            ];
    end
endgenerate

// --------------------------------------------------------------------------
// Instantiate PE rows

generate

    for(i=0; i<array_m; i=i+1)
    begin : array

        // --------------------------------------------------------------
        // First row receives activations directly
        if(i==0) begin

            PE_line #(
                .data_width(data_width),
                .array_m(array_m),
                .array_n(array_n),
                .log2_array_m(log2_array_m)
            )
            PE_Line_u
            (
                .clk(clk),
                .rst_n(rst_n),
                .set_w(set_w),

                .x(x_array[i]),

                .psum_in_packed(
                    psum_in_packed_array[i]
                ),

                .w_packed(
                    w_line_array[i]
                ),

                .psum_out_packed(
                    psum_in_packed_array[i+1]
                )
            );

        end

        // --------------------------------------------------------------
        // Remaining rows require input delays to maintain systolic timing. Row i receives x delayed by i cycles.
        else begin

            reg [data_width-1:0] x_buf [i-1:0];

            always @(posedge clk or negedge rst_n) begin
                if(~rst_n)
                    x_buf[0] <= 0;
                else
                    x_buf[0] <= x_array[i];
            end

            genvar k;

            // Delay pipeline
            for(k=1;k<=i-1;k=k+1)
            begin : x_buf_for

                always @(posedge clk or negedge rst_n) begin
                    if(~rst_n)
                        x_buf[k] <= 0;
                    else
                        x_buf[k] <= x_buf[k-1];
                end
            end

            PE_line #(
                .data_width(data_width),
                .array_m(array_m),
                .array_n(array_n),
                .log2_array_m(log2_array_m)
            )
            PE_Line_u
            (
                .clk(clk),
                .rst_n(rst_n),
                .set_w(set_w),

                // Delayed activation input
                .x(x_buf[i-1]),

                // Partial sums from previous row
                .psum_in_packed(
                    psum_in_packed_array[i]
                ),

                // Weight vector for this row
                .w_packed(
                    w_line_array[i]
                ),

                // Output partial sums to next row
                .psum_out_packed(
                    psum_in_packed_array[i+1]
                )
            );

        end
    end
endgenerate

endmodule
