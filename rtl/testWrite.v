module testWrite();
    reg ACLK;
    reg ARESETn;
    reg finishwrite = 1;
    wire writeavail;
    reg memoryWrite;
    reg devclock;
    reg [31:0] datawrite;
    reg [31:0] addresswrite;

    reg [31:0] WADDR,
    reg [3:0] WLEN,
    reg [2:0] WSIZE,
    reg [1:0] WBURST,
    reg [1:0] WLOCK,
    reg [3:0] WCACHE,
    reg [2:0] WPROT,
    initial
    begin
        ACLK = 0;
        ARESETn = 0;
        #10 ARESETn = 1;
    end

    always #10 ACLK = !ACLK;
    always #10 devclock = !devclock;

    WriteSlave slavewrite(ACLK, ARESETn, Dataout, addressout, finishwrite, writeavail, BID, BRESP, BVALID,
    BREADY, AWID, AWADDR, AWLEN, AWSIZE, AWBURST, AWLOCK, AWCACHE, AWPROT, AWVALID, AWREADY, WID, dataBus, addressBus, WSTRB, WLAST, WVALID, WREADY);

    WriteMaster masterwrite(ACLK, ARESETn, BID, BRESP, BVALID, BREADY, datawrite, addresswrite, memoryWrite, devclock, WADDR, WLEN, WSIZE, WBURST, WLOCK,
    WCACHE, WPROT, response, AWID, AWADDR, AWLEN, AWSIZE, AWBURST, AWLOCK, AWCACHE, AWPROT, AWVALID, AWREADY, WID, WDATA, WSTRB, WVALID, WREADY);

endmodule