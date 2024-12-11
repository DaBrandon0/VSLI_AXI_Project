`timescale 1ns/1ps

module WriteMaster
    #(parameter buswidth = 32)
    (
    //global signals
    input ACLK,
    input ARESETn,
    //Write response channel signals master side
    input BID,
    input [1:0] BRESP,
    input BVALID,
    output reg BREADY,
    //Device signals
    input [buswidth-1:0] Datain,
    input memoryWrite,
    input devclock,
    input [3:0] AWWID,
    input [3:0] WWID,
    input [31:0] WADDR,
    input [3:0] WLEN,
    input [2:0] WSIZE,
    input [1:0] WBURST,
    input [1:0] WLOCK,
    input [3:0] WCACHE,
    input [2:0] WPROT,
    output reg [1:0] response,
    //Write address channel signals master side
    output reg AWID,
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
    output reg WID,
    output reg [buswidth-1:0] WDATA,
    output [3:0] WSTRB,
    output reg WLAST,
    output reg WVALID,
    input WREADY
);
    //Burst data fifo
    integer i;
    integer j;
    reg sent;
    reg sent2;
    reg [buswidth-1:0] fifodata [63:0];
    reg [3:0] fifoawid [63:0];
    reg [3:0] fifowid [63:0];
    reg [31:0] fifowaddr [63:0];
    reg [2:0] fifowsize [63:0];
    reg [1:0] fifoburst [63:0];
    reg [3:0] fifolen [63:0];
    reg [3:0] fifowstrb [63:0];
    reg [6:0] fifosize;
    reg [6:0] fifoWAsize;
    reg once;
    reg once2;
    reg once3;
    always@(posedge devclock)
    begin
        if(!ARESETn)
        begin
            fifosize <= 0;
            fifoWAsize <= 0;
            once2 <= 0;
            once3 <= 0;
            for (i = 0; i < 64; i = i + 1)
            begin
                fifodata[i] <= 32'd0;
            end
        end
        else
        begin
            if(!memoryWrite)
                once2 <= 0;
            if(memoryWrite && !once2)
            begin
                fifodata[fifosize] <= Datain;
                fifosize <= fifosize + 1;
                fifoWAsize <= fifoWAsize + 1;
                fifowid[fifosize] <= WWID;
                fifoawid[fifoWAsize] <= AWWID;
                fifowaddr[fifoWAsize] <= WADDR;
                fifolen[fifoWAsize] <= WLEN;
                fifowsize[fifoWAsize] <= WSIZE;
                fifoburst[fifoWAsize] <= WBURST;
                /*
                AWLOCK <= WLOCK;
                AWCACHE <= WCACHE;
                AWPROT <= WPROT;
                */
                once2 <= 1;
            end
            if(sent2)
            begin
                if(!once3)
                begin
                fifoWAsize <= fifoWAsize - AWLEN;
                    for (j = 0; j < AWLEN; j = j + 1)
                begin
                for (i = 0; i < 64; i = i + 1)
                begin
                    fifoawid[i] <= fifoawid[i+1];
                    fifowid[i] <= fifowid[i+1];
                    fifowaddr[i] <= fifowaddr[i+1];
                    fifolen[i] <= fifolen[i+1];
                    fifowsize[i] <= fifowsize[i+1];
                    fifoburst[i] <= fifoburst[i+1];
                end
                end
                end
            end
            if(sent)
            begin
                if(!once)
                begin
                fifosize <= fifosize - WLEN;
                for (i = 0; i < 64; i = i + 1)
                    begin
                        if(i+WLEN > 63)
                        begin
                            fifodata[i] <= 32'b0;
                        end
                        else
                        begin
                            fifodata[i] <= fifodata[i+WLEN];
                        end
                    end
                end
            end
            once <= sent;
            once3 <= sent2;
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
        else if(state == 0)
            transcount <= 0;
        else if(WVALID&&WREADY)
            transcount <= transcount + 1;
        
    end

    always@(*)
    begin
        WID = fifowid[0];
        AWID = fifoawid[0];
        AWADDR = fifowaddr[0];
        AWLEN = fifolen[0];
        AWSIZE = fifowsize[0];
        AWBURST = fifoburst[0];
        if(!ARESETn)
        begin
            AWVALID = 0;
            WVALID = 0;
            WLAST = 0;
            BREADY = 0;
            response = 2'bZZ;
            AWID = 0;
            AWADDR = 0;
            AWLEN = 0;
            AWSIZE = 0;
            AWBURST = 0;
            AWLOCK = 0;
            AWCACHE = 0;
            AWPROT = 0;
            sent = 0;
            sent2 = 0;
        end
        else
        begin
        sent  = 0;
        sent2 = 0;
        WVALID = 0;
        WLAST = 0;
        BREADY = 0;
        response = 2'bZZ;
        if (fifosize >= AWLEN && state == 0)
                AWVALID = 1;
            else
                AWVALID = 0;
        case(state)
        4'd0:
        begin
            if (AWVALID && AWREADY)
            begin
                nstate = 1;
            end
            else
                nstate = 0;
        end
        4'd1:
        begin
            BREADY = 1;
            WVALID = 1;
            WDATA = fifodata[transcount];
            if(transcount == WLEN)
            begin
                sent = 1;
                nstate = 2;
                WLAST = 1;
            end
            else
                nstate = 1;
        end
        4'd2:
        begin
            BREADY = 1;
            if(BVALID)
            begin
                response = BRESP;
                sent2 = 1;
                nstate = 0;
            end
            else
            begin
                nstate = 2;
            end
        end
        endcase
        end
    end

endmodule 