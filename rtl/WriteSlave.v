module WriteSlave
    #(parameter buswidth = 32)
    (
        //global signals
        input ACLK,
        input ARESETn,
        //Device signals
        output reg [buswidth-1:0] Dataout,
        output reg [buswidth-1:0] Addressout,
        input writefinish,
        output writeavail,
        //Write response channel signals master side
        output reg [3:0] BID,
        output reg [1:0] BRESP,
        output reg BVALID,
        input BREADY,
        //Write address channel signals slave side
        input [3:0] AWID,
        input [31:0] AWADDR,
        input [3:0] AWLEN,
        input [2:0] AWSIZE,
        input [1:0] AWBURST,
        input [1:0] AWLOCK,
        input [3:0] AWCACHE,
        input [2:0] AWPROT,
        input AWVALID,
        output reg AWREADY,
        //Write data channel signals slave side
        input [3:0] WID,
        input [buswidth-1:0] WDATA,
        input [3:0] WSTRB,
        input WLAST,
        input WVALID,
        output reg WREADY
    );

    reg [3:0] state;
    reg [3:0] nstate;
    reg[15:0] burstsize;

    assign writeavail = ((state == 4'd1)&&WVALID) || state == 4'd2;
    
    always@(posedge ACLK)
    begin
        if(!ARESETn)
            state <= 0;
        else
            state <= nstate;
    end

    always@(*)
    begin
        AWREADY = 0;
        WREADY = 0;
        BVALID = 0;
        Dataout = 32'bZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ;
        case(state)
        4'd0:
        begin
            if(AWVALID)
            begin
                AWREADY = 1;
                nstate = 1;
                Addressout = AWADDR;
            end
            else 
                nstate = 0;
        end
        4'd1:
        begin
            WREADY = 1;
            if(WVALID)
            begin
                Dataout = WDATA;
                if(writefinish)
                begin
                    if(WLAST)
                        nstate = 3;
                    else
                        nstate = 1;
                    case(AWBURST)
                    2'b01: Addressout = Addressout + 2**AWSIZE;
                    2'b10: Addressout = AWADDR;// wrapping burst implementation specific to cache size (not specified)
                    default: Addressout = Addressout;
                    endcase
                end
                nstate = 2;
            end
        end
        4'd2://wait for external device to latch write
        begin
            Dataout = WDATA;
            if(writefinish)
            begin
                if(WLAST)
                    nstate = 3;
                else
                    nstate = 1;
                case(AWBURST)
                    2'b01: Addressout = Addressout + 2**AWSIZE;
                    2'b10: Addressout = AWADDR;// wrapping burst implementation specific to cache size (not specified)
                    default: Addressout = Addressout;
                endcase
            end
            else
                nstate = 2;
        end
        4'd3:
        begin
            BRESP = 2'b00; // default ok response 
            BVALID = 1;
            if(BREADY)
            begin
                nstate = 3;
            end
            else
            begin
                nstate = 0;
            end
        end

        endcase


    end

endmodule