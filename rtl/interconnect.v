module interconnect #(
    parameter M = 2,
    parameter S = 2,
    parameter NUM_OUTSTANDING_TRANS = 2,
    parameter BUS_WIDTH = 32,
    parameter ID_WIDTH = 1,
    parameter ADDR_WIDTH = 32
)(
    input clk,
    input clr,

    // write address channel signals
    input [ID_WIDTH-1:0] M0_AWID,
    input [ADDR_WIDTH-1:0] M0_AWADDR,
    input [4-1:0] M0_AWLEN,
    input [3-1:0] M0_AWSIZE,
    input [2-1:0] M0_AWBURST,
    input [2-1:0] M0_AWLOCK,
    input [4-1:0] M0_AWCACHE,
    input [3-1:0] M0_AWPROT,
    input M0_AWVALID,
    output M0_AWREADY,

    input [ID_WIDTH-1:0] M1_AWID,
    input [ADDR_WIDTH-1:0] M1_AWADDR,
    input [4-1:0] M1_AWLEN,
    input [3-1:0] M1_AWSIZE,
    input [2-1:0] M1_AWBURST,
    input [2-1:0] M1_AWLOCK,
    input [4-1:0] M1_AWCACHE,
    input [3-1:0] M1_AWPROT,
    input M1_AWVALID,
    output M1_AWREADY,

    output [(ID_WIDTH+$clog2(M))-1:0] S0_AWID,
    output [ADDR_WIDTH-1:0] S0_AWADDR,
    output [4-1:0] S0_AWLEN,
    output [3-1:0] S0_AWSIZE,
    output [2-1:0] S0_AWBURST,
    output [2-1:0] S0_AWLOCK,
    output [4-1:0] S0_AWCACHE,
    output [3-1:0] S0_AWPROT,
    output S0_AWVALID,
    input S0_AWREADY,

    output [(ID_WIDTH+$clog2(M))-1:0] S1_AWID,
    output [ADDR_WIDTH-1:0] S1_AWADDR,
    output [4-1:0] S1_AWLEN,
    output [3-1:0] S1_AWSIZE,
    output [2-1:0] S1_AWBURST,
    output [2-1:0] S1_AWLOCK,
    output [4-1:0] S1_AWCACHE,
    output [3-1:0] S1_AWPROT,
    output S1_AWVALID,
    input S1_AWREADY,

    // write data channel signals
    input [ID_WIDTH-1:0] M0_WID,
    input [BUS_WIDTH-1:0] M0_WDATA,
    input [4-1:0] M0_WSTRB,
    input M0_WLAST,
    input M0_WVALID,
    output M0_WREADY,

    input [ID_WIDTH-1:0] M1_WID,
    input [BUS_WIDTH-1:0] M1_WDATA,
    input [4-1:0] M1_WSTRB,
    input M1_WLAST,
    input M1_WVALID,
    output M1_WREADY,

    output [(ID_WIDTH+$clog2(M))-1:0] S0_WID,
    output [BUS_WIDTH-1:0] S0_WDATA,
    output [4-1:0] S0_WSTRB,
    output S0_WLAST,
    output S0_WVALID,
    input S0_WREADY,

    output [(ID_WIDTH+$clog2(M))-1:0] S1_WID,
    output [BUS_WIDTH-1:0] S1_WDATA,
    output [4-1:0] S1_WSTRB,
    output S1_WLAST,
    output S1_WVALID,
    input S1_WREADY,

    // write response channel signals
    output [ID_WIDTH-1:0] M0_BID,
    output [2-1:0] M0_BRESP,
    output M0_BVALID,
    input M0_BREADY,

    output [ID_WIDTH-1:0] M1_BID,
    output [2-1:0] M1_BRESP,
    output M1_BVALID,
    input M1_BREADY,

    input [(ID_WIDTH+$clog2(M))-1:0] S0_BID,
    input [2-1:0] S0_BRESP,
    input S0_BVALID,
    output S0_BREADY,

    input [(ID_WIDTH+$clog2(M))-1:0] S1_BID,
    input [2-1:0] S1_BRESP,
    input S1_BVALID,
    output S1_BREADY,

    // read address channel signals
    input [ID_WIDTH-1:0] M0_ARID,
    input [ADDR_WIDTH-1:0] M0_ARADDR,
    input [4-1:0] M0_ARLEN,
    input [2-1:0] M0_ARSIZE,
    input [2-1:0] M0_ARBURST,
    input [2-1:0] M0_ARLOCK,
    input [4-1:0] M0_ARCACHE,
    input [3-1:0] M0_ARPROT,
    input M0_ARVALID,
    output M0_ARREADY,

    input [ID_WIDTH-1:0] M1_ARID,
    input [ADDR_WIDTH-1:0] M1_ARADDR,
    input [4-1:0] M1_ARLEN,
    input [2-1:0] M1_ARSIZE,
    input [2-1:0] M1_ARBURST,
    input [2-1:0] M1_ARLOCK,
    input [4-1:0] M1_ARCACHE,
    input [3-1:0] M1_ARPROT,
    input M1_ARVALID,
    output M1_ARREADY,

    output [(ID_WIDTH+$clog2(M))-1:0] S0_ARID,
    output [ADDR_WIDTH-1:0] S0_ARADDR,
    output [4-1:0] S0_ARLEN,
    output [2-1:0] S0_ARSIZE,
    output [2-1:0] S0_ARBURST,
    output [2-1:0] S0_ARLOCK,
    output [4-1:0] S0_ARCACHE,
    output [3-1:0] S0_ARPROT,
    output S0_ARVALID,
    input S0_ARREADY,

    output [(ID_WIDTH+$clog2(M))-1:0] S1_ARID,
    output [ADDR_WIDTH-1:0] S1_ARADDR,
    output [4-1:0] S1_ARLEN,
    output [2-1:0] S1_ARSIZE,
    output [2-1:0] S1_ARBURST,
    output [2-1:0] S1_ARLOCK,
    output [4-1:0] S1_ARCACHE,
    output [3-1:0] S1_ARPROT,
    output S1_ARVALID,
    input S1_ARREADY,

    // read data channel signals
    output [ID_WIDTH-1:0] M0_RID,
    output [BUS_WIDTH-1:0] M0_RDATA,
    output [2-1:0] M0_RRESP,
    output M0_RLAST,
    output M0_RVALID,
    input M0_RREADY,

    output [ID_WIDTH-1:0] M1_RID,
    output [BUS_WIDTH-1:0] M1_RDATA,
    output [2-1:0] M1_RRESP,
    output M1_RLAST,
    output M1_RVALID,
    input M1_RREADY,

    input [(ID_WIDTH+$clog2(M))-1:0] S0_RID,
    input [BUS_WIDTH-1:0] S0_RDATA,
    input [2-1:0] S0_RRESP,
    input S0_RLAST,
    input S0_RVALID,
    output S0_RREADY,

    input [(ID_WIDTH+$clog2(M))-1:0] S1_RID,
    input [BUS_WIDTH-1:0] S1_RDATA,
    input [2-1:0] S1_RRESP,
    input S1_RLAST,
    input S1_RVALID,
    output S1_RREADY
);

// crossbar
wire [$clog2(S)-1:0] M0_write_addr_sel;
wire M0_write_addr_en;
wire [$clog2(S)-1:0] M1_write_addr_sel;
wire M1_write_addr_en;

wire [$clog2(S)-1:0] M0_write_data_sel;
wire M0_write_data_en;
wire [$clog2(S)-1:0] M1_write_data_sel;
wire M1_write_data_en;

wire [$clog2(M)-1:0] S0_write_resp_sel;
wire S0_write_resp_en;
wire [$clog2(M)-1:0] S1_write_resp_sel;
wire S1_write_resp_en;

wire [$clog2(S)-1:0] M0_read_addr_sel;
wire M0_read_addr_en;
wire [$clog2(S)-1:0] M1_read_addr_sel;
wire M1_read_addr_en;

wire [$clog2(M)-1:0] S0_read_data_sel;
wire S0_read_data_en;
wire [$clog2(M)-1:0] S1_read_data_sel;
wire S1_read_data_en;

crossbar2x2 #(
    .BUS_WIDTH(BUS_WIDTH),
    .ID_WIDTH(ID_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH)
) crossbar2x2_inst (
    // write address channel signals
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

    // write data channel signals
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

    // write response channel signals
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

    // read address channel signals
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

    // read data channel signals
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
    .S1_RREADY(S1_RREADY),

    // selectors
    .M0_write_addr_sel(M0_write_addr_sel),
    .M0_write_addr_en(M0_write_addr_en),
    .M1_write_addr_sel(M1_write_addr_sel),
    .M1_write_addr_en(M1_write_addr_en),

    .M0_write_data_sel(M0_write_data_sel),
    .M0_write_data_en(M0_write_data_en),
    .M1_write_data_sel(M1_write_data_sel),
    .M1_write_data_en(M1_write_data_en),

    .S0_write_resp_sel(S0_write_resp_sel),
    .S0_write_resp_en(S0_write_resp_en),
    .S1_write_resp_sel(S1_write_resp_sel),
    .S1_write_resp_en(S1_write_resp_en),

    .M0_read_addr_en(M0_read_addr_en),
    .M0_read_addr_sel(M0_read_addr_sel),
    .M1_read_addr_en(M1_read_addr_en),
    .M1_read_addr_sel(M1_read_addr_sel),

    .S0_read_data_en(S0_read_data_en),
    .S0_read_data_sel(S0_read_data_sel),
    .S1_read_data_en(S1_read_data_en),
    .S1_read_data_sel(S1_read_data_sel)
);

// read arbiter
wire [(M*1)-1:0] AR_request_f;
wire [(S*1)-1:0] AR_finish_f;
wire [(M*ADDR_WIDTH)-1:0] AR_addr_f;
wire [(M*$clog2(NUM_OUTSTANDING_TRANS))-1:0] AR_id_f;
wire [(M*1)-1:0] AR_grant_f;
wire [(M*$clog2(S))-1:0] AR_sel_f;

wire [(M*1)-1:0] R_request_f;
wire [(M*($clog2(M)+$clog2(NUM_OUTSTANDING_TRANS)))-1:0] R_id_f;
wire [(S*1)-1:0] R_last_f;
wire [(S*1)-1:0] R_grant_f;
wire [(S*$clog2(M))-1:0] R_sel_f;

assign AR_request_f = {M1_ARVALID, M0_ARVALID};
assign AR_finish_f = {S1_ARREADY, S0_ARREADY};
assign AR_addr_f = {M1_ARADDR, M0_ARADDR};
assign AR_id_f = {M1_ARID, M0_ARID};

assign R_request_f = {M1_RREADY, M0_RREADY};
assign R_id_f = {S1_RID, S0_RID};
assign R_last_f = {S1_RLAST, S0_RLAST};

assign M0_read_addr_sel = AR_sel_f[((0+1)*$clog2(S))-1 -: $clog2(S)];
assign M0_read_addr_en = AR_grant_f[0];
assign M1_read_addr_sel = AR_sel_f[((1+1)*$clog2(S))-1 -: $clog2(S)];
assign M1_read_addr_en = AR_grant_f[1];

assign S0_read_data_sel = R_sel_f[((0+1)*$clog2(M))-1 -: $clog2(M)];
assign S0_read_data_en = R_grant_f[0];
assign S1_read_data_sel = R_sel_f[((1+1)*$clog2(M))-1 -: $clog2(M)];
assign S1_read_data_en = R_grant_f[1];

read_arbiter #(
    .M(M),
    .S(S),
    .NUM_OUTSTANDING_TRANS(NUM_OUTSTANDING_TRANS),
    .ADDR_WIDTH(ADDR_WIDTH)
)(
    .clk(clk),
    .clr(clr),

    // read address channel signals
    .AR_request_f(AR_request_f),
    .AR_finish_f(AR_finish_f),
    .AR_addr_f(AR_addr_f),
    .AR_id_f(AR_id_f),
    .AR_grant_f(AR_grant_f),
    .AR_sel_f(AR_sel_f),

    // read data channel signals
    .R_request_f(R_request_f),
    .R_id_f(R_id_f),
    .R_last_f(R_last_f),
    .R_grant_f(R_grant_f),
    .R_sel_f(R_sel_f)
);

// write arbiter
wire [(M*1)-1:0] AW_valid_f;
wire [(M*ADDR_WIDTH)-1:0] AW_addr_f;
wire [(M*$clog2(NUM_OUTSTANDING_TRANS))-1:0] AW_id_f;
wire [(M*1)-1:0] AW_grant_f;
wire [(M*$clog2(S))-1:0] AW_sel_f;

wire [(M*1)-1:0] B_ready_f;
wire [(M*($clog2(NUM_OUTSTANDING_TRANS)))-1:0] W_id_f;
wire [(S*1)-1:0] B_valid_f;
wire [(M*1)-1:0] W_grant_f;
wire [(S*1)-1:0] B_grant_f;
wire [(M*$clog2(S))-1:0] W_sel_f;
wire [(S*$clog2(M))-1:0] B_sel_f;

assign AW_valid_f = {M1_AWVALID, M0_AWVALID};
assign AW_addr_f = {M1_AWADDR, M0_AWADDR};
assign AW_id_f = {M1_AWID, M0_AWID};

assign B_ready_f = {M1_BREADY, M0_BREADY};
assign W_id_f = {M1_WID, M0_WID};
assign B_valid_f = {S1_BVALID, S0_BVALID};

assign M0_write_addr_sel = AW_sel_f[((0+1)*$clog2(S))-1 -: $clog2(S)];
assign M0_write_addr_en = AW_grant_f[0];
assign M1_write_addr_sel = AW_sel_f[((1+1)*$clog2(S))-1 -: $clog2(S)];
assign M1_write_addr_en = AW_grant_f[1];

assign M0_write_data_sel = W_sel_f[((0+1)*$clog2(S))-1 -: $clog2(S)];
assign M0_write_data_en = W_grant_f[0];
assign M1_write_data_sel = W_sel_f[((1+1)*$clog2(S))-1 -: $clog2(S)];
assign M1_write_data_en = W_grant_f[1];

assign S0_write_resp_sel = B_sel_f[((0+1)*$clog2(M))-1 -: $clog2(M)];
assign S0_write_resp_en = B_grant_f[0];
assign S1_write_resp_sel = B_sel_f[((1+1)*$clog2(M))-1 -: $clog2(M)];
assign S1_write_resp_en = B_grant_f[1];

write_arbiter #(
    .M(M),
    .S(S),
    .NUM_OUTSTANDING_TRANS(NUM_OUTSTANDING_TRANS),
    .ADDR_WIDTH(ADDR_WIDTH)
)(
    .clk(clk), 
    .clr(clr), 

    .AW_valid_f(AW_valid_f),
    .AW_addr_f(AW_addr_f),
    .AW_id_f(AW_id_f),
    .AW_grant_f(AW_grant_f),
    .AW_sel_f(AW_sel_f),

    .B_ready_f(B_ready_f),
    .W_id_f(W_id_f),
    .B_valid_f(B_valid_f),
    .W_grant_f(W_grant_f),
    .B_grant_f(B_grant_f),
    .W_sel_f(W_sel_f),
    .B_sel_f(B_sel_f)
);

endmodule