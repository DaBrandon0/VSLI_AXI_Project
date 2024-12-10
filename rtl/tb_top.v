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
reg [3:0] M0W_WID;
reg [3:0] M0W_AWID;
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

// master 1 read request
reg M1R_fifo_write0;
reg M1R_fifo_write1;
reg               M1R_tag_in0;
reg               M1R_tag_in1;
reg [BUS_WIDTH-1:0]M1R_address_in0;
reg [BUS_WIDTH-1:0]M1R_address_in1;
reg [3:0]         M1R_len_in0;
reg [3:0]         M1R_len_in1;
reg [1:0]         M1R_size_in0;
reg [1:0]         M1R_size_in1;
reg [1:0]         M1R_burst_in0;
reg [1:0]         M1R_burst_in1;
reg [1:0]         M1R_lock_in0;
reg [1:0]         M1R_lock_in1;
reg [3:0]         M1R_cache_in0;
reg [3:0]         M1R_cache_in1;
reg [2:0]         M1R_prot_in0;
reg [2:0]         M1R_prot_in1;
wire [BUS_WIDTH-1 : 0] M1R_address_out;
wire                  M1R_memread;
wire [BUS_WIDTH-1:0]    M1R_data_in;

// master 1 write request
reg M1W_memoryWrite;
reg [31:0] M1W_datawrite;
reg [31:0] M1W_addresswrite;
reg [3:0] M1W_WID;
reg [3:0] M1W_AWID;
reg [3:0] M1W_WLEN;
reg [2:0] M1W_WSIZE;
reg [1:0] M1W_WBURST;
reg [1:0] M1W_WLOCK;
reg [3:0] M1W_WCACHE;
reg [2:0] M1W_WPROT;
wire M1W_writeavail;
wire [31:0] M1W_Dataout;
wire [31:0] M1W_addressout;
wire M1W_finishwrite;

// global signals
always #5 clk = ~clk;
initial begin
    clk = 1;
    clr = 0;
    #20 clr = 1;
end

// master 0 read requests
initial begin

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
    #20;
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
    #6000;
    $stop;
end

// master 0 write requests
initial begin
    M0W_datawrite = 32'd1;
    M0W_addresswrite = 32'd2;
    M0W_WID = 4'd2;
    M0W_AWID = 4'd4;
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

// master 1 read requests
initial begin

    //reads 4 transfers of size 16 bytes from addy x00
    //reads mem[0]-mem[8]
    M1R_tag_in0 = 0;
    M1R_address_in0 = 32'h00000000;
    M1R_len_in0 = 3;
    M1R_size_in0 = 1;
    M1R_burst_in0 = 1; //incr
    M1R_lock_in0 = 1;
    M1R_cache_in0 = 1;
    M1R_prot_in0 = 1;
    M1R_fifo_write0 = 1;

    //reads 3 transfers of size 4 bytes from addy x08
    //reads mem[8]-mem[19]
    M1R_tag_in1 = 1;
    M1R_address_in1 = 32'h00000008;
    M1R_len_in1 = 2;
    M1R_size_in1 = 2; 
    M1R_burst_in1 = 1; //incr
    M1R_lock_in1 = 2;
    M1R_cache_in1 = 2;
    M1R_prot_in1 = 2;
    M1R_fifo_write1 = 1;
    #20;
    #10;

    //second part of test case
    //4 transfers size 1 byte from address #d20
    M1R_fifo_write0 = 0;
    M1R_tag_in0 = 0;
    M1R_address_in0 = 32'h00000014;
    M1R_len_in0 = 2;
    M1R_size_in0 = 0;
    M1R_burst_in0 = 1; //incr
    M1R_lock_in0 = 1;
    M1R_cache_in0 = 1;
    M1R_prot_in0 = 1;
    M1R_fifo_write0 = 1;

    //2 transfers size 4 bytes from address #d30
    M1R_fifo_write1 = 0;
    M1R_tag_in1 = 1;
    M1R_address_in1 = 32'h0000001E;
    M1R_len_in1 = 1;
    M1R_size_in1 = 2; 
    M1R_burst_in1 = 1; //incr
    M1R_lock_in1 = 2;
    M1R_cache_in1 = 2;
    M1R_prot_in1 = 2;
    M1R_fifo_write1 = 1;
    #10;

    M1R_fifo_write0 = 0;
    M1R_fifo_write1 = 0;
    #6000;
    $stop;
end

// master 1 write requests
initial begin
    M1W_datawrite = 32'd1;
    M1W_addresswrite = 32'd2;
    M1W_WID = 4'd2;
    M1W_AWID = 4'd4;
    M1W_WLEN = 4'd3;
    M1W_WSIZE = 3'b101;
    M1W_WBURST = 2'b00;
    M1W_WLOCK = 2'b00;
    M1W_WCACHE = 4'b0000;
    M1W_WPROT = 3'b000;
    M1W_memoryWrite = 0;
    #30 M1W_memoryWrite = 1;
    #30 M1W_memoryWrite = 0;
    M1W_datawrite = 32'd2;
    #30 M1W_memoryWrite = 1;
    #30 M1W_memoryWrite = 0;
    M1W_datawrite = 32'd3;
    #30 M1W_memoryWrite = 1;
    #30 M1W_memoryWrite = 0;
end

// slave 0 memory
Memory Memory_inst0 (
    .CS(1),
    .WE(M0W_writeavail),
    .CLK(clk),
    .WADDR(M0W_addressout),
    .RADDR(M0R_address_out[6:0]),
    .Mem_in(M0W_Dataout),
    .Mem_out(M0R_data_in),
    .writefinish(M0W_finishwrite)
);

// slave 1 memory
Memory Memory_inst1 (
    .CS(1),
    .WE(M1W_writeavail),
    .CLK(clk),
    .WADDR(M1W_addressout),
    .RADDR(M1R_address_out[6:0]),
    .Mem_in(M1W_Dataout),
    .Mem_out(M1R_data_in),
    .writefinish(M1W_finishwrite)
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

    // master 0 read request
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
    .M0W_WID(M0W_WID),
    .M0W_AWID(M0W_AWID),
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
    .M0W_finishwrite(M0W_finishwrite),

    // master 1 read request
    .M1R_fifo_write0(M1R_fifo_write0),
    .M1R_fifo_write1(M1R_fifo_write1),
    .M1R_tag_in0(M1R_tag_in0),
    .M1R_tag_in1(M1R_tag_in1),
    .M1R_address_in0(M1R_address_in0),
    .M1R_address_in1(M1R_address_in1),
    .M1R_len_in0(M1R_len_in0),
    .M1R_len_in1(M1R_len_in1),
    .M1R_size_in0(M1R_size_in0),
    .M1R_size_in1(M1R_size_in1),
    .M1R_burst_in0(M1R_burst_in0),
    .M1R_burst_in1(M1R_burst_in1),
    .M1R_lock_in0(M1R_lock_in0),
    .M1R_lock_in1(M1R_lock_in1),
    .M1R_cache_in0(M1R_cache_in0),
    .M1R_cache_in1(M1R_cache_in1),
    .M1R_prot_in0(M1R_prot_in0),
    .M1R_prot_in1(M1R_prot_in1),

    // master 1 write request
    .M1W_memoryWrite(M1W_memoryWrite),
    .M1W_datawrite(M1W_datawrite),
    .M1W_addresswrite(M1W_addresswrite),
    .M1W_WID(M1W_WID),
    .M1W_AWID(M1W_AWID),
    .M1W_WLEN(M1W_WLEN),
    .M1W_WSIZE(M1W_WSIZE),
    .M1W_WBURST(M1W_WBURST),
    .M1W_WLOCK(M1W_WLOCK),
    .M1W_WCACHE(M1W_WCACHE),
    .M1W_WPROT(M1W_WPROT),

    // master 1 read memory signals
    .M1R_address_out(M1R_address_out),
    .M1R_memread(M1R_memread),
    .M1R_data_in(M1R_data_in),

    // master 1 write memory signals
    .M1W_writeavail(M1W_writeavail),
    .M1W_Dataout(M1W_Dataout),
    .M1W_addressout(M1W_addressout),
    .M1W_finishwrite(M1W_finishwrite)
);

endmodule
