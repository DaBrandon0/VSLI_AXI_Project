
module WriteMaster
    #(parameter buswidth = 32)
    (
    //global signals
    input ACLK,
    input ARESETn,
    //Write response channel signals master side
    input [3:0] BID,
    input [1:0] BRESP,
    input BVALID,
    output reg BREADY,
    //Device signals
    input [buswidth-1:0] Datain,
    input [buswidth-1:0] Addressin,
    input memoryWrite,
    input devclock,
    input [31:0] WADDR,
    input [3:0] WLEN,
    input [2:0] WSIZE,
    input [1:0] WBURST,
    input [1:0] WLOCK,
    input [3:0] WCACHE,
    input [2:0] WPROT,
    output reg [1:0] response,
    //Write address channel signals master side
    output reg [3:0] AWID,
    output reg [31:0] AWADDR,
    output reg [3:0] AWLEN,
    output reg [2:0] AWSIZE,
    output reg [1:0] AWBURST,
    output reg [1:0] AWLOCK,
    output reg [3:0] AWCACHE,
    output reg [2:0] AWPROT,
    output reg AWVALID,
    input AWREADY,
    //Write data channel signals master side
    output [3:0] WID,
    output reg [buswidth-1:0] WDATA,
    output [3:0] WSTRB,
    output reg WLAST,
    output reg WVALID,
    input WREADY
);
    //Burst data fifo
    integer i;
    reg sent;
    reg [buswidth-1:0] fifodata [15:0];
    reg [4:0] fifosize;
    reg removed;
    reg once;
    always@(posedge devclock)
    begin
        if(!ARESETn)
        begin
            fifosize <= 0;
            AWID <= 0;
            AWADDR <= 0;
            AWLEN <= 0;
            AWSIZE <= 0;
            AWBURST <= 0;
            AWLOCK <= 0;
            AWCACHE <= 0;
            AWPROT <= 0;
        end
        else
        begin
            if(memoryWrite)
            begin
                fifodata[fifosize] <= Datain;
                fifosize <= fifosize + 1;
                if(fifosize == 0)
                begin
                AWID <= WID;
                AWADDR <= WADDR;
                AWLEN <= WLEN;
                AWSIZE <= WSIZE;
                AWBURST <= WBURST;
                AWLOCK <= WLOCK;
                AWCACHE <= WCACHE;
                AWPROT <= WPROT;
                end
            end
            if(sent)
            begin
                if(!once)
                begin
                fifosize <= fifosize - 1;
                for (i = 0; i < 15; i = i + 1)
                    fifodata[i] <= fifodata[i+1];
                end
                once <= !sent;
            end
        end
    end

    //Write Address Channel logic
    reg [3:0] state;
    reg [3:0] nstate;
    reg [3:0] transcount;

    always@(posedge ACLK)
    begin
        if(!ARESETn)
            state <= 0;
        else
            state <= nstate;
    end

    always@(posedge ACLK)
    begin
        if(!ARESETn)
            transcount <= 0;
        else if(WVALID&&WREADY)
            transcount <= transcount + 1;
    end

    always@(*)
    begin
        if(!ARESETn)
            state <= 0;
        else
        begin
        AWVALID = 0;
        WVALID = 0;
        WLAST = 0;
        BREADY = 0;
        response = 2'bZZ;
        case(state)
        4'd0:
        begin
            if (fifosize != 0)
                AWVALID = 1;
            else
                AWVALID = 0;
            if (AWVALID && AWREADY)
            begin
                nstate = 1;
                AWVALID = 0;
                sent = 1;
            end
            else
                nstate = 0;
        end
        4'd1:
        begin
            BREADY = 1;
            WDATA = fifodata[0];
            WVALID = 1;
            if(transcount == WLEN)
            begin
                nstate = 2;
                WLAST = 1;
            end
            else
                nstate = 1;
        end
        4'd2:
        begin
            if(BVALID)
            begin
                response = BRESP;
                BREADY = 1;
                nstate = 0;
            end
            else
            begin
                nstate = 2;
                BREADY = 0;
            end
        end
        endcase
        end
    end

endmodule 