module testWrite();
    reg ACLK;
    reg ARESETn;
    reg finishwrite = 1;
    wire writeavail;
    reg memoryWrite;
    reg devclock;
    reg [31:0] datawrite = 32'd1;
    reg [31:0] addresswrite = 32'd2;
    reg [3:0] WLEN = 4'd3;
    reg [2:0] WSIZE = 3'b101;
    reg [1:0] WBURST = 2'b00;
    reg [1:0] WLOCK = 2'b00;
    reg [3:0] WCACHE = 4'b0000;
    reg [2:0] WPROT = 3'b000;
    wire [31:0] Dataout;
    wire [31:0] addressout;
    
    //master-slave connect wires
    wire BREADY;
    wire [3:0] AWID;
    wire [31:0] AWADDR;
    wire [3:0] AWLEN;
    wire [2:0] AWSIZE;
    wire [1:0] AWBURST;
    wire [1:0] AWLOCK;
    wire [3:0] AWCACHE;
    wire [2:0] AWPROT;
    wire AWVALID;
    wire [3:0] WID;
    wire [32-1:0] dataBus;
    wire [3:0] WSTRB;
    wire WLAST;
    wire WVALID;

    initial
    begin
        ACLK = 0;
        devclock = 0;
        ARESETn = 0;
        memoryWrite = 0;
        #30 ARESETn = 1;
        memoryWrite = 1;
        //#30 memoryWrite = 0;
    end

    always #10 ACLK = !ACLK;
    always #10 devclock = !devclock;

    WriteMaster masterwrite(.ACLK(ACLK), .ARESETn(ARESETn), .BID(BID), .BRESP(BRESP), .BVALID(BVALID), .BREADY(BREADY), .Datain(datawrite), .memoryWrite(memoryWrite), .devclock(devclock), .WADDR(addresswrite), .WLEN(WLEN), .WSIZE(WSIZE), .WBURST(WBURST), .WLOCK(WLOCK),
    .WCACHE(WCACHE), .WPROT(WPROT), .response(response), .AWID(AWID), .AWADDR(AWADDR), .AWLEN(AWLEN), .AWSIZE(AWSIZE), .AWBURST(AWBURST), .AWLOCK(AWLOCK), .AWCACHE(AWCACHE), .AWPROT(AWPROT), .AWVALID(AWVALID), .AWREADY(AWREADY), .WID(WID), .WDATA(dataBus), .WSTRB(WSTRB), .WLAST(WLAST), .WVALID(WVALID), .WREADY(WREADY));

    WriteSlave slavewrite(ACLK, ARESETn, Dataout, addressout, finishwrite, writeavail, BID, BRESP, BVALID,
    BREADY, AWID, AWADDR, AWLEN, AWSIZE, AWBURST, AWLOCK, AWCACHE, AWPROT, AWVALID, AWREADY, WID, dataBus, WSTRB, WLAST, WVALID, WREADY);

    

endmodule