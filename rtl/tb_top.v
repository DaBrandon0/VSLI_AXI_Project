`timescale 1ns/1ps

module tb_top;

localparam BUS_WIDTH = 32;

// global signals
reg clk;
reg clr;

// master 0 read request
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

// master 0 write request
reg M0W_memoryWrite;
reg [31:0] M0W_datawrite;
reg [31:0] M0W_addresswrite;
reg [3:0] M0W_ID;
reg [3:0] M0W_WID;
reg [3:0] M0W_WLEN;
reg [2:0] M0W_WSIZE;
reg [1:0] M0W_WBURST;
reg [1:0] M0W_WLOCK;
reg [3:0] M0W_WCACHE;
reg [2:0] M0W_WPROT;
wire M0W_writeavail;
wire [31:0] M0W_Dataout;
wire [31:0] M0W_addressout;
wire M0W_finishwrite;

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

initial begin
    M0W_datawrite = 32'd1;
    M0W_addresswrite = 32'd2;
    M0W_ID = 4'd0;
    M0W_WID = 4'd0;
    M0W_WLEN = 4'd3;
    M0W_WSIZE = 3'b101;
    M0W_WBURST = 2'b00;
    M0W_WLOCK = 2'b00;
    M0W_WCACHE = 4'b0000;
    M0W_WPROT = 3'b000;
    M0W_memoryWrite = 0;
    #30 M0W_memoryWrite = 1;
    #30 M0W_memoryWrite = 0;
    M0W_datawrite = 32'd2;
    #30 M0W_memoryWrite = 1;
    #30 M0W_memoryWrite = 0;
    M0W_datawrite = 32'd3;
    #30 M0W_memoryWrite = 1;
    #30 M0W_memoryWrite = 0;
end

// slave 0 memory
Memory Memory_inst (
    .CS(M0R_memread),
    .WE(M0W_writeavail),
    .CLK(clk),
    .WADDR(M0W_addressout),
    .RADDR(M0R_address_out[6:0]),
    .Mem_in(M0W_Dataout),
    .Mem_out(M0R_data_in),
    .writefinish(M0W_finishwrite)
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

    //master 0 read request
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

    // master 0 write request
    .M0W_memoryWrite(M0W_memoryWrite),
    .M0W_datawrite(M0W_datawrite),
    .M0W_addresswrite(M0W_addresswrite),
    .M0W_ID(M0W_ID),
    .M0W_WID(M0W_WID),
    .M0W_WLEN(M0W_WLEN),
    .M0W_WSIZE(M0W_WSIZE),
    .M0W_WBURST(M0W_WBURST),
    .M0W_WLOCK(M0W_WLOCK),
    .M0W_WCACHE(M0W_WCACHE),
    .M0W_WPROT(M0W_WPROT),

    // master 0 read memory signals
    .M0R_address_out(M0R_address_out),
    .M0R_memread(M0R_memread),
    .M0R_data_in(M0R_data_in),

    // master 0 write memory signals
    .M0W_writeavail(M0W_writeavail),
    .M0W_Dataout(M0W_Dataout),
    .M0W_addressout(M0W_addressout),
    .M0W_finishwrite(M0W_finishwrite)
);

endmodule
