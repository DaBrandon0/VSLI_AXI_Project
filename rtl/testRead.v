module testRead();
localparam buswidth = 32;
localparam tagbits = 4;
//inputs to master from device
reg                 ACLK;
reg                 ARESETn;
reg                 devclock_in;
reg [buswidth-1:0]  address_in;
reg                 memoryRead_in;
reg [3:0]           len_in;
reg [1:0]           size_in;
reg [1:0]           burst_i;
reg [1:0]           lock_in;
reg [3:0]           cache_in;
reg [2:0]           prot_in;
//output from master to device
wire [buswidth-1: 0] data_out;
//outputs from slave to device
wire [buswidth-1 : 0] address_out;
wire                    devread;
wire [buswidth-1:0] data_in;

//Master AR wires
wire [tagbits-1: 0]  ARID;
wire [buswidth-1: 0] ARADDR;
wire [3:0]           ARLEN;
wire [1:0]           ARSIZE;
wire [1:0]           ARBURST;
wire [1:0]           ARLOCK;
wire [3:0]           ARCACHE;
wire [2:0]           ARPROT;

//Data Channel Signals
wire [tagbits-1:0]      RID;
wire [buswidth - 1:0]   RDATA;
wire [1:0]              RRESP;
wire                    RLAST;

//handshaking wires
wire RVALID;
wire RREADY;
wire ARVALID;
wire ARREADY;

always #5 ACLK = ~ACLK;
always #10 devclock_in = ~devclock_in;

initial begin
    ACLK = 0;
    ARESETn = 0;
    devclock_in = 0;
    address_in = 32'b0;
    memoryRead_in = 1;
    len_in = 1;
    size_in = 1;
    burst_i = 1;
    lock_in = 1;
    cache_in = 1;
    prot_in = 1;
    //access 1
    #8;
    ARESETn = 1;
    #22;
    memoryRead_in = 0;
    #500;
    $stop;
end

ReadMaster readmaster(
.ACLK(ACLK),
.ARESETn(ARESETn),

.devclock_in(devclock_in),
.address_in(address_in),
.memoryRead_in(memoryRead_in),
.len_in(len_in),
.size_in(size_in),
.burst_in(burst_in),
.lock_in(lock_in),
.cache_in(cache_in),
.prot_in(prot_in),
.data_out(data_out),

.ARID(ARID),
.ARADDR(ARADDR),
.ARLEN(ARLEN),
.ARSIZE(ARSIZE),
.ARBURST(ARBURST),
.ARLOCK(ARLOCK),
.ARCACHE(ARCACHE),
.ARPROT(ARPROT),

.RID(RID),
.RDATA(RDATA),
.RRESP(RRESP),
.RLAST(RLAST),

.RVALID(RVALID),
.RREADY(RREADY),
.ARVALID(ARVALID),
.ARREADY(ARREADY)
);

ReadSlave readslave(
.ACLK(ACLK),
.ARESETn(ARESETn),

.address_out(address_out),
.devread(devread),
.data_in(data_in),

.ARID(ARID),
.ARADDR(ARADDR),
.ARLEN(ARLEN),
.ARSIZE(ARSIZE),
.ARBURST(ARBURST),
.ARLOCK(ARLOCK),
.ARCACHE(ARCACHE),
.ARPROT(ARPROT),

.RID(RID),
.RDATA(RDATA),
.RRESP(RRESP),
.RLAST(RLAST),

.RVALID(RVALID),
.RREADY(RREADY),
.ARVALID(ARVALID),
.ARREADY(ARREADY)
);

endmodule