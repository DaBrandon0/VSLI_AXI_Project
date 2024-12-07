module WriteMasterSlave();
    input ACLK;
    input ARESETn;
    input writeavail;
    input memoryWrite;
    input devclock;// just set to ACLK for testing
    input [31:0] datawrite;
    input [31:0] addresswrite;
    input [3:0] ID;
    input [3:0] WID;
    input [3:0] WLEN;
    input [2:0] WSIZE;
    input [1:0] WBURST;
    input [1:0] WLOCK;
    input [3:0] WCACHE;
    input [2:0] WPROT;
    output [31:0] Dataout;
    output [31:0] addressout;
    output [1:0] response;
    
    //master connect wires
    output Master_out_BREADY;
    output [3:0] Master_out_AWID;
    output [31:0] Master_out_AWADDR;
    output [3:0] Master_out_AWLEN;
    output [2:0] Master_out_AWSIZE;
    output [1:0] Master_out_AWBURST;
    output [1:0] Master_out_AWLOCK;
    output [3:0] Master_out_AWCACHE;
    output [2:0] Master_out_AWPROT;
    output Master_out_AWVALID;
    output [3:0] Master_out_WID;
    output [1:0] Master_out_BRESP;
    output [32-1:0] Master_out_dataBus;
    output [3:0] Master_out_WSTRB;
    output Master_out_WLAST;
    output Master_out_WVALID;
    output [31:0] Master_out_readdata;
    input Master_in_AWREADY;
    input Master_in_WREADY;
    input Master_in_BVALID;
    input [3:0] Master_in_BID;
    //slave connect wires
    input Slave_in_BREADY;
    input [3:0] Slave_in_AWID;
    input [31:0] Slave_in_AWADDR;
    input [3:0] Slave_in_AWLEN;
    input [2:0] Slave_in_AWSIZE;
    input [1:0] Slave_in_AWBURST;
    input [1:0] Slave_in_AWLOCK;
    input [3:0] Slave_in_AWCACHE;
    input [2:0] Slave_in_AWPROT;
    input Slave_in_AWVALID;
    input [3:0] Slave_in_WID;
    input [1:0] Slave_out_BRESP;
    input [32-1:0] Slave_in_dataBus;
    input [3:0] Slave_in_WSTRB;
    input Slave_in_WLAST;
    input Slave_in_WVALID;
    input [31:0] Slave_in_readdata;
    output Slave_out_AWREADY;
    output Slave_out_WREADY;
    output Slave_out_BVALID;
    output [3:0] Slave_out_BID;

    WriteMaster masterwrite(.ACLK(ACLK), .ARESETn(ARESETn), .BID(Master_in_BID), .BRESP(BRESP), .BVALID(Master_in_BVALID), .BREADY(Master_out_BREADY), .Datain(datawrite), .ID(ID), .WWID(WWID), .memoryWrite(memoryWrite), .devclock(devclock), .WADDR(addresswrite), .WLEN(WLEN), .WSIZE(WSIZE), .WBURST(WBURST), .WLOCK(WLOCK),
    .WCACHE(WCACHE), .WPROT(WPROT), .response(response), .AWID(Master_out_AWID), .AWADDR(Master_out_AWADDR), .AWLEN(Master_out_AWLEN), .AWSIZE(Master_out_AWSIZE), .AWBURST(Master_out_AWBURST), .AWLOCK(Master_out_AWLOCK), .AWCACHE(Master_out_AWCACHE), .AWPROT(Master_out_AWPROT), .AWVALID(Master_out_AWVALID), .AWREADY(Master_in_AWREADY), .WID(Master_out_WID), .WDATA(Master_out_dataBus), .WSTRB(Master_out_WSTRB), .WLAST(Master_out_WLAST), .WVALID(Master_out_WVALID), .WREADY(Master_in_WREADY));

    WriteSlave slavewrite(ACLK, ARESETn, Dataout, addressout, finishwrite, writeavail, Slave_out_BID, Slave_out_BRESP, Slave_out_BVALID,
    Slave_in_BREADY, Slave_in_AWID, Slave_in_AWADDR, Slave_in_AWLEN, Slave_in_AWSIZE, Slave_in_AWBURST, Slave_in_AWLOCK, Slave_in_AWCACHE, Slave_in_AWPROT, Slave_in_AWVALID, Slave_out_AWREADY, Slave_in_WID, Slave_in_dataBus, Slave_in_WSTRB, Slave_in_WLAST, Slave_in_WVALID, Slave_out_WREADY);


endmodule