`timescale 1ns/1ps

module addr_decode #(
    parameter ADDR_WIDTH = 32,
    parameter S = 2,
    parameter SLICE_SIZE = 32'h00010000
)(
    input [ADDR_WIDTH-1:0] addr,
    output [$clog2(S)-1:0] sel
);

assign sel = addr / SLICE_SIZE;

endmodule
