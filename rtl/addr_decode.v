`define S 2

module addr_decode #(
    parameter ADDR_WIDTH = 32
)(
    input [ADDR_WIDTH-1:0] addr,
    output [`S-1:0] sel
);

assign sel =    (addr < 32'h0000FFFF) ? 
                0 :
                1;

endmodule