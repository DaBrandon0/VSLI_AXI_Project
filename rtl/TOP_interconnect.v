`define SLAVE = Jeff's_Slave;
`define MASTER = Jeff's_Master;

module TOP_interconnect();
    parameter num_slaves = 3;
    parameter num_masters = 3;
    parameter buswidth = 32;
    wire [num_slaves-1:0] crossbar [num_masters-1:0];
    //Write address channel signals master side
    wire [3:0] MAWID [num_masters-1:0];
    
    wire [num_masters-1:0] AWADDR [31:0];
    wire [num_masters-1:0] AWLEN [3:0];
    wire [num_masters-1:0] AWSIZE [2:0];
    wire [num_masters-1:0] AWBURST [2:0];
    wire [num_masters-1:0] AWBURST [2:0];
    wire [num_masters-1:0] AWLOCK [1:0];
    wire [num_masters-1:0] AWCACHE [3:0];
    wire [num_masters-1:0] AWPROT [2:0];
    wire [num_masters-1:0] AWVALID;
    wire [num_masters-1:0] AWREADY;
    
    //Write address channel signals slave side
    wire [3:0] SAWID [num_masters-1:0];
    wire [num_slaves-1:0] AWADDR [31:0];
    wire [num_slaves-1:0] AWLEN [3:0];
    wire [num_slaves-1:0] AWSIZE [2:0];
    wire [num_slaves-1:0] AWBURST [2:0];
    wire [num_slaves-1:0] AWBURST [2:0];
    wire [num_slaves-1:0] AWLOCK [1:0];
    wire [num_slaves-1:0] AWCACHE [3:0];
    wire [num_slaves-1:0] AWPROT [2:0];
    wire [num_slaves-1:0] AWVALID;
    wire [num_slaves-1:0] AWREADY;
    //Write data channel signals
    wire [num_masters-1:0] WID [3:0];
    wire [num_masters-1:0] WDATA [buswidth-1:0];
    wire [num_masters-1:0] WSTRB[3:0];
    wire [num_masters-1:0] WLAST;
    wire [num_masters-1:0] WVALID;
    wire [num_masters-1:0] WREADY;
    //Write response channel signals
    
    genvar k;
    genvar i;
    genvar j;
    generate
        for(i = 0; i<=num_slaves; i = i + 1)
        begin
            for(j = 0; j<=num_masters; j = j + 1)
            begin
                for(k = 0; k<=3; k = k + 1)
                begin
                    nmos(SAWID[i][k],MAWID[j][k],crossbar[i][j]);
                end
            end    
        end
    endgenerate
    



endmodule