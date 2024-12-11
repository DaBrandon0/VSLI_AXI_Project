//usage:
//FIFO inputs:
//2 separate fifos to write into. enable fifo_write0 or fifo_write1 for 1 cycle to send 1 entry.
//testbench will set each AR channel signal individually. *tag is 1 bit
//change from testRead testbench: no need to input 50 bit encoded AR data. i do it here.

//MEMORY ACCESS SIGNAL:
//connect the memory access signals to memory module.
//memory module coded to send data_in instantly back as long as memread is on.

//AR and R Channel stuff
//master and slave have names of "Master_out_" or "Slave_in_" for signal names
//interconnect must wire Master_out_signal to Slave_in_signal, and Slave_out_signal to Master_in_signal

`timescale 1ns/1ps
`define buswidth 32

module ReadMasterSlave
(
    input ACLK, 
    input ARESETn,

    //FIFO INPUT SIGNALS
    input fifo_write0,//2 signals for 2 separate fifos in each readmaster.
    input fifo_write1,
    //50 bit encoded transaction data for master
    input               tag_in0,        input               tag_in1,        //input is 1 bit tag
    input [`buswidth-1:0]address_in0,    input [`buswidth-1:0]address_in1,
    input [3:0]         len_in0,        input [3:0]         len_in1,        
    input [1:0]         size_in0,       input [1:0]         size_in1,
    input [1:0]         burst_in0,      input [1:0]         burst_in1,
    input [1:0]         lock_in0,       input [1:0]         lock_in1,
    input [3:0]         cache_in0,      input [3:0]         cache_in1,
    input [2:0]         prot_in0,       input [2:0]         prot_in1,

    //MEMORY ACCESS SIGNALS
    //slave sends address and read request out. 
    //requires data_in to instantly come back from memory module
    output [`buswidth-1 : 0] address_out,
    output                  memread,
    input [`buswidth-1:0]    data_in,
    
    //AR SIGNALS--------
    //Master
    output                 Master_out_ARID,             //IMPORTANT master out 1 bit ID
    output [`buswidth-1: 0] Master_out_ARADDR,
    output [3:0]           Master_out_ARLEN,
    output [1:0]           Master_out_ARSIZE,
    output [1:0]           Master_out_ARBURST,
    output [1:0]           Master_out_ARLOCK,
    output [3:0]           Master_out_ARCACHE,
    output [2:0]           Master_out_ARPROT,
    output Master_out_ARVALID,
    input  Master_in_ARREADY,
    //Slave
    input [1:0]            Slave_in_ARID,               //slave in 2 bit id
    input [`buswidth-1: 0]  Slave_in_ARADDR,
    input [3:0]            Slave_in_ARLEN,
    input [1:0]            Slave_in_ARSIZE,
    input [1:0]            Slave_in_ARBURST,
    input [1:0]            Slave_in_ARLOCK,
    input [3:0]            Slave_in_ARCACHE,
    input [2:0]            Slave_in_ARPROT,
    input Slave_in_ARVALID,
    output Slave_out_ARREADY,

    //DATA SIGNALS--------
    //Master
    input                  Master_in_RID,
    input [`buswidth - 1:0] Master_in_RDATA,
    input                  Master_in_RLAST,
    input [1:0]            Master_in_RRESP,
    input  Master_in_RVALID,
    output Master_out_RREADY,

    //Slave
    output [1:0]            Slave_out_RID,
    output [`buswidth - 1:0] Slave_out_RDATA,
    output                  Slave_out_RLAST,
    output [1:0]            Slave_out_RRESP,
    output Slave_out_RVALID,
    input  Slave_in_RREADY

);  
wire [49:0] AR_fifo_in0, AR_fifo_in1;
assign AR_fifo_in0 = {tag_in0, address_in0, len_in0, size_in0, burst_in0, lock_in0, cache_in0, prot_in0};
assign AR_fifo_in1 = {tag_in1, address_in1, len_in1, size_in1, burst_in1, lock_in1, cache_in1, prot_in1};

ReadMaster readmaster(
.ACLK(ACLK),
.ARESETn(ARESETn),

.fifo_write0(fifo_write0),
.fifo_write1(fifo_write1),
.AR_fifo_in0(AR_fifo_in0),
.AR_fifo_in1(AR_fifo_in1),

.ARID(Master_out_ARID),
.ARADDR(Master_out_ARADDR),
.ARLEN(Master_out_ARLEN),
.ARSIZE(Master_out_ARSIZE),
.ARBURST(Master_out_ARBURST),
.ARLOCK(Master_out_ARLOCK),
.ARCACHE(Master_out_ARCACHE),
.ARPROT(Master_out_ARPROT),

.ARVALID(Master_out_ARVALID),
.ARREADY(Master_in_ARREADY),

.RID(Master_in_RID),
.RDATA(Master_in_RDATA),
.RRESP(Master_in_RRESP),
.RLAST(Master_in_RLAST),
.RVALID(Master_in_RVALID),
.RREADY(Master_out_RREADY)
);

ReadSlave readslave(
.ACLK(ACLK),
.ARESETn(ARESETn),

.address_out(address_out),
.memread(memread),
.data_in(data_in),

.ARID(Slave_in_ARID),
.ARADDR(Slave_in_ARADDR),
.ARLEN(Slave_in_ARLEN),
.ARSIZE(Slave_in_ARSIZE),
.ARBURST(Slave_in_ARBURST),
.ARLOCK(Slave_in_ARLOCK),
.ARCACHE(Slave_in_ARCACHE),
.ARPROT(Slave_in_ARPROT),

.ARVALID(Slave_in_ARVALID),
.ARREADY(Slave_out_ARREADY),

.RID(Slave_out_RID),
.RDATA(Slave_out_RDATA),
.RRESP(Slave_out_RRESP),
.RLAST(Slave_out_RLAST),

.RVALID(Slave_out_RVALID),
.RREADY(Slave_in_RREADY)
);
endmodule
