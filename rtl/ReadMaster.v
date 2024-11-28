module ReadMaster(
    input ACLK,             //global clk. do everything on rising edge
    input ARESETn,          //active low reset
    //READ ADDRESS CHANNEL SIGNALS
    output [3:0]  ARID,     //ID of transaction for this start read addr and control signals
    output [BusWidth - 1:0] ARADDR,   //start read address of a read burst transaction. 
    output [3:0]  ARLEN,    //# of transfers for this burst
    output [1:0]  ARSIZE,   //Size of each transfer in bytes. <= bus width
    output [1:0]  ARBURST,  //00 fixed addy, 01 incr addy burst, 10 wrap addy
    
    //TODO: need to implement these features after
    output [1:0]  ARLOCK,   //atomic feature
    output [3:0]  ARCACHE,  //cache feature
    output [2:0]  ARPROT,   //protection feature

    output reg ARVALID,     //Read address channel outputs valid
    input ARREADY,          //slave ready to accept address channel signals

    //READ DATA CHANNEL SIGNALS
    input [3:0]  RID,       //read ID from slave. must match ARID from master
    input [BusWidth - 1:0] RDATA,     //read data from SLAVE. 
    input [1:0]  RRESP,     //read response from slave. TODO: not implemented yet. deals with PROT and other read stuff. 
    input RLAST,            //Last transfer signal from Slave
    input RVALID,           //RDATA from slave is valid
    output reg RREADY           //Master ready to accept RDATA
);
parameter BusWidth = 31; //in bits
parameter TagBits = 4;

reg [3:0] ARID_reg;         assign ARID = ARID_reg;
reg [31:0] ARADDR_reg;      assign ARADDR = ARADDR_reg;
reg [3:0] ARLEN_reg;        assign ARLEN = ARLEN_reg;
reg [2:0] ARSIZE_reg;       assign ARSIZE = ARSIZE_reg;
reg [1:0] ARBURST_reg;      assign ARBURST = ARBURST_reg;
reg [1:0] ARLOCK_reg;       assign ARLOCK = ARLOCK_reg;
reg [3:0] ARCACHE_reg;      assign ARCACHE = ARCACHE_reg;
reg [2:0] ARPROT_reg;       assign ARPROT = ARPROT_reg;



reg [1:0] state;
parameter await_transaction = 2'd0;
parameter await_ready = 2'd1;
parameter await_data = 2'd2;

always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn)begin
        ARVALID <= 1;
        RREADY <= 1;
        state <= await_transaction;
    end
    else begin
        case (state)
        await_transaction : begin
            //if new transaction comes in (new ID, ADDR, or Controls)
                //ARValid <= 1, 
                //latch ID, ADDR, and CONTROL signals to send to slave
                //go to await ready
            //else, things stay here and await for new transaction
        end
        await_ready: begin
            //if(!ARREADY)
                //idle in this state. Slave has not accepted Read Address signals yet
            //else if(ARREADY)
                //ARValid <= 0;, ID, ADDR, Controls can now be changed. RREADY <= 1;
                //go to await data
        end
        await_data: begin
            //if(!RVALID)
                //slave have not sent data over yet. just wait
            //else if(RVALID && RLAST)
                //last piece of data received. latch it whereever we need and this transaction is finished.
                //go back to await transaction
            //else if(RVALID && !RLAST)
                //still waiting for transfering to finish
                //latch read data as needed to somewhere TODO
                //RREADY <= 1; //ready for next piece of data.
        end    
        endcase
    end
end

endmodule
