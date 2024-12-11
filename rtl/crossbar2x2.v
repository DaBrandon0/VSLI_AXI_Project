`define M 2
`define S 2

module crossbar2x2 #(
    parameter BUS_WIDTH = 32,
    parameter ID_WIDTH = 1,
    parameter ADDR_WIDTH = 32
)(
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

    output [(ID_WIDTH+$clog2(`M))-1:0] S0_AWID,
    output [ADDR_WIDTH-1:0] S0_AWADDR,
    output [4-1:0] S0_AWLEN,
    output [3-1:0] S0_AWSIZE,
    output [2-1:0] S0_AWBURST,
    output [2-1:0] S0_AWLOCK,
    output [4-1:0] S0_AWCACHE,
    output [3-1:0] S0_AWPROT,
    output S0_AWVALID,
    input S0_AWREADY,

    output [(ID_WIDTH+$clog2(`M))-1:0] S1_AWID,
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

    output [(ID_WIDTH+$clog2(`M))-1:0] S0_WID,
    output [BUS_WIDTH-1:0] S0_WDATA,
    output [4-1:0] S0_WSTRB,
    output S0_WLAST,
    output S0_WVALID,
    input S0_WREADY,

    output [(ID_WIDTH+$clog2(`M))-1:0] S1_WID,
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

    input [(ID_WIDTH+$clog2(`M))-1:0] S0_BID,
    input [2-1:0] S0_BRESP,
    input S0_BVALID,
    output S0_BREADY,

    input [(ID_WIDTH+$clog2(`M))-1:0] S1_BID,
    input [2-1:0] S1_BRESP,
    input S1_BVALID,
    output S1_BREADY,

    // read address channel signals
    input [ID_WIDTH-1:0] M0_ARID,
    input [ADDR_WIDTH-1:0] M0_ARADDR,
    input [4-1:0] M0_ARLEN,
    input [3-1:0] M0_ARSIZE,
    input [2-1:0] M0_ARBURST,
    input [2-1:0] M0_ARLOCK,
    input [4-1:0] M0_ARCACHE,
    input [3-1:0] M0_ARPROT,
    input M0_ARVALID,
    output M0_ARREADY,

    input [ID_WIDTH-1:0] M1_ARID,
    input [ADDR_WIDTH-1:0] M1_ARADDR,
    input [4-1:0] M1_ARLEN,
    input [3-1:0] M1_ARSIZE,
    input [2-1:0] M1_ARBURST,
    input [2-1:0] M1_ARLOCK,
    input [4-1:0] M1_ARCACHE,
    input [3-1:0] M1_ARPROT,
    input M1_ARVALID,
    output M1_ARREADY,

    output [(ID_WIDTH+$clog2(`M))-1:0] S0_ARID,
    output [ADDR_WIDTH-1:0] S0_ARADDR,
    output [4-1:0] S0_ARLEN,
    output [3-1:0] S0_ARSIZE,
    output [2-1:0] S0_ARBURST,
    output [2-1:0] S0_ARLOCK,
    output [4-1:0] S0_ARCACHE,
    output [3-1:0] S0_ARPROT,
    output S0_ARVALID,
    input S0_ARREADY,

    output [(ID_WIDTH+$clog2(`M))-1:0] S1_ARID,
    output [ADDR_WIDTH-1:0] S1_ARADDR,
    output [4-1:0] S1_ARLEN,
    output [3-1:0] S1_ARSIZE,
    output [2-1:0] S1_ARBURST,
    output [2-1:0] S1_ARLOCK,
    output [4-1:0] S1_ARCACHE,
    output [3-1:0] S1_ARPROT,
    output S1_ARVALID,
    input S1_ARREADY,

    // read data channel signals
    output [ID_WIDTH-1:0] M0_RID,
    output [BUS_WIDTH-1:0] M0_RDATA,
    output [4-1:0] M0_RRESP,
    output M0_RLAST,
    output M0_RVALID,
    input M0_RREADY,

    output [ID_WIDTH-1:0] M1_RID,
    output [BUS_WIDTH-1:0] M1_RDATA,
    output [4-1:0] M1_RRESP,
    output M1_RLAST,
    output M1_RVALID,
    input M1_RREADY,

    input [(ID_WIDTH+$clog2(`M))-1:0] S0_RID,
    input [BUS_WIDTH-1:0] S0_RDATA,
    input [4-1:0] S0_RRESP,
    input S0_RLAST,
    input S0_RVALID,
    output S0_RREADY,

    input [(ID_WIDTH+$clog2(`M))-1:0] S1_RID,
    input [BUS_WIDTH-1:0] S1_RDATA,
    input [4-1:0] S1_RRESP,
    input S1_RLAST,
    input S1_RVALID,
    output S1_RREADY,

    // selectors
    input [$clog2(`S)-1:0] M0_write_addr_sel,
    input M0_write_addr_en,
    input [$clog2(`S)-1:0] M1_write_addr_sel,
    input M1_write_addr_en,

    input [$clog2(`S)-1:0] M0_write_data_sel,
    input M0_write_data_en,
    input [$clog2(`S)-1:0] M1_write_data_sel,
    input M1_write_data_en,

    input [$clog2(`M)-1:0] S0_write_resp_sel,
    input S0_write_resp_en,
    input [$clog2(`M)-1:0] S1_write_resp_sel,
    input S1_write_resp_en,

    input [$clog2(`S)-1:0] M0_read_addr_en,
    input M0_read_addr_sel,
    input [$clog2(`S)-1:0] M1_read_addr_en,
    input M1_read_addr_sel,

    input [$clog2(`M)-1:0] S0_read_data_en,
    input S0_read_data_sel,
    input [$clog2(`M)-1:0] S1_read_data_en,
    input S1_read_data_sel
);

// write address channel signals
assign M0_AWREADY = (M0_write_addr_en && M0_write_addr_sel == 0) ? S0_AWREADY :
                    (M0_write_addr_en && M0_write_addr_sel == 1) ? S1_AWREADY :
                    {1'b0};

assign M1_AWREADY = (M1_write_addr_en && M1_write_addr_sel == 0) ? S0_AWREADY :
                    (M1_write_addr_en && M1_write_addr_sel == 1) ? S1_AWREADY :
                    {1'b0};

assign S0_AWID =    (M0_write_addr_en && M0_write_addr_sel == 0) ? {`M'b0, M0_AWID} :
                    (M1_write_addr_en && M1_write_addr_sel == 0) ? {`M'b1, M1_AWID} :
                    {ID_WIDTH+$clog2(`M){1'bz}};

assign S0_AWADDR =  (M0_write_addr_en && M0_write_addr_sel == 0) ? M0_AWADDR :
                    (M1_write_addr_en && M1_write_addr_sel == 0) ? M1_AWADDR :
                    {ADDR_WIDTH{1'bz}};

assign S0_AWLEN =   (M0_write_addr_en && M0_write_addr_sel == 0) ? M0_AWLEN :
                    (M1_write_addr_en && M1_write_addr_sel == 0) ? M1_AWLEN :
                    {4'bz};

assign S0_AWSIZE =  (M0_write_addr_en && M0_write_addr_sel == 0) ? M0_AWSIZE :
                    (M1_write_addr_en && M1_write_addr_sel == 0) ? M1_AWSIZE :
                    {3'bz};

assign S0_AWBURST = (M0_write_addr_en && M0_write_addr_sel == 0) ? M0_AWBURST :
                    (M1_write_addr_en && M1_write_addr_sel == 0) ? M1_AWBURST :
                    {2'bz};

assign S0_AWLOCK =  (M0_write_addr_en && M0_write_addr_sel == 0) ? M0_AWLOCK :
                    (M1_write_addr_en && M1_write_addr_sel == 0) ? M1_AWLOCK :
                    {2'bz};

assign S0_AWCACHE = (M0_write_addr_en && M0_write_addr_sel == 0) ? M0_AWCACHE :
                    (M1_write_addr_en && M1_write_addr_sel == 0) ? M1_AWCACHE :
                    {4'bz};

assign S0_AWPROT =  (M0_write_addr_en && M0_write_addr_sel == 0) ? M0_AWPROT :
                    (M1_write_addr_en && M1_write_addr_sel == 0) ? M1_AWPROT :
                    {3'bz};

assign S0_AWVALID = (M0_write_addr_en && M0_write_addr_sel == 0) ? M0_AWVALID :
                    (M1_write_addr_en && M1_write_addr_sel == 0) ? M1_AWVALID :
                    {1'b0};

assign S1_AWID =    (M0_write_addr_en && M0_write_addr_sel == 1) ? {`M'b0, M0_AWID} :
                    (M1_write_addr_en && M1_write_addr_sel == 1) ? {`M'b1, M1_AWID} :
                    {ID_WIDTH+$clog2(`M){1'bz}};

assign S1_AWADDR =  (M0_write_addr_en && M0_write_addr_sel == 1) ? M0_AWADDR :
                    (M1_write_addr_en && M1_write_addr_sel == 1) ? M1_AWADDR :
                    {ADDR_WIDTH{1'bz}};

assign S1_AWLEN =   (M0_write_addr_en && M0_write_addr_sel == 1) ? M0_AWLEN :
                    (M1_write_addr_en && M1_write_addr_sel == 1) ? M1_AWLEN :
                    {4'bz};

assign S1_AWSIZE =  (M0_write_addr_en && M0_write_addr_sel == 1) ? M0_AWSIZE :
                    (M1_write_addr_en && M1_write_addr_sel == 1) ? M1_AWSIZE :
                    {3'bz};

assign S1_AWBURST = (M0_write_addr_en && M0_write_addr_sel == 1) ? M0_AWBURST :
                    (M1_write_addr_en && M1_write_addr_sel == 1) ? M1_AWBURST :
                    {2'bz};

assign S1_AWLOCK =  (M0_write_addr_en && M0_write_addr_sel == 1) ? M0_AWLOCK :
                    (M1_write_addr_en && M1_write_addr_sel == 1) ? M1_AWLOCK :
                    {2'bz};

assign S1_AWCACHE = (M0_write_addr_en && M0_write_addr_sel == 1) ? M0_AWCACHE :
                    (M1_write_addr_en && M1_write_addr_sel == 1) ? M1_AWCACHE :
                    {4'bz};

assign S1_AWPROT =  (M0_write_addr_en && M0_write_addr_sel == 1) ? M0_AWPROT :
                    (M1_write_addr_en && M1_write_addr_sel == 1) ? M1_AWPROT :
                    {3'bz};

assign S1_AWVALID = (M0_write_addr_en && M0_write_addr_sel == 1) ? M0_AWVALID :
                    (M1_write_addr_en && M1_write_addr_sel == 1) ? M1_AWVALID :
                    {1'bz};

// write data channel signals
assign M0_WREADY =  (M0_write_data_en && M0_write_data_sel == 0) ? S0_WREADY :
                    (M0_write_data_en && M0_write_data_sel == 1) ? S1_WREADY :
                    {1'b0};

assign M1_WREADY = (M1_write_data_en && M1_write_data_sel == 0) ? S0_WREADY :
                    (M1_write_data_en && M1_write_data_sel == 1) ? S1_WREADY :
                    {1'b0};

assign S0_WID =     (M0_write_data_en && M0_write_data_sel == 0) ? M0_WID :
                    (M1_write_data_en && M1_write_data_sel == 0) ? M1_WID :
                    {ID_WIDTH+$clog2(`M){1'bz}};

assign S0_WDATA =   (M0_write_data_en && M0_write_data_sel == 0) ? M0_WDATA :
                    (M1_write_data_en && M1_write_data_sel == 0) ? M1_WDATA :
                    {BUS_WIDTH{1'bz}};

assign S0_WSTRB =   (M0_write_data_en && M0_write_data_sel == 0) ? M0_WSTRB :
                    (M1_write_data_en && M1_write_data_sel == 0) ? M1_WSTRB :
                    {4'b0};

assign S0_WLAST =   (M0_write_data_en && M0_write_data_sel == 0) ? M0_WLAST :
                    (M1_write_data_en && M1_write_data_sel == 0) ? M1_WLAST :
                    {1'b0};

assign S0_WVALID =  (M0_write_data_en && M0_write_data_sel == 0) ? M0_WVALID :
                    (M1_write_data_en && M1_write_data_sel == 0) ? M1_WVALID :
                    {1'b0};

assign S1_WID =     (M0_write_data_en && M0_write_data_sel == 1) ? M0_WID :
                    (M1_write_data_en && M1_write_data_sel == 1) ? M1_WID :
                    {ID_WIDTH+$clog2(`M){1'bz}};

assign S1_WDATA =   (M0_write_data_en && M0_write_data_sel == 1) ? M0_WDATA :
                    (M1_write_data_en && M1_write_data_sel == 1) ? M1_WDATA :
                    {BUS_WIDTH{1'bz}};

assign S1_WSTRB =   (M0_write_data_en && M0_write_data_sel == 1) ? M0_WSTRB :
                    (M1_write_data_en && M1_write_data_sel == 1) ? M1_WSTRB :
                    {4'b0};

assign S1_WLAST =   (M0_write_data_en && M0_write_data_sel == 1) ? M0_WLAST :
                    (M1_write_data_en && M1_write_data_sel == 1) ? M1_WLAST :
                    {1'b0};

assign S1_WVALID =  (M0_write_data_en && M0_write_data_sel == 1) ? M0_WVALID :
                    (M1_write_data_en && M1_write_data_sel == 1) ? M1_WVALID :
                    {1'b0};

// write response channel signals
assign M0_BID       =   (S0_write_resp_en && S0_write_resp_sel == 0) ? S0_BID :
                        (S1_write_resp_en && S1_write_resp_sel == 0) ? S1_BID :
                        {ID_WIDTH{1'bz}};
                        
assign M0_BRESP     =   (S0_write_resp_en && S0_write_resp_sel == 0) ? S0_BRESP :
                        (S1_write_resp_en && S1_write_resp_sel == 0) ? S1_BRESP :
                        {2'bz};

assign M0_BVALID    =   (S0_write_resp_en && S0_write_resp_sel == 0) ? S0_BVALID :
                        (S1_write_resp_en && S1_write_resp_sel == 0) ? S1_BVALID :
                        {1'bz};

assign M1_BID       =   (S0_write_resp_en && S0_write_resp_sel == 1) ? S0_BID :
                        (S1_write_resp_en && S1_write_resp_sel == 1) ? S1_BID :
                        {ID_WIDTH{1'bz}};
                        
assign M1_BRESP     =   (S0_write_resp_en && S0_write_resp_sel == 1) ? S0_BRESP :
                        (S1_write_resp_en && S1_write_resp_sel == 1) ? S1_BRESP :
                        {2'bz};

assign M1_BVALID    =   (S0_write_resp_en && S0_write_resp_sel == 1) ? S0_BVALID :
                        (S1_write_resp_en && S1_write_resp_sel == 1) ? S1_BVALID :
                        {1'bz};

assign S0_BREADY    =   (M0_write_data_en && M0_write_data_sel == 0) ? M0_BREADY :
                        (M1_write_data_en && M1_write_data_sel == 0) ? M1_BREADY :
                        {1'b0};

assign S1_BREADY    =   (M0_write_data_en && M0_write_data_sel == 1) ? M0_BREADY :
                        (M1_write_data_en && M1_write_data_sel == 1) ? M1_BREADY :
                        {1'b0};

// read address channel signals
assign M0_ARREADY = (M0_read_addr_en && M0_read_addr_sel == 0) ? S0_ARREADY :
                    (M0_read_addr_en && M0_read_addr_sel == 1) ? S1_ARREADY :
                    {1'b0};

assign M1_ARREADY = (M1_read_addr_en && M1_read_addr_sel == 0) ? S0_ARREADY :
                    (M1_read_addr_en && M1_read_addr_sel == 1) ? S1_ARREADY :
                    {1'b0};

assign S0_ARID =    (M0_read_addr_en && M0_read_addr_sel == 0) ? {`M'b0, M0_ARID} :
                    (M1_read_addr_en && M1_read_addr_sel == 0) ? {`M'b1, M1_ARID} :
                    {ID_WIDTH+$clog2(`M){1'bz}};

assign S0_ARADDR =  (M0_read_addr_en && M0_read_addr_sel == 0) ? M0_ARADDR :
                    (M1_read_addr_en && M1_read_addr_sel == 0) ? M1_ARADDR :
                    {ADDR_WIDTH{1'bz}};

assign S0_ARLEN =   (M0_read_addr_en && M0_read_addr_sel == 0) ? M0_ARLEN :
                    (M1_read_addr_en && M1_read_addr_sel == 0) ? M1_ARLEN :
                    {4'bz};

assign S0_ARSIZE =  (M0_read_addr_en && M0_read_addr_sel == 0) ? M0_ARSIZE :
                    (M1_read_addr_en && M1_read_addr_sel == 0) ? M1_ARSIZE :
                    {3'bz};

assign S0_ARBURST = (M0_read_addr_en && M0_read_addr_sel == 0) ? M0_ARBURST :
                    (M1_read_addr_en && M1_read_addr_sel == 0) ? M1_ARBURST :
                    {2'bz};

assign S0_ARLOCK =  (M0_read_addr_en && M0_read_addr_sel == 0) ? M0_ARLOCK :
                    (M1_read_addr_en && M1_read_addr_sel == 0) ? M1_ARLOCK :
                    {2'bz};

assign S0_ARCACHE = (M0_read_addr_en && M0_read_addr_sel == 0) ? M0_ARCACHE :
                    (M1_read_addr_en && M1_read_addr_sel == 0) ? M1_ARCACHE :
                    {4'bz};

assign S0_ARPROT =  (M0_read_addr_en && M0_read_addr_sel == 0) ? M0_ARPROT :
                    (M1_read_addr_en && M1_read_addr_sel == 0) ? M1_ARPROT :
                    {3'bz};

assign S0_ARVALID = (M0_read_addr_en && M0_read_addr_sel == 0) ? M0_ARVALID :
                    (M1_read_addr_en && M1_read_addr_sel == 0) ? M1_ARVALID :
                    {1'b0};

assign S1_ARID =    (M0_read_addr_en && M0_read_addr_sel == 1) ? {`M'b0, M0_ARID} :
                    (M1_read_addr_en && M1_read_addr_sel == 1) ? {`M'b1, M1_ARID} :
                    {ID_WIDTH+$clog2(`M){1'bz}};

assign S1_ARADDR =  (M0_read_addr_en && M0_read_addr_sel == 1) ? M0_ARADDR :
                    (M1_read_addr_en && M1_read_addr_sel == 1) ? M1_ARADDR :
                    {ADDR_WIDTH{1'bz}};

assign S1_ARLEN =   (M0_read_addr_en && M0_read_addr_sel == 1) ? M0_ARLEN :
                    (M1_read_addr_en && M1_read_addr_sel == 1) ? M1_ARLEN :
                    {4'bz};

assign S1_ARSIZE =  (M0_read_addr_en && M0_read_addr_sel == 1) ? M0_ARSIZE :
                    (M1_read_addr_en && M1_read_addr_sel == 1) ? M1_ARSIZE :
                    {3'bz};

assign S1_ARBURST = (M0_read_addr_en && M0_read_addr_sel == 1) ? M0_ARBURST :
                    (M1_read_addr_en && M1_read_addr_sel == 1) ? M1_ARBURST :
                    {2'bz};

assign S1_ARLOCK =  (M0_read_addr_en && M0_read_addr_sel == 1) ? M0_ARLOCK :
                    (M1_read_addr_en && M1_read_addr_sel == 1) ? M1_ARLOCK :
                    {2'bz};

assign S1_ARCACHE = (M0_read_addr_en && M0_read_addr_sel == 1) ? M0_ARCACHE :
                    (M1_read_addr_en && M1_read_addr_sel == 1) ? M1_ARCACHE :
                    {4'bz};

assign S1_ARPROT =  (M0_read_addr_en && M0_read_addr_sel == 1) ? M0_ARPROT :
                    (M1_read_addr_en && M1_read_addr_sel == 1) ? M1_ARPROT :
                    {3'bz};

assign S1_ARVALID = (M0_read_addr_en && M0_read_addr_sel == 1) ? M0_ARVALID :
                    (M1_read_addr_en && M1_read_addr_sel == 1) ? M1_ARVALID :
                    {1'bz};

// read data channel signals
assign M0_RID       =   (S0_read_data_en && S0_read_data_sel == 0) ? S0_RID :
                        (S1_read_data_en && S1_read_data_sel == 0) ? S1_RID :
                        {ID_WIDTH{1'bz}};


assign M0_RDATA     =   (S0_read_data_en && S0_read_data_sel == 0) ? S0_RDATA :
                        (S1_read_data_en && S1_read_data_sel == 0) ? S1_RDATA :
                        {BUS_WIDTH{1'bz}};
                

assign M0_RRESP     =   (S0_read_data_en && S0_read_data_sel == 0) ? S0_RRESP :
                        (S1_read_data_en && S1_read_data_sel == 0) ? S1_RRESP :
                        {4'bz};
                

assign M0_RLAST     =   (S0_read_data_en && S0_read_data_sel == 0) ? S0_RLAST :
                        (S1_read_data_en && S1_read_data_sel == 0) ? S1_RLAST :
                        {1'bz};
                

assign M0_RVALID    =   (S0_read_data_en && S0_read_data_sel == 0) ? S0_RVALID :
                        (S1_read_data_en && S1_read_data_sel == 0) ? S1_RVALID :
                        {1'bz};
                
assign M1_RID       =   (S0_read_data_en && S0_read_data_sel == 1) ? S0_RID :
                        (S1_read_data_en && S1_read_data_sel == 1) ? S1_RID :
                        {ID_WIDTH{1'bz}};


assign M1_RDATA     =   (S0_read_data_en && S0_read_data_sel == 1) ? S0_RDATA :
                        (S1_read_data_en && S1_read_data_sel == 1) ? S1_RDATA :
                        {BUS_WIDTH{1'bz}};
                

assign M1_RRESP     =   (S0_read_data_en && S0_read_data_sel == 1) ? S0_RRESP :
                        (S1_read_data_en && S1_read_data_sel == 1) ? S1_RRESP :
                        {4'bz};
                

assign M1_RLAST     =   (S0_read_data_en && S0_read_data_sel == 1) ? S0_RLAST :
                        (S1_read_data_en && S1_read_data_sel == 1) ? S1_RLAST :
                        {1'bz};
                

assign M1_RVALID    =   (S0_read_data_en && S0_read_data_sel == 1) ? S0_RVALID :
                        (S1_read_data_en && S1_read_data_sel == 1) ? S1_RVALID :
                        {1'bz};

assign S0_RREADY    =   (S0_read_data_en && S0_read_data_sel == 0) ? M0_RREADY :
                        (S0_read_data_en && S0_read_data_sel == 1) ? M1_RREADY :
                        {1'bz};

assign S1_RREADY    =   (S1_read_data_en && S1_read_data_sel == 0) ? M0_RREADY :
                        (S1_read_data_en && S1_read_data_sel == 1) ? M1_RREADY :
                        {1'bz};


endmodule