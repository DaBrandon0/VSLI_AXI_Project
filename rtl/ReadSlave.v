
`timescale 1ns/1ps

module ReadSlave
    #(parameter BusWidth = 32,
      parameter tagbits = 2) //2 bit tag for slave to track 2 master 2 ID each
(
    input ACLK,             //global clk. do everything on rising edge
    input ARESETn,          //active low reset
    //Device signals
    output reg [BusWidth-1 : 0] address_out,
    output reg memread,
    input [BusWidth-1 : 0] data_in, //TODO: 
    //AR Channel Signals
    input [tagbits-1:0] ARID,     //ID of transaction for this start read addr and control signals
    input [BusWidth-1 : 0] ARADDR,   //start read address of a read burst transaction. 
    input [3:0]  ARLEN,    //# of transfers for this burst //capped at 4
    input [1:0]  ARSIZE,   //Size of each transfer in bytes. 1-4 bytes (00-10) max <= bus width
    input [1:0]  ARBURST,  //00 fixed addy, 01 incr addy burst, 10 wrap addy
    //TODO: need to implement these features after
    input [1:0]  ARLOCK,   //atomic feature
    input [3:0]  ARCACHE,  //cache feature
    input [2:0]  ARPROT,   //protection feature

    input ARVALID,     //Read address channel outputs valid
    output reg ARREADY,          //slave ready to accept address channel signals

    //READ DATA CHANNEL SIGNALS
    output reg [tagbits-1:0]    RID,       //read ID from slave. must match ARID from master
    output reg [BusWidth - 1:0] RDATA,     //read data from SLAVE. 
    output reg [1:0]            RRESP,     //read response from slave. TODO: not implemented yet. deals with PROT and other read stuff. 
    output reg                  RLAST,            //Last transfer signal from Slave

    output reg RVALID,           //RDATA from slave is valid
    input RREADY           //Master ready to accept RDATA
);

reg fifo_read [0:3];       //0 or 1 for the 4 fifos. 
reg fifo_write[0:3]; 
//reg [1:0] fifo_index, fifo_nindex;  //fifo read index
reg  [48+tagbits:0] AR_fifo_in  [0:3];
wire [48+tagbits:0] AR_fifo_out [0:3];
wire fifo_empty[0:3];
wire fifo_full[0:3]; //actually should never happen trying to write multiple into one fifo. 
fifo_ReadSlave #(.tagbits(tagbits)) m0id0(ACLK, ARESETn, fifo_write[0], fifo_read[0], AR_fifo_in[0], AR_fifo_out[0], fifo_empty[0], fifo_full[0]);
fifo_ReadSlave #(.tagbits(tagbits)) m0id1(ACLK, ARESETn, fifo_write[1], fifo_read[1], AR_fifo_in[1], AR_fifo_out[1], fifo_empty[1], fifo_full[1]);
fifo_ReadSlave #(.tagbits(tagbits)) m1id0(ACLK, ARESETn, fifo_write[2], fifo_read[2], AR_fifo_in[2], AR_fifo_out[2], fifo_empty[2], fifo_full[2]);
fifo_ReadSlave #(.tagbits(tagbits)) m1id1(ACLK, ARESETn, fifo_write[3], fifo_read[3], AR_fifo_in[3], AR_fifo_out[3], fifo_empty[3], fifo_full[3]);

reg [tagbits-1:0]    ID;
reg [BusWidth-1 : 0] ADDR;
reg [3:0]            LEN;
reg [1:0]            SIZE;
reg [1:0]            BURST;
reg [1:0]            LOCK;
reg [3:0]            CACHE;
reg [2:0]            PROT;

reg [1:0] AR_state, AR_nstate;
localparam reset = 2'b00;
localparam AR_idle = 2'b01;
localparam record = 2'b10;
// AR Channel State Machine ----------------------------------------------------
always @(posedge ACLK or negedge ARESETn)begin
  if(!ARESETn)begin
    AR_state <= reset;
  end 
  else begin
    AR_state <= AR_nstate;
  end
end
//comb
integer i;
always @(*)begin
  case(AR_state)
    reset:begin
      ARREADY = 1;
      AR_nstate = AR_idle;
      for(i = 0; i < 4; i = i+1)begin
        fifo_write[i] = 0;
        AR_fifo_in[i] = 0;
      end
    end
    AR_idle:begin
        for(i = 0; i < 4; i = i+1)begin
        fifo_write[i] = 0;
        AR_fifo_in[i] = 0;
      end
      if(ARVALID)begin
        ARREADY = 0;
        AR_nstate = record;
      end 
      else begin
        ARREADY = 1;
        AR_nstate = AR_idle;
      end
    end
    record:begin
      ARREADY = 1;
      fifo_write[ARID] = 1; //turn on write to fifo matching ARID
      AR_fifo_in[ARID] = {ARID, ARADDR, ARLEN, ARSIZE, ARBURST, ARLOCK, ARCACHE, ARPROT}; //writes matching bits to matching fifo
      AR_nstate = AR_idle;
    end
    default:begin
      ARREADY = 1;
      AR_nstate = AR_idle;
      for(i = 0; i < 4; i = i+1)begin
        fifo_write[i] = 0;
        AR_fifo_in[i] = 0;
      end
    end
  endcase
  
  
end


//R data Channel FSM here------------------------------------------------------

reg[2:0] R_state, R_nstate;
localparam R_reset = 3'd0;
localparam R_Idle = 3'd1;
localparam R_Idle2 = 3'd2;
localparam read_fifo = 3'd3;
localparam read_mem = 3'd4;
localparam send_data = 3'd5;
localparam r_valid = 3'd6;

always @(posedge ACLK or negedge ARESETn)begin
  if(!ARESETn)begin
    R_state <= R_reset;
  end
  else begin
    R_state <= R_nstate;
  end
end


reg [2:0] count, ncount;
reg [31:0] temp_data;
reg [31:0] new_address;
reg [1:0] fifo_index, fifo_nindex;
reg [1:0] incr_count, incr_ncount;
reg sync_index;
reg last_reg;   //this and seen-rready are logic for better RREADY and RVALID timing
reg seen_rready; //this and seen-rready are logic for better RREADY and RVALID timing
reg [1:0] read_index;
integer j;
always @(*)begin
  case(R_state)
    R_reset:begin 
      R_nstate = R_Idle;
      fifo_index = 2'b00;
      fifo_nindex = 2'b00;
      for(j = 0; j < 4; j = j + 1)begin
        fifo_read[j] = 0;
      end
      memread = 0;
      address_out = 0;
      new_address = 0;

      ID    = 0;
      ADDR  = 0;
      LEN   = 0;
      SIZE  = 0;
      BURST = 0;
      LOCK  = 0;
      CACHE = 0;
      PROT  = 0;

      RVALID = 0;
      RID = 0;
      RDATA = 0;
      RRESP = 0;
      RLAST = 0;
      count = 0; ncount = 0;
      incr_count = 0; incr_ncount = 0;
      temp_data = 0;
      last_reg = 0;
      seen_rready = 0;
      read_index = 0;
    end
    R_Idle:begin  
      RVALID = 0;
      RLAST = 0;
      seen_rready = 0;
      last_reg = 0;
      incr_ncount = 0;
      incr_count = 0;
      if(!fifo_empty[fifo_index])begin
        R_nstate = read_fifo;
        read_index = fifo_index;
        sync_index = 1;
      end
      else begin
        R_nstate = R_Idle2;
      end
      fifo_nindex = fifo_index + 1;
    end
    R_Idle2:begin  
      RVALID = 0;
      RLAST = 0;
      incr_ncount = 0;
      incr_count = 0;
      if(!fifo_empty[fifo_nindex])begin
        R_nstate = read_fifo;
        read_index = fifo_nindex;
        sync_index = 0;
      end
      else begin
        R_nstate = R_Idle;
      end
      fifo_index = fifo_nindex + 1;
    end
    read_fifo: begin
      RVALID = 0;
      RLAST = 0;
      incr_ncount = 0;
      incr_count = 0;
      fifo_read[read_index] = 1;
      ID    = AR_fifo_out[read_index][48+tagbits:49]; //50:49 = 2 bit ID
      ADDR  = AR_fifo_out[read_index][48:17];
      LEN   = AR_fifo_out[read_index][16:13]; //00 = 1, 01 = 2, 10 = 3, 11 = 4
      SIZE  = AR_fifo_out[read_index][12:11]; //00 = 1, 01 = 2, 10 = 4
      BURST = AR_fifo_out[read_index][10:9];
      LOCK  = AR_fifo_out[read_index][8:7];
      CACHE = AR_fifo_out[read_index][6:3];
      PROT  = AR_fifo_out[read_index][2:0];
      count = LEN + 1; ncount = LEN + 1;
      address_out = ADDR;
      R_nstate = read_mem;
    end
    read_mem:begin
      seen_rready = 0;
      RLAST = 0;
      RVALID = 0;                //if returning to read mem, must set RVALID low
      for(j = 0; j < 4; j = j+1)begin
        fifo_read[j] = 0; //fifo read complete by this stage
        fifo_read[j] = 0; //fifo read complete by this stage
      end
      if(sync_index)begin       //adjusting from which idle state we're coming from
        fifo_index = fifo_nindex;  //will stop read on the read fifo index and the new one, but that's ok
      end 
      else begin
        fifo_nindex = fifo_index;  //will stop read on the read fifo index and the new one, but that's ok
      end
      memread = 1;
      temp_data = data_in; //read will be latched into tempdata on negedge by send_data stage. 
      case(BURST) //takes care of incrementing address and strobing
      2'b00:begin //fixed
        new_address = address_out;      //same addressing
        ncount = count - 1; //finish read 4, becomes 0. 
      end
      2'b01:begin //incr
      case(SIZE)
        2'b00: begin  //1byte size access
          new_address = address_out;
        end
        2'b01: begin  //2byte size access
          if(incr_count == 1)
            new_address = address_out + 4;
          else 
            new_address = address_out;
          incr_ncount = incr_count + 1;
        end
        2'b10: begin  //4byte size access
          new_address = address_out + 4;
        end
      endcase
      ncount = count - 1;
      end
      2'b10:begin //wrapped
      end
      2'b11:begin //reserved
      end
      endcase
      R_nstate = send_data;
      //after read from fifo, increment fifo_nindex
    end
    send_data:begin
      incr_count = incr_ncount;
      address_out = new_address; //next memory access
      RID = ID;
      memread = 0;
      count = ncount;
      RDATA = temp_data;
      RLAST = (count == 0);
      last_reg = (count == 0);
      RVALID = 1;
      R_nstate = r_valid;
    end
    r_valid:begin
      if(RREADY || seen_rready)begin
        seen_rready = 1;
        RVALID = 0;
        if(last_reg)begin
          RLAST = 0;
          R_nstate = R_Idle;  //finished reading. can move to next transaction
        end
        else begin
          R_nstate = read_mem; //not finished reading. addr incremented already. read again.
        end
      end
      else begin
        R_nstate = r_valid;   //not received ready handshake. remain here. 
      end
    end
    default:begin
      R_nstate = R_Idle;
      fifo_index = 2'b00;
      fifo_nindex = 2'b00;
      for(j = 0; j < 4; j = j + 1)begin
        fifo_read[j] = 0;
      end
      memread = 0;
      address_out = 0;
      new_address = 0;

      ID    = 0;
      ADDR  = 0;
      LEN   = 0;
      SIZE  = 0;
      BURST = 0;
      LOCK  = 0;
      CACHE = 0;
      PROT  = 0;

      RVALID = 0;
      RID = 0;
      RDATA = 0;
      RRESP = 0;
      RLAST = 0;
      count = 0; ncount = 0;
      incr_count = 0; incr_ncount = 0;
      temp_data = 0;
    end
  endcase
end
endmodule