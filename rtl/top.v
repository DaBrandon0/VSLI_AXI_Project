`timescale 1ns/1ps

module top #(
    parameter M = 2,
    parameter S = 2,
    parameter NUM_OUTSTANDING_TRANS = 2,
    parameter BUS_WIDTH = 32,
    parameter ID_WIDTH = 1,
    parameter ADDR_WIDTH = 32
)(
    input clk,
    input clr,

    // master 0 read request
    input M0R_fifo_write0,
    input M0R_fifo_write1,
    input               M0R_tag_in0,
    input               M0R_tag_in1,
    input [BUS_WIDTH-1:0]M0R_address_in0,
    input [BUS_WIDTH-1:0]M0R_address_in1,
    input [3:0]         M0R_len_in0,
    input [3:0]         M0R_len_in1,
    input [1:0]         M0R_size_in0,
    input [1:0]         M0R_size_in1,
    input [1:0]         M0R_burst_in0,
    input [1:0]         M0R_burst_in1,
    input [1:0]         M0R_lock_in0,
    input [1:0]         M0R_lock_in1,
    input [3:0]         M0R_cache_in0,
    input [3:0]         M0R_cache_in1,
    input [2:0]         M0R_prot_in0,
    input [2:0]         M0R_prot_in1,

    // master 0 write request
    input M0W_memoryWrite,
    input [31:0] M0W_datawrite,
    input [31:0] M0W_addresswrite,
    input [3:0] M0W_WID,
    input [3:0] M0W_AWID,
    input [3:0] M0W_WLEN,
    input [2:0] M0W_WSIZE,
    input [1:0] M0W_WBURST,
    input [1:0] M0W_WLOCK,
    input [3:0] M0W_WCACHE,
    input [2:0] M0W_WPROT,

    // master 0 read memory signals
    output [BUS_WIDTH-1 : 0] M0R_address_out,
    output                  M0R_memread,
    input [BUS_WIDTH-1:0]    M0R_data_in,

    // master 0 write memory signals
    output M0W_writeavail,
    output [31:0] M0W_Dataout,
    output [31:0] M0W_addressout,
    input M0W_finishwrite,

    // master 1 read request
    input M1R_fifo_write0,
    input M1R_fifo_write1,
    input               M1R_tag_in0,
    input               M1R_tag_in1,
    input [BUS_WIDTH-1:0]M1R_address_in0,
    input [BUS_WIDTH-1:0]M1R_address_in1,
    input [3:0]         M1R_len_in0,
    input [3:0]         M1R_len_in1,
    input [1:0]         M1R_size_in0,
    input [1:0]         M1R_size_in1,
    input [1:0]         M1R_burst_in0,
    input [1:0]         M1R_burst_in1,
    input [1:0]         M1R_lock_in0,
    input [1:0]         M1R_lock_in1,
    input [3:0]         M1R_cache_in0,
    input [3:0]         M1R_cache_in1,
    input [2:0]         M1R_prot_in0,
    input [2:0]         M1R_prot_in1,

    // master 0 write request
    input M1W_memoryWrite,
    input [31:0] M1W_datawrite,
    input [31:0] M1W_addresswrite,
    input [3:0] M1W_WID,
    input [3:0] M1W_AWID,
    input [3:0] M1W_WLEN,
    input [2:0] M1W_WSIZE,
    input [1:0] M1W_WBURST,
    input [1:0] M1W_WLOCK,
    input [3:0] M1W_WCACHE,
    input [2:0] M1W_WPROT,

    // master 1 read memory signals
    output [BUS_WIDTH-1 : 0] M1R_address_out,
    output                  M1R_memread,
    input [BUS_WIDTH-1:0]    M1R_data_in,

    // master 1 write memory signals
    output M1W_writeavail,
    output [31:0] M1W_Dataout,
    output [31:0] M1W_addressout,
    input M1W_finishwrite
);

// interconnect
wire [ID_WIDTH-1:0] M0_AWID;
wire [ADDR_WIDTH-1:0] M0_AWADDR;
wire [4-1:0] M0_AWLEN;
wire [3-1:0] M0_AWSIZE;
wire [2-1:0] M0_AWBURST;
wire [2-1:0] M0_AWLOCK;
wire [4-1:0] M0_AWCACHE;
wire [3-1:0] M0_AWPROT;
wire M0_AWVALID;
wire M0_AWREADY;
wire [ID_WIDTH-1:0] M1_AWID;
wire [ADDR_WIDTH-1:0] M1_AWADDR;
wire [4-1:0] M1_AWLEN;
wire [3-1:0] M1_AWSIZE;
wire [2-1:0] M1_AWBURST;
wire [2-1:0] M1_AWLOCK;
wire [4-1:0] M1_AWCACHE;
wire [3-1:0] M1_AWPROT;
wire M1_AWVALID;
wire M1_AWREADY;
wire [(ID_WIDTH+$clog2(M))-1:0] S0_AWID;
wire [ADDR_WIDTH-1:0] S0_AWADDR;
wire [4-1:0] S0_AWLEN;
wire [3-1:0] S0_AWSIZE;
wire [2-1:0] S0_AWBURST;
wire [2-1:0] S0_AWLOCK;
wire [4-1:0] S0_AWCACHE;
wire [3-1:0] S0_AWPROT;
wire S0_AWVALID;
wire S0_AWREADY;
wire [(ID_WIDTH+$clog2(M))-1:0] S1_AWID;
wire [ADDR_WIDTH-1:0] S1_AWADDR;
wire [4-1:0] S1_AWLEN;
wire [3-1:0] S1_AWSIZE;
wire [2-1:0] S1_AWBURST;
wire [2-1:0] S1_AWLOCK;
wire [4-1:0] S1_AWCACHE;
wire [3-1:0] S1_AWPROT;
wire S1_AWVALID;
wire S1_AWREADY;
wire [ID_WIDTH-1:0] M0_WID;
wire [BUS_WIDTH-1:0] M0_WDATA;
wire [4-1:0] M0_WSTRB;
wire M0_WLAST;
wire M0_WVALID;
wire M0_WREADY;
wire [ID_WIDTH-1:0] M1_WID;
wire [BUS_WIDTH-1:0] M1_WDATA;
wire [4-1:0] M1_WSTRB;
wire M1_WLAST;
wire M1_WVALID;
wire M1_WREADY;
wire [(ID_WIDTH+$clog2(M))-1:0] S0_WID;
wire [BUS_WIDTH-1:0] S0_WDATA;
wire [4-1:0] S0_WSTRB;
wire S0_WLAST;
wire S0_WVALID;
wire S0_WREADY;
wire [(ID_WIDTH+$clog2(M))-1:0] S1_WID;
wire [BUS_WIDTH-1:0] S1_WDATA;
wire [4-1:0] S1_WSTRB;
wire S1_WLAST;
wire S1_WVALID;
wire S1_WREADY;
wire [ID_WIDTH-1:0] M0_BID;
wire [2-1:0] M0_BRESP;
wire M0_BVALID;
wire M0_BREADY;
wire [ID_WIDTH-1:0] M1_BID;
wire [2-1:0] M1_BRESP;
wire M1_BVALID;
wire M1_BREADY;
wire [(ID_WIDTH+$clog2(M))-1:0] S0_BID;
wire [2-1:0] S0_BRESP;
wire S0_BVALID;
wire S0_BREADY;
wire [(ID_WIDTH+$clog2(M))-1:0] S1_BID;
wire [2-1:0] S1_BRESP;
wire S1_BVALID;
wire S1_BREADY;
wire [ID_WIDTH-1:0] M0_ARID;
wire [ADDR_WIDTH-1:0] M0_ARADDR;
wire [4-1:0] M0_ARLEN;
wire [3-1:0] M0_ARSIZE;
wire [2-1:0] M0_ARBURST;
wire [2-1:0] M0_ARLOCK;
wire [4-1:0] M0_ARCACHE;
wire [3-1:0] M0_ARPROT;
wire M0_ARVALID;
wire M0_ARREADY;
wire [ID_WIDTH-1:0] M1_ARID;
wire [ADDR_WIDTH-1:0] M1_ARADDR;
wire [4-1:0] M1_ARLEN;
wire [3-1:0] M1_ARSIZE;
wire [2-1:0] M1_ARBURST;
wire [2-1:0] M1_ARLOCK;
wire [4-1:0] M1_ARCACHE;
wire [3-1:0] M1_ARPROT;
wire M1_ARVALID;
wire M1_ARREADY;
wire [(ID_WIDTH+$clog2(M))-1:0] S0_ARID;
wire [ADDR_WIDTH-1:0] S0_ARADDR;
wire [4-1:0] S0_ARLEN;
wire [3-1:0] S0_ARSIZE;
wire [2-1:0] S0_ARBURST;
wire [2-1:0] S0_ARLOCK;
wire [4-1:0] S0_ARCACHE;
wire [3-1:0] S0_ARPROT;
wire S0_ARVALID;
wire S0_ARREADY;
wire [(ID_WIDTH+$clog2(M))-1:0] S1_ARID;
wire [ADDR_WIDTH-1:0] S1_ARADDR;
wire [4-1:0] S1_ARLEN;
wire [3-1:0] S1_ARSIZE;
wire [2-1:0] S1_ARBURST;
wire [2-1:0] S1_ARLOCK;
wire [4-1:0] S1_ARCACHE;
wire [3-1:0] S1_ARPROT;
wire S1_ARVALID;
wire S1_ARREADY;
wire [ID_WIDTH-1:0] M0_RID;
wire [BUS_WIDTH-1:0] M0_RDATA;
wire [4-1:0] M0_RRESP;
wire M0_RLAST;
wire M0_RVALID;
wire M0_RREADY;
wire [ID_WIDTH-1:0] M1_RID;
wire [BUS_WIDTH-1:0] M1_RDATA;
wire [4-1:0] M1_RRESP;
wire M1_RLAST;
wire M1_RVALID;
wire M1_RREADY;
wire [(ID_WIDTH+$clog2(M))-1:0] S0_RID;
wire [BUS_WIDTH-1:0] S0_RDATA;
wire [4-1:0] S0_RRESP;
wire S0_RLAST;
wire S0_RVALID;
wire S0_RREADY;
wire [(ID_WIDTH+$clog2(M))-1:0] S1_RID;
wire [BUS_WIDTH-1:0] S1_RDATA;
wire [4-1:0] S1_RRESP;
wire S1_RLAST;
wire S1_RVALID;
wire S1_RREADY;

interconnect #(
    .M(M),
    .S(S),
    .NUM_OUTSTANDING_TRANS(NUM_OUTSTANDING_TRANS),
    .BUS_WIDTH(BUS_WIDTH),
    .ID_WIDTH(ID_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) interconnect_inst (
    .clk(clk),
    .clr(clr),
    .M0_AWID(M0_AWID),
    .M0_AWADDR(M0_AWADDR),
    .M0_AWLEN(M0_AWLEN),
    .M0_AWSIZE(M0_AWSIZE),
    .M0_AWBURST(M0_AWBURST),
    .M0_AWLOCK(M0_AWLOCK),
    .M0_AWCACHE(M0_AWCACHE),
    .M0_AWPROT(M0_AWPROT),
    .M0_AWVALID(M0_AWVALID),
    .M0_AWREADY(M0_AWREADY),
    .M1_AWID(M1_AWID),
    .M1_AWADDR(M1_AWADDR),
    .M1_AWLEN(M1_AWLEN),
    .M1_AWSIZE(M1_AWSIZE),
    .M1_AWBURST(M1_AWBURST),
    .M1_AWLOCK(M1_AWLOCK),
    .M1_AWCACHE(M1_AWCACHE),
    .M1_AWPROT(M1_AWPROT),
    .M1_AWVALID(M1_AWVALID),
    .M1_AWREADY(M1_AWREADY),
    .S0_AWID(S0_AWID),
    .S0_AWADDR(S0_AWADDR),
    .S0_AWLEN(S0_AWLEN),
    .S0_AWSIZE(S0_AWSIZE),
    .S0_AWBURST(S0_AWBURST),
    .S0_AWLOCK(S0_AWLOCK),
    .S0_AWCACHE(S0_AWCACHE),
    .S0_AWPROT(S0_AWPROT),
    .S0_AWVALID(S0_AWVALID),
    .S0_AWREADY(S0_AWREADY),
    .S1_AWID(S1_AWID),
    .S1_AWADDR(S1_AWADDR),
    .S1_AWLEN(S1_AWLEN),
    .S1_AWSIZE(S1_AWSIZE),
    .S1_AWBURST(S1_AWBURST),
    .S1_AWLOCK(S1_AWLOCK),
    .S1_AWCACHE(S1_AWCACHE),
    .S1_AWPROT(S1_AWPROT),
    .S1_AWVALID(S1_AWVALID),
    .S1_AWREADY(S1_AWREADY),
    .M0_WID(M0_WID),
    .M0_WDATA(M0_WDATA),
    .M0_WSTRB(M0_WSTRB),
    .M0_WLAST(M0_WLAST),
    .M0_WVALID(M0_WVALID),
    .M0_WREADY(M0_WREADY),
    .M1_WID(M1_WID),
    .M1_WDATA(M1_WDATA),
    .M1_WSTRB(M1_WSTRB),
    .M1_WLAST(M1_WLAST),
    .M1_WVALID(M1_WVALID),
    .M1_WREADY(M1_WREADY),
    .S0_WID(S0_WID),
    .S0_WDATA(S0_WDATA),
    .S0_WSTRB(S0_WSTRB),
    .S0_WLAST(S0_WLAST),
    .S0_WVALID(S0_WVALID),
    .S0_WREADY(S0_WREADY),
    .S1_WID(S1_WID),
    .S1_WDATA(S1_WDATA),
    .S1_WSTRB(S1_WSTRB),
    .S1_WLAST(S1_WLAST),
    .S1_WVALID(S1_WVALID),
    .S1_WREADY(S1_WREADY),
    .M0_BID(M0_BID),
    .M0_BRESP(M0_BRESP),
    .M0_BVALID(M0_BVALID),
    .M0_BREADY(M0_BREADY),
    .M1_BID(M1_BID),
    .M1_BRESP(M1_BRESP),
    .M1_BVALID(M1_BVALID),
    .M1_BREADY(M1_BREADY),
    .S0_BID(S0_BID),
    .S0_BRESP(S0_BRESP),
    .S0_BVALID(S0_BVALID),
    .S0_BREADY(S0_BREADY),
    .S1_BID(S1_BID),
    .S1_BRESP(S1_BRESP),
    .S1_BVALID(S1_BVALID),
    .S1_BREADY(S1_BREADY),
    .M0_ARID(M0_ARID),
    .M0_ARADDR(M0_ARADDR),
    .M0_ARLEN(M0_ARLEN),
    .M0_ARSIZE(M0_ARSIZE),
    .M0_ARBURST(M0_ARBURST),
    .M0_ARLOCK(M0_ARLOCK),
    .M0_ARCACHE(M0_ARCACHE),
    .M0_ARPROT(M0_ARPROT),
    .M0_ARVALID(M0_ARVALID),
    .M0_ARREADY(M0_ARREADY),
    .M1_ARID(M1_ARID),
    .M1_ARADDR(M1_ARADDR),
    .M1_ARLEN(M1_ARLEN),
    .M1_ARSIZE(M1_ARSIZE),
    .M1_ARBURST(M1_ARBURST),
    .M1_ARLOCK(M1_ARLOCK),
    .M1_ARCACHE(M1_ARCACHE),
    .M1_ARPROT(M1_ARPROT),
    .M1_ARVALID(M1_ARVALID),
    .M1_ARREADY(M1_ARREADY),
    .S0_ARID(S0_ARID),
    .S0_ARADDR(S0_ARADDR),
    .S0_ARLEN(S0_ARLEN),
    .S0_ARSIZE(S0_ARSIZE),
    .S0_ARBURST(S0_ARBURST),
    .S0_ARLOCK(S0_ARLOCK),
    .S0_ARCACHE(S0_ARCACHE),
    .S0_ARPROT(S0_ARPROT),
    .S0_ARVALID(S0_ARVALID),
    .S0_ARREADY(S0_ARREADY),
    .S1_ARID(S1_ARID),
    .S1_ARADDR(S1_ARADDR),
    .S1_ARLEN(S1_ARLEN),
    .S1_ARSIZE(S1_ARSIZE),
    .S1_ARBURST(S1_ARBURST),
    .S1_ARLOCK(S1_ARLOCK),
    .S1_ARCACHE(S1_ARCACHE),
    .S1_ARPROT(S1_ARPROT),
    .S1_ARVALID(S1_ARVALID),
    .S1_ARREADY(S1_ARREADY),
    .M0_RID(M0_RID),
    .M0_RDATA(M0_RDATA),
    .M0_RRESP(M0_RRESP),
    .M0_RLAST(M0_RLAST),
    .M0_RVALID(M0_RVALID),
    .M0_RREADY(M0_RREADY),
    .M1_RID(M1_RID),
    .M1_RDATA(M1_RDATA),
    .M1_RRESP(M1_RRESP),
    .M1_RLAST(M1_RLAST),
    .M1_RVALID(M1_RVALID),
    .M1_RREADY(M1_RREADY),
    .S0_RID(S0_RID),
    .S0_RDATA(S0_RDATA),
    .S0_RRESP(S0_RRESP),
    .S0_RLAST(S0_RLAST),
    .S0_RVALID(S0_RVALID),
    .S0_RREADY(S0_RREADY),
    .S1_RID(S1_RID),
    .S1_RDATA(S1_RDATA),
    .S1_RRESP(S1_RRESP),
    .S1_RLAST(S1_RLAST),
    .S1_RVALID(S1_RVALID),
    .S1_RREADY(S1_RREADY)
);

// ReadMasterSlave 0
ReadMasterSlave #(
    .BUS_WIDTH(BUS_WIDTH)
) ReadMasterSlave_inst0 (
    .ACLK(clk),
    .ARESETn(clr),
    .fifo_write0(M0R_fifo_write0),
    .fifo_write1(M0R_fifo_write1),
    .tag_in0(M0R_tag_in0),
    .tag_in1(M0R_tag_in1),
    .address_in0(M0R_address_in0),
    .address_in1(M0R_address_in1),
    .len_in0(M0R_len_in0),
    .len_in1(M0R_len_in1),
    .size_in0(M0R_size_in0),
    .size_in1(M0R_size_in1),
    .burst_in0(M0R_burst_in0),
    .burst_in1(M0R_burst_in1),
    .lock_in0(M0R_lock_in0),
    .lock_in1(M0R_lock_in1),
    .cache_in0(M0R_cache_in0),
    .cache_in1(M0R_cache_in1),
    .prot_in0(M0R_prot_in0),
    .prot_in1(M0R_prot_in1),
    .address_out(M0R_address_out),
    .memread(M0R_memread),
    .data_in(M0R_data_in),
    .Master_out_ARID(M0_ARID),
    .Master_out_ARADDR(M0_ARADDR),
    .Master_out_ARLEN(M0_ARLEN),
    .Master_out_ARSIZE(M0_ARSIZE),
    .Master_out_ARBURST(M0_ARBURST),
    .Master_out_ARLOCK(M0_ARLOCK),
    .Master_out_ARCACHE(M0_ARCACHE),
    .Master_out_ARPROT(M0_ARPROT),
    .Master_out_ARVALID(M0_ARVALID),
    .Master_in_ARREADY(M0_ARREADY),
    .Slave_in_ARID(S0_ARID),
    .Slave_in_ARADDR(S0_ARADDR),
    .Slave_in_ARLEN(S0_ARLEN),
    .Slave_in_ARSIZE(S0_ARSIZE),
    .Slave_in_ARBURST(S0_ARBURST),
    .Slave_in_ARLOCK(S0_ARLOCK),
    .Slave_in_ARCACHE(S0_ARCACHE),
    .Slave_in_ARPROT(S0_ARPROT),
    .Slave_in_ARVALID(S0_ARVALID),
    .Slave_out_ARREADY(S0_ARREADY),
    .Master_in_RID(M0_RID),
    .Master_in_RDATA(M0_RDATA),
    .Master_in_RLAST(M0_RLAST),
    .Master_in_RRESP(M0_RRESP),
    .Master_in_RVALID(M0_RVALID),
    .Master_out_RREADY(M0_RREADY),
    .Slave_out_RID(S0_RID),
    .Slave_out_RDATA(S0_RDATA),
    .Slave_out_RLAST(S0_RLAST),
    .Slave_out_RRESP(S0_RRESP),
    .Slave_out_RVALID(S0_RVALID),
    .Slave_in_RREADY(S0_RREADY)
);

// WriteMasterSlave 0
WriteMasterSlave WriteMasterSlave_inst0 (
    .ACLK(clk),
    .ARESETn(clr),
    .writeavail(M0W_writeavail),
    .memoryWrite(M0W_memoryWrite),
    .devclock(clk),
    .datawrite(M0W_datawrite),
    .addresswrite(M0W_addresswrite),
    .WID(M0W_WID),
    .AWID(M0W_AWID),
    .WLEN(M0W_WLEN),
    .WSIZE(M0W_WSIZE),
    .WBURST(M0W_WBURST),
    .WLOCK(M0W_WLOCK),
    .WCACHE(M0W_WCACHE),
    .WPROT(M0W_WPROT),
    .Dataout(M0W_Dataout),
    .addressout(M0W_addressout),
    .response(),
    .finishwrite(M0W_finishwrite),
    .Master_out_BREADY(M0_BREADY),
    .Master_out_AWID(M0_AWID),
    .Master_out_AWADDR(M0_AWADDR),
    .Master_out_AWLEN(M0_AWLEN),
    .Master_out_AWSIZE(M0_AWSIZE),
    .Master_out_AWBURST(M0_AWBURST),
    .Master_out_AWLOCK(M0_AWLOCK),
    .Master_out_AWCACHE(M0_AWCACHE),
    .Master_out_AWPROT(M0_AWPROT),
    .Master_out_AWVALID(M0_AWVALID),
    .Master_out_WID(M0_WID),
    .Master_out_BRESP(M0_BRESP),
    .Master_out_dataBus(M0_WDATA),
    .Master_out_WSTRB(M0_WSTRB),
    .Master_out_WLAST(M0_WLAST),
    .Master_out_WVALID(M0_WVALID),
    .Master_in_AWREADY(M0_AWREADY),
    .Master_in_WREADY(M0_WREADY),
    .Master_in_BVALID(M0_BVALID),
    .Master_in_BID(M0_BID),
    .Slave_in_BREADY(S0_BREADY),
    .Slave_in_AWID(S0_AWID),
    .Slave_in_AWADDR(S0_AWADDR),
    .Slave_in_AWLEN(S0_AWLEN),
    .Slave_in_AWSIZE(S0_AWSIZE),
    .Slave_in_AWBURST(S0_AWBURST),
    .Slave_in_AWLOCK(S0_AWLOCK),
    .Slave_in_AWCACHE(S0_AWCACHE),
    .Slave_in_AWPROT(S0_AWPROT),
    .Slave_in_AWVALID(S0_AWVALID),
    .Slave_in_WID(S0_WID),
    .Slave_out_BRESP(S0_BRESP),
    .Slave_in_dataBus(S0_WDATA),
    .Slave_in_WSTRB(S0_WSTRB),
    .Slave_in_WLAST(S0_WLAST),
    .Slave_in_WVALID(S0_WVALID),
    .Slave_out_AWREADY(S0_AWREADY),
    .Slave_out_WREADY(S0_WREADY),
    .Slave_out_BVALID(S0_BVALID),
    .Slave_out_BID(S0_BID)
);

// ReadMasterSlave 1
ReadMasterSlave #(
    .BUS_WIDTH(BUS_WIDTH)
) ReadMasterSlave_inst1 (
    .ACLK(clk),
    .ARESETn(clr),
    .fifo_write0(M1R_fifo_write0),
    .fifo_write1(M1R_fifo_write1),
    .tag_in0(M1R_tag_in0),
    .tag_in1(M1R_tag_in1),
    .address_in0(M1R_address_in0),
    .address_in1(M1R_address_in1),
    .len_in0(M1R_len_in0),
    .len_in1(M1R_len_in1),
    .size_in0(M1R_size_in0),
    .size_in1(M1R_size_in1),
    .burst_in0(M1R_burst_in0),
    .burst_in1(M1R_burst_in1),
    .lock_in0(M1R_lock_in0),
    .lock_in1(M1R_lock_in1),
    .cache_in0(M1R_cache_in0),
    .cache_in1(M1R_cache_in1),
    .prot_in0(M1R_prot_in0),
    .prot_in1(M1R_prot_in1),
    .address_out(M1R_address_out),
    .memread(M1R_memread),
    .data_in(M1R_data_in),
    .Master_out_ARID(M1_ARID),
    .Master_out_ARADDR(M1_ARADDR),
    .Master_out_ARLEN(M1_ARLEN),
    .Master_out_ARSIZE(M1_ARSIZE),
    .Master_out_ARBURST(M1_ARBURST),
    .Master_out_ARLOCK(M1_ARLOCK),
    .Master_out_ARCACHE(M1_ARCACHE),
    .Master_out_ARPROT(M1_ARPROT),
    .Master_out_ARVALID(M1_ARVALID),
    .Master_in_ARREADY(M1_ARREADY),
    .Slave_in_ARID(S1_ARID),
    .Slave_in_ARADDR(S1_ARADDR),
    .Slave_in_ARLEN(S1_ARLEN),
    .Slave_in_ARSIZE(S1_ARSIZE),
    .Slave_in_ARBURST(S1_ARBURST),
    .Slave_in_ARLOCK(S1_ARLOCK),
    .Slave_in_ARCACHE(S1_ARCACHE),
    .Slave_in_ARPROT(S1_ARPROT),
    .Slave_in_ARVALID(S1_ARVALID),
    .Slave_out_ARREADY(S1_ARREADY),
    .Master_in_RID(M1_RID),
    .Master_in_RDATA(M1_RDATA),
    .Master_in_RLAST(M1_RLAST),
    .Master_in_RRESP(M1_RRESP),
    .Master_in_RVALID(M1_RVALID),
    .Master_out_RREADY(M1_RREADY),
    .Slave_out_RID(S1_RID),
    .Slave_out_RDATA(S1_RDATA),
    .Slave_out_RLAST(S1_RLAST),
    .Slave_out_RRESP(S1_RRESP),
    .Slave_out_RVALID(S1_RVALID),
    .Slave_in_RREADY(S1_RREADY)
);

// WriteMasterSlave 1
WriteMasterSlave WriteMasterSlave_inst1 (
    .ACLK(clk),
    .ARESETn(clr),
    .writeavail(M1W_writeavail),
    .memoryWrite(M1W_memoryWrite),
    .devclock(clk),
    .datawrite(M1W_datawrite),
    .addresswrite(M1W_addresswrite),
    .WID(M1W_WID),
    .AWID(M1W_AWID),
    .WLEN(M1W_WLEN),
    .WSIZE(M1W_WSIZE),
    .WBURST(M1W_WBURST),
    .WLOCK(M1W_WLOCK),
    .WCACHE(M1W_WCACHE),
    .WPROT(M1W_WPROT),
    .Dataout(M1W_Dataout),
    .addressout(M1W_addressout),
    .response(),
    .finishwrite(M1W_finishwrite),
    .Master_out_BREADY(M1_BREADY),
    .Master_out_AWID(M1_AWID),
    .Master_out_AWADDR(M1_AWADDR),
    .Master_out_AWLEN(M1_AWLEN),
    .Master_out_AWSIZE(M1_AWSIZE),
    .Master_out_AWBURST(M1_AWBURST),
    .Master_out_AWLOCK(M1_AWLOCK),
    .Master_out_AWCACHE(M1_AWCACHE),
    .Master_out_AWPROT(M1_AWPROT),
    .Master_out_AWVALID(M1_AWVALID),
    .Master_out_WID(M1_WID),
    .Master_out_BRESP(M1_BRESP),
    .Master_out_dataBus(M1_WDATA),
    .Master_out_WSTRB(M1_WSTRB),
    .Master_out_WLAST(M1_WLAST),
    .Master_out_WVALID(M1_WVALID),
    .Master_in_AWREADY(M1_AWREADY),
    .Master_in_WREADY(M1_WREADY),
    .Master_in_BVALID(M1_BVALID),
    .Master_in_BID(M1_BID),
    .Slave_in_BREADY(S1_BREADY),
    .Slave_in_AWID(S1_AWID),
    .Slave_in_AWADDR(S1_AWADDR),
    .Slave_in_AWLEN(S1_AWLEN),
    .Slave_in_AWSIZE(S1_AWSIZE),
    .Slave_in_AWBURST(S1_AWBURST),
    .Slave_in_AWLOCK(S1_AWLOCK),
    .Slave_in_AWCACHE(S1_AWCACHE),
    .Slave_in_AWPROT(S1_AWPROT),
    .Slave_in_AWVALID(S1_AWVALID),
    .Slave_in_WID(S1_WID),
    .Slave_out_BRESP(S1_BRESP),
    .Slave_in_dataBus(S1_WDATA),
    .Slave_in_WSTRB(S1_WSTRB),
    .Slave_in_WLAST(S1_WLAST),
    .Slave_in_WVALID(S1_WVALID),
    .Slave_out_AWREADY(S1_AWREADY),
    .Slave_out_WREADY(S1_WREADY),
    .Slave_out_BVALID(S1_BVALID),
    .Slave_out_BID(S1_BID)
);

endmodule