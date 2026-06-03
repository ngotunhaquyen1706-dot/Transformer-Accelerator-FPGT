// Processing Element (PE)
// Performs Multiply-Accumulate (MAC) operation:
// psum_out = psum_in + x_in * weight
// dataflow: WS
module PE
#(
    parameter data_width = 8,     // Width of input data and weight
    parameter array_m = 16,       // Number of rows in PE array
    parameter array_n = 16,       // Number of columns in PE array
    parameter log2_array_m = 4    // log2(array_m), used for accumulator width
)
(
    input                                              clk,        // System clock
    input                                              set_w,      // Weight loading enable
    input                                              rst_n,      // Active-low reset

    input signed [data_width-1:0]                      x_in,       // Input activation
    input signed [data_width-1:0]                      w,          // Input weight

    input signed [2*data_width+log2_array_m-1:0]       psum_in,    // Incoming partial sum

    output reg signed [data_width-1:0]                 x_out,      // Forwarded activation
    output reg signed [2*data_width+log2_array_m-1:0]  psum_out    // Updated partial sum
);

// Internal register to store the weight value
reg signed [data_width-1:0] reg_w;

// Sequential logic
always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        // Reset all registers
        psum_out <= 0;
        reg_w    <= 0;
        x_out    <= 0;
    end
    else begin
        // Load weight into local register when enabled
        if(set_w)
            reg_w <= w;

        // Multiply-Accumulate (MAC) operation
        // Add product of input activation and stored weight to the incoming partial sum
        psum_out <= psum_in + x_in * reg_w;
        // Forward input activation to the next PE
        x_out <= x_in;
    end
end

endmodule
