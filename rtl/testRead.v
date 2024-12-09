`timescale 1ns/1ps

module testRead();
localparam buswidth = 32;
localparam master_tags = 1;
localparam slave_tags = 2;
reg                 ACLK;
reg                 ARESETn;
//FIFO testbench signals
reg fifo_write0;
reg fifo_write1;
reg [master_tags-1:0] tag_in0;        reg [master_tags-1:0] tag_in1;
reg [buswidth-1:0]    address_in0;    reg [buswidth-1:0]    address_in1;
reg [3:0]             len_in0;        reg [3:0]             len_in1;
reg [1:0]             size_in0;       reg [1:0]             size_in1;
reg [1:0]             burst_in0;      reg [1:0]             burst_in1;
reg [1:0]             lock_in0;       reg [1:0]             lock_in1;
reg [3:0]             cache_in0;      reg [3:0]             cache_in1;
reg [2:0]             prot_in0;       reg [2:0]             prot_in1;

//outputs from slave to device
wire [buswidth-1 : 0] address_out;
wire                  memread;
wire [buswidth-1:0]    data_in;
wire [6:0] dummy0;
wire [31:0] dummy1;
wire writefinish;
//write address, mem_in, and writefinish not connected (high impedence)
Memory mem(memread, !memread, ACLK, dummy0, address_out[6:0], dummy1, data_in, writefinish);

//AR wires
wire Master_out_ARID;
wire [1:0] Slave_in_ARID = {0, Master_out_ARID};
wire Master_in_RID = Slave_out_RID[0];
wire [1:0] Slave_out_RID;

wire [buswidth-1: 0]    ARADDR;
wire [3:0]              ARLEN;
wire [1:0]              ARSIZE;
wire [1:0]              ARBURST;
wire [1:0]              ARLOCK;
wire [3:0]              ARCACHE;
wire [2:0]              ARPROT;
//R Data Channel Signals
wire [slave_tags:0]      RID;
wire [buswidth - 1:0]   RDATA;
wire                    RLAST;
wire [1:0]              RRESP;

//handshaking wires
wire RVALID;
wire RREADY;
wire ARVALID;
wire ARREADY;

localparam byte1 = 2'b00;
localparam byte2 = 2'b01;
localparam byte4 = 2'b10;

localparam transfer1 = 2'b00;
localparam transfer2 = 2'b01;
localparam transfer3 = 2'b10;
localparam transfer4 = 2'b11;


always #5 ACLK = ~ACLK;
//test case 2
initial begin
    ACLK = 1;
    ARESETn = 0;

    //reads 4 transfers of size 16 bytes from addy x00
    //reads mem[0]-mem[8]
    tag_in0 = 0;
    address_in0 = 32'h00000000;
    len_in0 = 3;
    size_in0 = 1;
    burst_in0 = 1; //incr
    lock_in0 = 1;
    cache_in0 = 1;
    prot_in0 = 1;
    fifo_write0 = 1;

    //reads 3 transfers of size 4 bytes from addy x08
    //reads mem[8]-mem[19]
    tag_in1 = 1;
    address_in1 = 32'h00000008;
    len_in1 = 2;
    size_in1 = 2; 
    burst_in1 = 1; //incr
    lock_in1 = 2;
    cache_in1 = 2;
    prot_in1 = 2;
    fifo_write1 = 1;
    #20
    ARESETn = 1; //begin
    #10;

    //second part of test case
    //4 transfers size 1 byte from address #d20
    fifo_write0 = 0;
    tag_in0 = 0;
    address_in0 = 32'h00000014;
    len_in0 = 2;
    size_in0 = 0;
    burst_in0 = 1; //incr
    lock_in0 = 1;
    cache_in0 = 1;
    prot_in0 = 1;
    fifo_write0 = 1;

    //2 transfers size 4 bytes from address #d30
    fifo_write1 = 0;
    tag_in1 = 1;
    address_in1 = 32'h0000001E;
    len_in1 = 1;
    size_in1 = 2; 
    burst_in1 = 1; //incr
    lock_in1 = 2;
    cache_in1 = 2;
    prot_in1 = 2;
    fifo_write1 = 1;
    #10;

    fifo_write0 = 0;
    fifo_write1 = 0;
    #600;
    $stop;
end

ReadMasterSlave topread(
.ACLK(ACLK), 
.ARESETn(ARESETn),

.fifo_write0(fifo_write0),  .fifo_write1(fifo_write1),
.tag_in0(tag_in0),          .tag_in1(tag_in1),        //input is 1 bit tag
.address_in0(address_in0),  .address_in1(address_in1),
.len_in0(len_in0),          .len_in1(len_in1),        
.size_in0(size_in0),        .size_in1(size_in1),
.burst_in0(burst_in0),      .burst_in1(burst_in1),
.lock_in0(lock_in0),        .lock_in1(lock_in1),
.cache_in0(cache_in0),      .cache_in1(cache_in1),
.prot_in0(prot_in0),        .prot_in1(prot_in1),

.address_out(address_out),
.memread(memread),
.data_in(data_in),
    
//AR SIGNALS--------
//Master
.Master_out_ARID(Master_out_ARID),             //IMPORTANT master out 1 bit ID
.Master_out_ARADDR(ARADDR),
.Master_out_ARLEN(ARLEN),
.Master_out_ARSIZE(ARSIZE),
.Master_out_ARBURST(ARBURST),
.Master_out_ARLOCK(ARLOCK),
.Master_out_ARCACHE(ARCACHE),
.Master_out_ARPROT(ARPROT),
.Master_out_ARVALID(ARVALID),
.Master_in_ARREADY(ARREADY),
//Slave
.Slave_in_ARID(Slave_in_ARID),               //slave in 2 bit id //append
.Slave_in_ARADDR(ARADDR),
.Slave_in_ARLEN(ARLEN),
.Slave_in_ARSIZE(ARSIZE),
.Slave_in_ARBURST(ARBURST),
.Slave_in_ARLOCK(ARLOCK),
.Slave_in_ARCACHE(ARCACHE),
.Slave_in_ARPROT(ARPROT),
.Slave_in_ARVALID(ARVALID),
.Slave_out_ARREADY(ARREADY),
//DATA SIGNALS--------
//Master
.Master_in_RID(Master_in_RID),
.Master_in_RDATA(RDATA),
.Master_in_RLAST(RLAST),
.Master_in_RRESP(RRESP),
.Master_in_RVALID(RVALID),
.Master_out_RREADY(RREADY),
//Slave
.Slave_out_RID(Slave_out_RID),
.Slave_out_RDATA(RDATA),
.Slave_out_RLAST(RLAST),
.Slave_out_RRESP(RRESP),
.Slave_out_RVALID(RVALID),
.Slave_in_RREADY(RREADY)
);

endmodule


// //test case 1
// initial begin
//     ACLK = 1;
//     ARESETn = 0;

//     //reads 4 transfers of size 16 bytes from addy x00
//     //reads mem[0]-mem[8]
//     tag_in0 = 0;
//     address_in0 = 32'h00000000;
//     len_in0 = 3;
//     size_in0 = 1;
//     burst_in0 = 1; //incr
//     lock_in0 = 1;
//     cache_in0 = 1;
//     prot_in0 = 1;
//     fifo_write0 = 1;

//     //reads 3 transfers of size 4 bytes from addy x08
//     //reads mem[8]-mem[20]
//     tag_in1 = 1;
//     address_in1 = 32'h00000008;
//     len_in1 = 2;
//     size_in1 = 2; 
//     burst_in1 = 1; //incr
//     lock_in1 = 2;
//     cache_in1 = 2;
//     prot_in1 = 2;
//     fifo_write1 = 1;
//     #20
//     ARESETn = 1; //begin
//     #10;
//     fifo_write0 = 0;
//     fifo_write1 = 0;
//     #250;
//     $stop;
// end

// //test case 2
// initial begin
//     ACLK = 1;
//     ARESETn = 0;

//     //reads 4 transfers of size 16 bytes from addy x00
//     //reads mem[0]-mem[8]
//     tag_in0 = 0;
//     address_in0 = 32'h00000000;
//     len_in0 = 3;
//     size_in0 = 1;
//     burst_in0 = 1; //incr
//     lock_in0 = 1;
//     cache_in0 = 1;
//     prot_in0 = 1;
//     fifo_write0 = 1;

//     //reads 3 transfers of size 4 bytes from addy x08
//     //reads mem[8]-mem[20]
//     tag_in1 = 1;
//     address_in1 = 32'h00000008;
//     len_in1 = 2;
//     size_in1 = 2; 
//     burst_in1 = 1; //incr
//     lock_in1 = 2;
//     cache_in1 = 2;
//     prot_in1 = 2;
//     fifo_write1 = 1;
//     #20
//     ARESETn = 1; //begin
//     #10;

//     //second part of test case
//     //4 transfers size 1 byte from address #d20
//     fifo_write0 = 0;
//     tag_in0 = 0;
//     address_in0 = 32'h00000014;
//     len_in0 = 2;
//     size_in0 = 0;
//     burst_in0 = 1; //incr
//     lock_in0 = 1;
//     cache_in0 = 1;
//     prot_in0 = 1;
//     fifo_write0 = 1;

//     //2 transfers size 4 bytes from address #d30
//     fifo_write1 = 0;
//     tag_in1 = 1;
//     address_in1 = 32'h0000001E;
//     len_in1 = 1;
//     size_in1 = 2; 
//     burst_in1 = 1; //incr
//     lock_in1 = 2;
//     cache_in1 = 2;
//     prot_in1 = 2;
//     fifo_write1 = 1;
//     #10;

//     fifo_write0 = 0;
//     fifo_write1 = 0;
//     #600;
//     $stop;
// end


// //test case 3
// initial begin

//     ACLK = 1;
//     ARESETn = 0;

//     //reads 4 transfers of size 16 bytes from addy x00
//     //reads mem[0]-mem[8]
//     tag_in0 = 0;
//     address_in0 = 32'h00000000;
//     len_in0 = transfer4;
//     size_in0 = byte2;
//     burst_in0 = 1; //incr
//     lock_in0 = 1;
//     cache_in0 = 1;
//     prot_in0 = 1;
//     fifo_write0 = 1;
//     #10
//     ARESETn = 1; //begin
//     #10;
//     //second part of test case
//     //4 transfers size 1 byte from address #d20
//     fifo_write0 = 0;
//     tag_in0 = 0;
//     address_in0 = 32'h00000014;
//     len_in0 = transfer2;
//     size_in0 = byte4;
//     burst_in0 = 1; //incr
//     lock_in0 = 1;
//     cache_in0 = 1;
//     prot_in0 = 1;
//     fifo_write0 = 1;
//     #10;

//     fifo_write0 = 0;
//     fifo_write1 = 0;
//     #300;
//     $stop;
// end