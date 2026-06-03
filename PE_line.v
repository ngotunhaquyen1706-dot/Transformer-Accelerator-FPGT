// PE Line
// A horizontal chain of Processing Elements (PEs).
// The input activation x propagates from left to right, while each PE independently performs a MAC operation, using its own weight and partial sum input.

module PE_line
#(
    parameter array_m = 4,                  // Number of rows in systolic array
    parameter array_n = 4,                  // Number of PEs in this line
    parameter data_width = 8,               // Data and weight bit width
    parameter log2_array_m = 2              // log2(array_m), used for accumulator width
)
(
    input                                               clk,                // System clock
    input                                               rst_n,              // Active-low reset
    input                                               set_w,              // Weight loading enable

    input [data_width-1:0]                              x,                  // Input activation

    // Packed partial sum inputs for all PEs
    input [array_n*(log2_array_m+data_width*2)-1:0]     psum_in_packed,

    // Packed weights for all PEs
    input [array_n*data_width-1:0] w_packed,

    // Packed partial sum outputs from all PEs
    output [array_n*(log2_array_m+data_width*2)-1:0]    psum_out_packed
);

// Unpacked partial sum inputs
wire [2*data_width+log2_array_m-1:0] psum_in_array [array_n-1:0];

// Unpacked partial sum outputs
wire [2*data_width+log2_array_m-1:0] psum_out_array [array_n-1:0];

// Unpacked weights
wire [data_width-1:0] w_array [array_n-1:0];

// Internal activation propagation path
// x_array[0] receives external input x
// x_array[i+1] receives output from PE[i]
wire [data_width-1:0] x_array [array_n:0];

// First activation input enters the first PE
assign x_array[0] = x;

genvar i;

// ------------------------------------------------------------------
// Unpack input buses into arrays and pack output arrays into buses
generate
    for(i=0;i<array_n;i=i+1) begin : packed_to_array_1

        // Extract weight for PE[i]
        assign w_array[i] = w_packed[data_width*i +: data_width];

        // Extract partial sum input for PE[i]
        assign psum_in_array[i] = psum_in_packed[(log2_array_m+data_width*2)*i +:
                           (log2_array_m+data_width*2)];

        // Pack partial sum output from PE[i]
        assign psum_out_packed[(log2_array_m+data_width*2)*i +:
                               (log2_array_m+data_width*2)] =
                               psum_out_array[i];
    end
endgenerate

// ------------------------------------------------------------------
// Instantiate a row of PEs
//
// Data flow:
// x --> PE0 --> PE1 --> PE2 --> ... --> PEn
//
// Each PE:
// psum_out = psum_in + x * weight
// ------------------------------------------------------------------
generate
    for(i=0;i<array_n;i=i+1) begin : array_line

        PE #(
            .data_width(data_width),
            .array_m(array_m),
            .array_n(array_n),
            .log2_array_m(log2_array_m)
        )
        PE_u (
            .clk(clk),
            .set_w(set_w),
            .rst_n(rst_n),

            // Activation from previous PE
            .x_in(x_array[i]),

            // Local weight
            .w(w_array[i]),

            // Partial sum input
            .psum_in(psum_in_array[i]),

            // Activation forwarded to next PE
            .x_out(x_array[i+1]),

            // Updated partial sum output
            .psum_out(psum_out_array[i])
        );
    end
endgenerate

endmodule
