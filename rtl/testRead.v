module testRead();
localparam buswidth = 32;
localparam tagbits = 1;
//inputs to master from device
reg                 ACLK;
reg                 ARESETn;
reg [tagbits-1:0]   tag_in[0:1];
reg [buswidth-1:0]  address_in[0:1];
reg [3:0]           len_in[0:1];
reg [1:0]           size_in[0:1];
reg [1:0]           burst_i[0:1];
reg [1:0]           lock_in[0:1];
reg [3:0]           cache_in[0:1];
reg [2:0]           prot_in[0:1];
//output from master to device
wire [buswidth-1: 0] data_out;
//outputs from slave to device
wire [buswidth-1 : 0] address_out;
wire                  devread;
reg [buswidth-1:0]    data_in;

//AR wires
wire [tagbits-1: 0]  ARID;
wire [buswidth-1: 0] ARADDR;
wire [3:0]           ARLEN;
wire [1:0]           ARSIZE;
wire [1:0]           ARBURST;
wire [1:0]           ARLOCK;
wire [3:0]           ARCACHE;
wire [2:0]           ARPROT;
//R Data Channel Signals
wire [tagbits:0]      RID;
wire [buswidth - 1:0]   RDATA;
wire                    RLAST;
wire [1:0]              RRESP;

//handshaking wires
wire RVALID;
wire RREADY;
wire ARVALID;
wire ARREADY;

//FIFO testbench signals
reg fifo_write[0:1];
reg [49:0] AR_fifo_in[0:1];


always #5 ACLK = ~ACLK;

initial begin
    ACLK = 1;
    ARESETn = 0;
    tag_in[0] = 0;
    address_in[0] = 32'h00001111;
    len_in[0] = 1;
    size_in[0] = 1;
    burst_i[0] = 1;
    lock_in[0] = 1;
    cache_in[0] = 1;
    prot_in[0] = 1;
    AR_fifo_in[0] = {tag_in[0], address_in[0], len_in[0], size_in[0], burst_i[0], lock_in[0], cache_in[0], prot_in[0]};
    fifo_write[0] = 1;

    tag_in[1] = 1;
    address_in[1] = 32'h00002222;
    len_in[1] = 2;
    size_in[1] = 2;
    burst_i[1] = 2;
    lock_in[1] = 2;
    cache_in[1] = 2;
    prot_in[1] = 2;
    AR_fifo_in[1] = {tag_in[1], address_in[1], len_in[1], size_in[1], burst_i[1], lock_in[1], cache_in[1], prot_in[1]};
    fifo_write[1] = 1;
    //access 1
    #10
    ARESETn = 1;
    #6;
    fifo_write[0] = 0;
    
    tag_in[1] = 1;
    address_in[1] = 32'h00002222;
    len_in[1] = 2;
    size_in[1] = 2;
    burst_i[1] = 2;
    lock_in[1] = 2;
    cache_in[1] = 2;
    prot_in[1] = 2;
    AR_fifo_in[1] = {tag_in[1], address_in[1], len_in[1], size_in[1], burst_i[1], lock_in[1], cache_in[1], prot_in[1]};
    fifo_write[1] = 1;
    #10;
    fifo_write[1] = 0;
    #100;
    $stop;
end

//things to test
//1-4 transfers
//1-4 bytes
//
//1. fixed reading
//2. incr reading
//3. wrapped reading


ReadMaster readmaster(
.ACLK(ACLK),
.ARESETn(ARESETn),

.fifo0_write(fifo_write[0]),
.fifo1_write(fifo_write[1]),
.AR_fifo0_in(AR_fifo_in[0]),
.AR_fifo1_in(AR_fifo_in[1]),
.data_out(data_out),

.ARID(ARID),
.ARADDR(ARADDR),
.ARLEN(ARLEN),
.ARSIZE(ARSIZE),
.ARBURST(ARBURST),
.ARLOCK(ARLOCK),
.ARCACHE(ARCACHE),
.ARPROT(ARPROT),

.ARVALID(ARVALID),
.ARREADY(ARREADY),

.RID(RID[0]),
.RDATA(RDATA),
.RRESP(RRESP),
.RLAST(RLAST),
.RVALID(RVALID),
.RREADY(RREADY)
);

ReadSlave readslave(
.ACLK(ACLK),
.ARESETn(ARESETn),

.address_out(address_out),
.devread(devread),
.data_in(data_in),

.ARID({0,ARID}),
.ARADDR(ARADDR),
.ARLEN(ARLEN),
.ARSIZE(ARSIZE),
.ARBURST(ARBURST),
.ARLOCK(ARLOCK),
.ARCACHE(ARCACHE),
.ARPROT(ARPROT),

.ARVALID(ARVALID),
.ARREADY(ARREADY),

.RID(RID),
.RDATA(RDATA),
.RRESP(RRESP),
.RLAST(RLAST),

.RVALID(RVALID),
.RREADY(RREADY)
);

endmodule