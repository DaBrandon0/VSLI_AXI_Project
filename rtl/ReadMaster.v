module ReadMaster
    #(parameter BusWidth = 32,
      parameter tagbits = 1)
(
    input ACLK,             //global clk. do everything on rising edge
    input ARESETn,          //active low reset
    //fifo input signals from testbench
    input fifo0_write,
    input fifo1_write,
    input [48 + tagbits:0] AR_fifo0_in,
    input [48 + tagbits:0] AR_fifo1_in,
    //data output from master to show received value
    //READ ADDRESS CHANNEL SIGNALS
    output reg [tagbits-1:0]    ARID,     //ID of transaction for this start read addr and control signals
    output reg [BusWidth-1 : 0] ARADDR,   //start read address of a read burst transaction. 
    output reg [3:0]            ARLEN,    //# of transfers for this burst //capped at 4
    output reg [1:0]            ARSIZE,   //Size of each transfer in bytes. 00:10 -> 1-4 bytes <= bus width
    output reg [1:0]            ARBURST,  //00 fixed addy, 01 incr addy burst, 10 wrap addy
    //TODO: need to implement these features after
    output reg [1:0]            ARLOCK,   //atomic feature
    output reg [3:0]            ARCACHE,  //cache feature
    output reg [2:0]            ARPROT,   //protection feature

    output reg ARVALID,     //Read address channel outputs valid
    input ARREADY,          //slave ready to accept address channel signals

    //READ DATA CHANNEL SIGNALS
    input [tagbits-1:0]  RID,       //read ID from slave. must match ARID from master
    input [BusWidth - 1:0] RDATA,     //read data from SLAVE. 
    input [1:0]  RRESP,     //read response from slave. TODO: not implemented yet. deals with PROT and other read stuff. 
    input RLAST,            //Last transfer signal from Slave
    input RVALID,           //RDATA from slave is valid
    output reg RREADY           //Master ready to accept RDATA
);

//fifo receives writes and inputs from testbench outside of master. 
//master reads out of fifo to get data. 
reg fifo_read[0:1];
reg fifo_index; //shows which fifo we're using
wire [48 + tagbits:0] AR_fifo_out[0:1]; 
wire fifo_empty[0:1], fifo_full[0:1];
fifo fifo_1(ACLK, ARESETn,fifo0_write, fifo_read[0], AR_fifo0_in, AR_fifo_out[0], fifo_empty[0], fifo_full[0]);
fifo fifo_2(ACLK, ARESETn,fifo1_write, fifo_read[1], AR_fifo1_in, AR_fifo_out[1], fifo_empty[1], fifo_full[1]);

//--------------AR CHANNEL STATE MACHINE -------------------------------------------

reg [1:0] AR_state, AR_nstate;
always @(posedge ACLK or negedge ARESETn)begin
    if(!ARESETn)begin
        AR_state <= 0;
    end
    else begin
        AR_state <= AR_nstate;
    end
end

localparam reset =       2'b00;
localparam check_fifo0 = 2'b01;
localparam check_fifo1 = 2'b10;
localparam ar_valid =    2'b11;

always @(*)begin
    case(AR_state)
    reset:begin
        //initialize values
        ARID = 0;    
        ARADDR = 0;  
        ARLEN = 0;   
        ARSIZE = 0;  
        ARBURST = 0; 
        ARLOCK = 0;  
        ARCACHE = 0; 
        ARPROT = 0;  

        ARVALID = 0;
        fifo_index = 0;
        fifo_read[0] = 0;
        fifo_read[1] = 0;
        AR_nstate = check_fifo0;
    end
    check_fifo0:begin
        fifo_index = 0;
        if(fifo_empty[0])begin
            ARVALID = 0;
            AR_nstate = check_fifo1;
        end
        else begin
            fifo_read[0] = 1; 
            ARID =    AR_fifo_out[0][48+tagbits:49];
            ARADDR =  AR_fifo_out[0][48:17];
            ARLEN =   AR_fifo_out[0][16:13];
            ARSIZE =  AR_fifo_out[0][12:11];
            ARBURST = AR_fifo_out[0][10:9];
            ARLOCK =  AR_fifo_out[0][8:7];
            ARCACHE = AR_fifo_out[0][6:3];
            ARPROT =  AR_fifo_out[0][2:0];
            ARVALID = 1;
            AR_nstate = ar_valid;
        end
    end
    check_fifo1:begin
        fifo_index = 1;
        if(fifo_empty[1])begin
            ARVALID = 0;
            AR_nstate = check_fifo0;
        end
        else begin
            fifo_read[1] = 1; 
            //fifo_out is combinational to current readptr value.
            //we will grab first entry now and set read
            ARID =    AR_fifo_out[1][48+tagbits:49];
            ARADDR =  AR_fifo_out[1][48:17];
            ARLEN =   AR_fifo_out[1][16:13];
            ARSIZE =  AR_fifo_out[1][12:11];
            ARBURST = AR_fifo_out[1][10:9];
            ARLOCK =  AR_fifo_out[1][8:7];
            ARCACHE = AR_fifo_out[1][6:3];
            ARPROT =  AR_fifo_out[1][2:0];
            ARVALID = 1;    //read correct value, now set valid before next clk rise
            AR_nstate = ar_valid; 
        end 
    end
    ar_valid:begin
        fifo_read[0] = 0; //read en will be high initially on this clock edge
        fifo_read[1] = 0; //meaning fifo will register the read and dec counter now
        if(ARREADY)begin
            ARVALID = 1; //TODO: not sure if this line should be here or the next edge
            // AR_nstate = extra_hold;
            if(fifo_index) //coming from fifo1
                AR_nstate = check_fifo0;
            else           //coming from fifo0
                AR_nstate = check_fifo1;
        end
        else begin
           AR_nstate = ar_valid;
        end
    end
    default: begin
        ARID = 0;    
        ARADDR = 0;  
        ARLEN = 0;   
        ARSIZE = 0;  
        ARBURST = 0; 
        ARLOCK = 0;  
        ARCACHE = 0; 
        ARPROT = 0;  

        ARVALID = 0;
        fifo_index = 0;
        fifo_read[0] = 0;
        fifo_read[1] = 0;
        AR_nstate = check_fifo0;
    end
    endcase
end


// for our situation, don't really need to do anything except tie RREADY to high
//--------------R CHANNEL STATE MACHINE -------------------------------------------
always@(posedge ACLK or negedge ARESETn)begin
    if(!ARESETn)begin
        RREADY <= 1;
    end
    else begin
        RREADY <= 1;
    end
end


endmodule
