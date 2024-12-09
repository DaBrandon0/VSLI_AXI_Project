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
reg [1:0] fifo_index, fifo_nindex;  //fifo read index
reg  [48+tagbits:0] AR_fifo_in  [0:3];
wire [48+tagbits:0] AR_fifo_out [0:3];
wire fifo_empty[0:3];
wire fifo_full[0:3]; //actually should never happen trying to write multiple into one fifo. 
fifo #(.tagbits(tagbits)) m0id0(ACLK, ARESETn, fifo_write[0], fifo_read[0], AR_fifo_in[0], AR_fifo_out[0], fifo_empty[0], fifo_full[0]);
fifo #(.tagbits(tagbits)) m0id1(ACLK, ARESETn, fifo_write[1], fifo_read[1], AR_fifo_in[1], AR_fifo_out[1], fifo_empty[1], fifo_full[1]);
fifo #(.tagbits(tagbits)) m1id0(ACLK, ARESETn, fifo_write[2], fifo_read[2], AR_fifo_in[2], AR_fifo_out[2], fifo_empty[2], fifo_full[2]);
fifo #(.tagbits(tagbits)) m1id1(ACLK, ARESETn, fifo_write[3], fifo_read[3], AR_fifo_in[3], AR_fifo_out[3], fifo_empty[3], fifo_full[3]);

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
localparam read_mem = 3'd3;
localparam send_data = 3'd4;
localparam r_valid = 3'd5;

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
    end
    R_Idle:begin  
      RVALID = 0;
      RLAST = 0;
      incr_ncount = 0;
      incr_count = 0;
      if(!fifo_empty[fifo_index])begin
        fifo_read[fifo_index] = 1;
        ID    = AR_fifo_out[fifo_index][48+tagbits:49]; //50:49 = 2 bit ID
        ADDR  = AR_fifo_out[fifo_index][48:17];
        LEN   = AR_fifo_out[fifo_index][16:13]; //00 = 1, 01 = 2, 10 = 3, 11 = 4
        SIZE  = AR_fifo_out[fifo_index][12:11]; //00 = 1, 01 = 2, 10 = 4
        BURST = AR_fifo_out[fifo_index][10:9];
        LOCK  = AR_fifo_out[fifo_index][8:7];
        CACHE = AR_fifo_out[fifo_index][6:3];
        PROT  = AR_fifo_out[fifo_index][2:0];
        count = LEN + 1; ncount = LEN + 1;
        address_out = ADDR;
        R_nstate = read_mem;
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
        fifo_read[fifo_nindex] = 1;
        ID    = AR_fifo_out[fifo_nindex][48+tagbits:49]; //50:49 = 2 bit ID
        ADDR  = AR_fifo_out[fifo_nindex][48:17];
        LEN   = AR_fifo_out[fifo_nindex][16:13]; //00 = 1, 01 = 2, 10 = 3, 11 = 4
        SIZE  = AR_fifo_out[fifo_nindex][12:11]; //00 = 1, 01 = 2, 10 = 4
        BURST = AR_fifo_out[fifo_nindex][10:9];
        LOCK  = AR_fifo_out[fifo_nindex][8:7];
        CACHE = AR_fifo_out[fifo_nindex][6:3];
        PROT  = AR_fifo_out[fifo_nindex][2:0];
        count = LEN + 1; ncount = LEN + 1;
        address_out = ADDR;
        R_nstate = read_mem;
        sync_index = 0;
      end
      else begin
        R_nstate = R_Idle;
      end
      fifo_index = fifo_nindex + 1;
    end
    read_mem:begin
      RLAST = 0;
      RVALID = 0;                //if returning to read mem, must set RVALID low
      if(sync_index)begin       //adjusting from which idle state we're coming from
        fifo_read[fifo_index] = 0; //fifo read complete by this stage
        fifo_index = fifo_nindex;  //will stop read on the read fifo index and the new one, but that's ok
      end 
      else begin
        fifo_read[fifo_nindex] = 0; //fifo read complete by this stage
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
      RVALID = 1;
      R_nstate = r_valid;
    end
    r_valid:begin
      if(RREADY)begin
        RVALID = 1;
        if(RLAST)
          R_nstate = R_Idle;  //finished reading. can move to next transaction
        else
          R_nstate = read_mem; //not finished reading. addr incremented already. read again.
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


//addressing options from specs
// wire [BusWidth-1 : 0] Start_Address = ADDR;
// wire [8:0] Number_Bytes = 1'b1 << SIZE;
// wire [4:0] Burst_Length = LEN + 1;
// wire [BusWidth-1 : 0] Aligned_Address = (Start_Address / Number_Bytes) * Number_Bytes;

//valid before ready:


//reg [1:0] R_state, R_nstate;
// //R Data channel things

// always @(posedge ACLK or negedge ARESETn)begin
//   if(!ARESETn)begin
//     R_state <= reset;
//   end 
//   else begin
//     R_state <= R_nstate;
//   end 
// end

// // localparam reset = 2'd0
// // localparam wait_master = 2'd1;
// localparam read_mem = 2'd2;
// localparam send_data = 2'd3;
// //R channel state machine
// // reg [31:0] dataread_buffer;
// reg [1:0] count, temp_count;
// reg [31:0] temp_address; //works with address_out as latching

// always @(*) begin
//   case(R_state)
//     reset:begin
//       address_out = 0;
//       RID = 0;
//       RDATA = 0;
//       RRESP = 0;
//       RLAST = 0;
//       RVALID = 0;
//       devread = 0;
//       count = 0; temp_count = 0; //tracks which transfer we are at. 
//       temp_address = 0;
//       //dataread_buffer = 0;
//       R_nstate = wait_master;
//     end
//     wait_master:begin
//       if(ARVALID)begin
//         RID = ID;
//         address_out = Start_Address;//access memory
//         temp_address = Start_Address;
//         count = LEN[1:0]; //00 = 1 transfer left, 11 = 4 transfers left
//         temp_count = count;
//         devread = 1;                
//         R_nstate = read_mem;
//       end
//       else begin
//         address_out = 0;
//         devread = 0;              
//         R_nstate = wait_master;
//       end
//     end
//     //TODO: narrow transfer lanes not yet implemented
//     read_mem:begin
//       case(SIZE)
//         2'b00:begin //1 byte
//           RDATA[7:0] = data_in[7:0];
//         end
//         2'b01:begin //2 byte
//           RDATA[15:0] = data_in[15:0];
//         end 
//         2'b10:begin //4 byte capped
//           RDATA[31:0] = data_in[31:0];
//         end
//         default:begin
//           RDATA = 32'b0;
//         end
//       endcase

//       case(BURST) //00
//         FIXED:begin //same address location. track transfer #
//           case(count)
//           2'b00:begin //1 transfer
//             temp_count = 2'b00;
//             RLAST = 1;
//           end
//           2'b01:begin //2 transfers
//             temp_count = 2'b00;
//             RLAST = 0;
//           end
//           2'b10:begin //3 transfers
//             temp_count = 2'b01;
//             RLAST = 0;
//           end
//           2'b11:begin //4 transfers
//             temp_count = 2'b10;
//             RLAST = 0;
//           end
//           endcase
//         end

//         INCR:begin //01
//           case(count)
//           2'b00:begin //1 transfer
//             temp_count = 2'b00;
//             RLAST = 1;
//           end
//           2'b01:begin //2 transfers
//             temp_count = 2'b00;
//             temp_address = address_out + Number_Bytes;
//             RLAST = 0;
//           end
//           2'b10:begin //3 transfers
//             temp_count = 2'b01;
//             temp_address = address_out + Number_Bytes;
//             RLAST = 0;
//           end
//           2'b11:begin //4 transfers
//             temp_count = 2'b10;
//             temp_address = address_out + Number_Bytes;
//             RLAST = 0;
//           end
//           endcase
//         end
//         WRAP:begin
//           //TODO :(
//         end
//       endcase
//         RVALID = 1;
//         R_nstate = send_data;
//     end
    
//     send_data:begin //3
//       count = temp_count; //latch count and address for next transfer
//       address_out = temp_address;
//       if(RREADY)begin //master receive data
//         if(RLAST)begin //last data 
//           RLAST = 0;
//           RVALID = 0;
//           R_nstate = wait_master;
//         end
//         else begin //continue transfering
//           RVALID = 0;
//           R_nstate = read_mem;
//         end
//       end
//       else begin  //wait for master to be ready to receive
//         R_nstate = send_data;
//       end
//     end
//     default:begin
//       address_out = 0;
//       RID = 0;
//       RDATA = 0;
//       RRESP = 0;
//       RLAST = 0;
//       RVALID = 0;
//       devread = 0;
//       count = 0; temp_count = 0; //tracks which transfer we are at. 
//       temp_address = 0;
//       //dataread_buffer = 0;
//       R_nstate = reset;
//     end
//   endcase
// end


endmodule

//                  readmemory: 
//    1 byte        2 bytes       4 bytes
//  setaddy         setaddy         setaddy
//  [7:0]data_in  [15:0]data_in     [31:0]data_in

//we have a address, and temp_address
//we have count and temp_count //decreasing num of transfers

//fixed: 
//access data on addr dependent on size. 
//data on same bus lane
//do not increment addr_temp
//if transfernum == 0, 
//  assert last 
//move to send data
//assert RVALID

//incr:
//access data on addr dependent on size. 
//check count to determine bus lane
//drive data to bus lane
//if transfernum == 0, 
//  assert RLAST 
//else not done
//  increment temp_address dependent on size
//move to send data

//wrapped:
//access data on addr dependent on size
//check count to determine bus lane
//drive data to bus lane

//send data: 
//latch addr = temp_addr
//latch count = temp_count
//send data onto bus and wait for RREADY. 
//if RREADY
//  deassert RVALID
//  if done, 
//    we move to wait master
//  if not done
//    we move to 
//if done, we move to wait master for next transaction
