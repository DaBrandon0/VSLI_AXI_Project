module ReadMaster
    #(parameter BusWidth = 32,
      parameter TagBits = 4)
(
    input ACLK,             //global clk. do everything on rising edge
    input ARESETn,          //active low reset

    //device input signals to the master
    input devclock_in,
    input [BusWidth - 1:0] address_in,
    input memoryRead_in,
    input [3:0] len_in,
    input [1:0] size_in,
    input [1:0] burst_in,
    input [1:0] lock_in,
    input [3:0] cache_in,
    input [2:0] prot_in,
    output reg [BusWidth-1 : 0] data_out,
    //READ ADDRESS CHANNEL SIGNALS
    output reg [TagBits-1:0] ARID,     //ID of transaction for this start read addr and control signals
    output reg [BusWidth-1 : 0] ARADDR,   //start read address of a read burst transaction. 
    output reg [3:0]  ARLEN,    //# of transfers for this burst //capped at 4
    output reg [1:0]  ARSIZE,   //Size of each transfer in bytes. 2's complement <= bus width
    output reg [1:0]  ARBURST,  //00 fixed addy, 01 incr addy burst, 10 wrap addy
    //TODO: need to implement these features after
    output reg [1:0]  ARLOCK,   //atomic feature
    output reg [3:0]  ARCACHE,  //cache feature
    output reg [2:0]  ARPROT,   //protection feature

    output reg ARVALID,     //Read address channel outputs valid
    input ARREADY,          //slave ready to accept address channel signals

    //READ DATA CHANNEL SIGNALS
    input [TagBits-1:0]  RID,       //read ID from slave. must match ARID from master
    input [BusWidth - 1:0] RDATA,     //read data from SLAVE. 
    input [1:0]  RRESP,     //read response from slave. TODO: not implemented yet. deals with PROT and other read stuff. 
    input RLAST,            //Last transfer signal from Slave

    input RVALID,           //RDATA from slave is valid
    output reg RREADY           //Master ready to accept RDATA
);

localparam master_number = 1; //helps generate unique id for each master's transaction

//block for reading device input
//latches AR information for slave

reg begin_transaction;
reg transaction_began;

//reads devclock input for read request
always @(posedge devclock_in or negedge ARESETn)begin
    if(!ARESETn)begin
        ARID <= 0; //incrementing ID's
        ARADDR <= 0;
        ARLEN <= 0;
        ARSIZE <= 0;
        ARBURST <= 0;
        ARLOCK <= 0;
        ARCACHE <= 0;
        ARPROT <= 0;
        begin_transaction <= 0;
    end 
    else begin
        if(memoryRead_in && !transaction_began)begin
            ARID <= {master_number, ARID[2:0] + 1}; //MSB is master number
            ARADDR <= address_in;
            ARLEN <= len_in;
            ARSIZE <= size_in;
            ARBURST <= burst_in;
            ARLOCK <= lock_in;
            ARCACHE <= cache_in;
            ARPROT <= prot_in;
            begin_transaction <= 1;
        end
        else if(memoryRead_in && transaction_began)begin
            begin_transaction <= 0;
        end
    end
end

reg [1:0] state, nstate;
localparam reset = 2'b00
localparam wait_transaction = 2'b01;
localparam wait_ready = 2'b10;
localparam wait_data = 2'b11;

always @(posedge ACLK or negedge ARESETn) begin
    if(!ARESETn)begin
        state <= reset;
    end
    else begin
        state <= nstate;
    end
end

always @(*) begin
    case (state)
    reset: begin
        ARVALID = 0; //11-1 protocol spec sheet`
        RREADY = 0;
        nstate = wait_transaction;
        transaction_began = 0;
        data_out = 0;
    end
    wait_transaction : begin
        //if aew transaction comes in (new ID, ADDR, or Controls)
            //ARValid <= 1, 
            //latch ID, ADDR, and CONTROL signals to send to slave
            //go to await ready
        //else, things stay here and await for new transaction
        case(begin_transaction)
            0: begin
                ARVALID = 0;
                nstate = wait_transaction;
            end 
            1: begin
                ARVALID = 1;
                nstate = wait_ready;
            end
            default: begin 
                ARVALID = 0; 
                nstate = wait_transaction; 
            end
        endcase
    end
    wait_ready: begin
        //if(!ARREADY)
            //idle in this state. Slave has not accepted Read Address signals yet
        //else if(ARREADY)
            //ARValid <= 0;, ID, ADDR, Controls can now be changed. RREADY <= 1;
            //go to await data
        case (ARREADY)
            0: begin
                //do nothing and wait for ARREADY
                ARVALID = 1;
                nstate = wait_ready;
                RREADY = 1;
            end
            1: begin
                ARVALID = 0;
                nstate = wait_data;
                RREADY = 1;
            end
        endcase
    end
    wait_data: begin
        //if(!RVALID)
            //slave have not sent data over yet. just wait
        //else if(RVALID && RLAST)
            //last piece of data received. latch it whereever we need and this transaction is finished.
            //go back to await transaction
        //else if(RVALID && !RLAST)
            //still waiting for transfering to finish
            //latch read data as needed to somewhere TODO
            //RREADY <= 1; //ready for next piece of data.
        if(!RLAST)begin
            if(RVALID)begin
                RREADY = 1;
                nstate = wait_data;
                data_out = RDATA;
            end
            else begin
                RREADY = 1;
                nstate = wait_data;
            end    
        end
        else begin
            data_out = RDATA;
            RREADY = 0;
            nstate = wait_transaction;
        end
    end
    default:begin
        ARVALID = 0; //11-1 protocol spec sheet`
        RREADY = 0;
        nstate = wait_transaction;
        transaction_began = 0;
    end
    endcase
end

endmodule
