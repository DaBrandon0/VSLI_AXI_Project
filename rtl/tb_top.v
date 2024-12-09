`timescale 1ns/1ps

module tb_top;

localparam BUS_WIDTH = 32;

reg clk;
reg clr;
reg M0R_fifo_write0;
reg M0R_fifo_write1;
reg               M0R_tag_in0;
reg               M0R_tag_in1;
reg [BUS_WIDTH-1:0]M0R_address_in0;
reg [BUS_WIDTH-1:0]M0R_address_in1;
reg [3:0]         M0R_len_in0;
reg [3:0]         M0R_len_in1;
reg [1:0]         M0R_size_in0;
reg [1:0]         M0R_size_in1;
reg [1:0]         M0R_burst_in0;
reg [1:0]         M0R_burst_in1;
reg [1:0]         M0R_lock_in0;
reg [1:0]         M0R_lock_in1;
reg [3:0]         M0R_cache_in0;
reg [3:0]         M0R_cache_in1;
reg [2:0]         M0R_prot_in0;
reg [2:0]         M0R_prot_in1;
wire [BUS_WIDTH-1 : 0] M0R_address_out;
wire                  M0R_memread;
wire [BUS_WIDTH-1:0]    M0R_data_in;

localparam byte1 = 2'b00;
localparam byte2 = 2'b01;
localparam byte4 = 2'b10;

localparam transfer1 = 2'b00;
localparam transfer2 = 2'b01;
localparam transfer3 = 2'b10;
localparam transfer4 = 2'b11;

always #5 clk = ~clk;
initial begin
    clk = 1;
    clr = 0;

    //reads 4 transfers of size 16 bytes from addy x00
    //reads mem[0]-mem[8]
    M0R_tag_in0 = 0;
    M0R_address_in0 = 32'h00000000;
    M0R_len_in0 = 3;
    M0R_size_in0 = 1;
    M0R_burst_in0 = 1; //incr
    M0R_lock_in0 = 1;
    M0R_cache_in0 = 1;
    M0R_prot_in0 = 1;
    M0R_fifo_write0 = 1;

    //reads 3 transfers of size 4 bytes from addy x08
    //reads mem[8]-mem[19]
    M0R_tag_in1 = 1;
    M0R_address_in1 = 32'h00000008;
    M0R_len_in1 = 2;
    M0R_size_in1 = 2; 
    M0R_burst_in1 = 1; //incr
    M0R_lock_in1 = 2;
    M0R_cache_in1 = 2;
    M0R_prot_in1 = 2;
    M0R_fifo_write1 = 1;
    #20
    clr = 1; //begin
    #10;

    //second part of test case
    //4 transfers size 1 byte from address #d20
    M0R_fifo_write0 = 0;
    M0R_tag_in0 = 0;
    M0R_address_in0 = 32'h00000014;
    M0R_len_in0 = 2;
    M0R_size_in0 = 0;
    M0R_burst_in0 = 1; //incr
    M0R_lock_in0 = 1;
    M0R_cache_in0 = 1;
    M0R_prot_in0 = 1;
    M0R_fifo_write0 = 1;

    //2 transfers size 4 bytes from address #d30
    M0R_fifo_write1 = 0;
    M0R_tag_in1 = 1;
    M0R_address_in1 = 32'h0000001E;
    M0R_len_in1 = 1;
    M0R_size_in1 = 2; 
    M0R_burst_in1 = 1; //incr
    M0R_lock_in1 = 2;
    M0R_cache_in1 = 2;
    M0R_prot_in1 = 2;
    M0R_fifo_write1 = 1;
    #10;

    M0R_fifo_write0 = 0;
    M0R_fifo_write1 = 0;
    #600;
    $stop;
end

// slave 0 memory
Memory Memory_inst (
    .CS(M0R_memread),
    .WE(0),
    .CLK(clk),
    .WADDR(0),
    .RADDR(M0R_address_out[6:0]),
    .Mem_in(0),
    .Mem_out(M0R_data_in),
    .writefinish()
);

// top
top #(
    .M(2),
    .S(2),
    .NUM_OUTSTANDING_TRANS(2),
    .BUS_WIDTH(BUS_WIDTH),
    .ID_WIDTH(1),
    .ADDR_WIDTH(32)
) top_inst (
    .clk(clk),
    .clr(clr),
    .M0R_fifo_write0(M0R_fifo_write0),
    .M0R_fifo_write1(M0R_fifo_write1),
    .M0R_tag_in0(M0R_tag_in0),
    .M0R_tag_in1(M0R_tag_in1),
    .M0R_address_in0(M0R_address_in0),
    .M0R_address_in1(M0R_address_in1),
    .M0R_len_in0(M0R_len_in0),
    .M0R_len_in1(M0R_len_in1),
    .M0R_size_in0(M0R_size_in0),
    .M0R_size_in1(M0R_size_in1),
    .M0R_burst_in0(M0R_burst_in0),
    .M0R_burst_in1(M0R_burst_in1),
    .M0R_lock_in0(M0R_lock_in0),
    .M0R_lock_in1(M0R_lock_in1),
    .M0R_cache_in0(M0R_cache_in0),
    .M0R_cache_in1(M0R_cache_in1),
    .M0R_prot_in0(M0R_prot_in0),
    .M0R_prot_in1(M0R_prot_in1),
    .M0R_address_out(M0R_address_out),
    .M0R_memread(M0R_memread),
    .M0R_data_in(M0R_data_in)
);

endmodule
