module ReadSlave
    #(parameter BusWidth = 32,
      parameter tagbits = 2) //2 bit tag for slave to track 2 master 2 ID each
(
    input ACLK,             //global clk. do everything on rising edge
    input ARESETn,          //active low reset
    //Device signals
    output reg [BusWidth-1 : 0] address_out,
    output reg devread,
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
