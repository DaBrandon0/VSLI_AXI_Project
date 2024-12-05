module testRead();
localparam buswidth = 32;
localparam tagbits = 1;
//inputs to master from device
reg                 ACLK;
reg                 ARESETn;
reg [tagbits-1:0]   tag_in[0:1];
reg [buswidth-1:0]  address_in[0:1];
reg [3:0]           len_in[0:1];
reg [1:0]           size_in[0:1];
reg [1:0]           burst_i[0:1];
reg [1:0]           lock_in[0:1];
reg [3:0]           cache_in[0:1];
reg [2:0]           prot_in[0:1];
//outputs from slave to device
wire [buswidth-1 : 0] address_out;
wire                  memread;
wire [buswidth-1:0]    data_in;

wire [6:0] nothing = 7'bz;
wire [31:0] nothing2 = 31'bz;

Memory mem(memread, !memread, ACLK, nothing, address_out[6:0], nothing2, data_in);

//AR wires
wire [tagbits-1: 0]  ARID;
wire [buswidth-1: 0] ARADDR;
wire [3:0]           ARLEN;
wire [1:0]           ARSIZE;
wire [1:0]           ARBURST;
wire [1:0]           ARLOCK;
wire [3:0]           ARCACHE;
wire [2:0]           ARPROT;
//R Data Channel Signals
wire [tagbits:0]      RID;
wire [buswidth - 1:0]   RDATA;
wire                    RLAST;
wire [1:0]              RRESP;

//handshaking wires
wire RVALID;
wire RREADY;
wire ARVALID;
wire ARREADY;

//FIFO testbench signals
reg fifo_write[0:1];
reg [49:0] AR_fifo_in[0:1];


always #5 ACLK = ~ACLK;


initial begin
    ACLK = 1;
    ARESETn = 0;


    //reads 4 transfers of size 16 bytes from addy x00
    tag_in[0] = 0;
    address_in[0] = 32'h00000000;
    len_in[0] = 3;
    size_in[0] = 1;
    burst_i[0] = 1; //incr
    lock_in[0] = 1;
    cache_in[0] = 1;
    prot_in[0] = 1;
    AR_fifo_in[0] = {tag_in[0], address_in[0], len_in[0], size_in[0], burst_i[0], lock_in[0], cache_in[0], prot_in[0]};
    fifo_write[0] = 1;

    //reads 3 transfers of size 4 bytes from addy x08
    tag_in[1] = 1;
    address_in[1] = 32'h00000008;
    len_in[1] = 2;
    size_in[1] = 2; 
    burst_i[1] = 1; //incr
    lock_in[1] = 2;
    cache_in[1] = 2;
    prot_in[1] = 2;
    AR_fifo_in[1] = {tag_in[1], address_in[1], len_in[1], size_in[1], burst_i[1], lock_in[1], cache_in[1], prot_in[1]};
    fifo_write[1] = 1;
    #10
    ARESETn = 1;
    #6;
    //reads 4 transfers of size 1 byte from addy x00
    fifo_write[0] = 1;
    tag_in[0] = 0;
    address_in[0] = 32'h00000000;
    len_in[0] = 3;
    size_in[0] = 0;
    burst_i[0] = 1; //incr
    lock_in[0] = 1;
    cache_in[0] = 1;
    prot_in[0] = 1;
    AR_fifo_in[0] = {tag_in[0], address_in[0], len_in[0], size_in[0], burst_i[0], lock_in[0], cache_in[0], prot_in[0]};
    #10;
    fifo_write[0] = 0;
    #250;
    $stop;
end

//things to test
//1-4 transfers
//1-4 bytes
//
//1. fixed reading
//2. incr reading
//3. wrapped reading


ReadMaster readmaster(
.ACLK(ACLK),
.ARESETn(ARESETn),

.fifo0_write(fifo_write[0]),
.fifo1_write(fifo_write[1]),
.AR_fifo0_in(AR_fifo_in[0]),
.AR_fifo1_in(AR_fifo_in[1]),

.ARID(ARID),
.ARADDR(ARADDR),
.ARLEN(ARLEN),
.ARSIZE(ARSIZE),
.ARBURST(ARBURST),
.ARLOCK(ARLOCK),
.ARCACHE(ARCACHE),
.ARPROT(ARPROT),

.ARVALID(ARVALID),
.ARREADY(ARREADY),

.RID(RID[0]),
.RDATA(RDATA),
.RRESP(RRESP),
.RLAST(RLAST),
.RVALID(RVALID),
.RREADY(RREADY)
);

ReadSlave readslave(
.ACLK(ACLK),
.ARESETn(ARESETn),

.address_out(address_out),
.memread(memread),
.data_in(data_in),

.ARID({0,ARID}),
.ARADDR(ARADDR),
.ARLEN(ARLEN),
.ARSIZE(ARSIZE),
.ARBURST(ARBURST),
.ARLOCK(ARLOCK),
.ARCACHE(ARCACHE),
.ARPROT(ARPROT),

.ARVALID(ARVALID),
.ARREADY(ARREADY),

.RID(RID),
.RDATA(RDATA),
.RRESP(RRESP),
.RLAST(RLAST),

.RVALID(RVALID),
.RREADY(RREADY)
);

endmodule

module Memory(CS, WE, CLK, WADDR, RADDR, Mem_in, Mem_out);
  input CS;
  input WE;
  input CLK;
  input [6:0] WADDR;
  input [6:0] RADDR;
  input [31:0] Mem_in;
  output reg [31:0] Mem_out;

  reg [31:0] data_out;
  reg [7:0] RAM [0:127];
  integer i;
  initial begin
    //$readmemh("memories.mem",RAM);
    RAM[0] =   8'b00000000;
    RAM[1] =   8'h01;  
    RAM[2] =   8'h02;  
    RAM[3] =   8'h03;  
    RAM[4] =   8'h04;  
    RAM[5] =   8'h05;  
    RAM[6] =   8'h06;  
    RAM[7] =   8'h07;  
    RAM[8] =   8'h08;  
    RAM[9] =   8'h09;  
     RAM[10] =  8'h0A;
     RAM[11] =  8'h0B;  
     RAM[12] =  8'h0C;  
     RAM[13] =  8'h0D;  
     RAM[14] =  8'h0E;  
     RAM[15] =  8'h0F;  
     RAM[16] =  8'h10;  
     RAM[17] =  8'h11;  
     RAM[18] =  8'h12;  
     RAM[19] =  8'h13;  
     RAM[20] =  8'h14;  
     RAM[21] =  8'h15;  
     RAM[22] =  8'h16;  
     RAM[23] =  8'h17;  
     RAM[24] =  8'h18;  
     RAM[25] =  8'h19;  
     RAM[26] =  8'h1A;  
     RAM[27] =  8'h1B;  
     RAM[28] =  8'h1C;  
     RAM[29] =  8'h1D;  
     RAM[30] =  8'h1E;  
     RAM[31] =  8'h1F;  
     RAM[32] =  8'h20;  
     RAM[33] =  8'h21;  
     RAM[34] =  8'h22;  
     RAM[35] =  8'h23;  
     RAM[36] =  8'h24;  
     RAM[37] =  8'h25;  
     RAM[38] =  8'h26;  
     RAM[39] =  8'h27;  
     RAM[40] =  8'h28;  
     RAM[41] =  8'h29;  
     RAM[42] =  8'h2A;  
     RAM[43] =  8'h2B;  
     RAM[44] =  8'h2C;  
     RAM[45] =  8'h2D;  
     RAM[46] =  8'h2E;  
     RAM[47] =  8'h2F;  
     RAM[48] =  8'h30;  
     RAM[49] =  8'h31;  
     RAM[50] =  8'h32;  
     RAM[51] =  8'h33;  
     RAM[52] =  8'h34;  
     RAM[53] =  8'h35;  
     RAM[54] =  8'h36;  
     RAM[55] =  8'h37;  
     RAM[56] =  8'h38;  
     RAM[57] =  8'h39;  
     RAM[58] =  8'h3A;  
     RAM[59] =  8'h3B;  
     RAM[60] =  8'h3C;  
     RAM[61] =  8'h3D;  
     RAM[62] =  8'h3E;  
     RAM[63] =  8'h3F;  
     RAM[64] =  8'h40;  
     RAM[65] =  8'h41;  
     RAM[66] =  8'h42;  
     RAM[67] =  8'h43;  
     RAM[68] =  8'h44;  
     RAM[69] =  8'h45;  
     RAM[70] =  8'h46;  
     RAM[71] =  8'h47;  
     RAM[72] =  8'h48;  
     RAM[73] =  8'h49;  
     RAM[74] =  8'h4A;  
     RAM[75] =  8'h4B;  
     RAM[76] =  8'h4C;  
     RAM[77] =  8'h4D;  
     RAM[78] =  8'h4E;  
     RAM[79] =  8'h4F;  
     RAM[80] =  8'h50;  
     RAM[81] =  8'h51;  
     RAM[82] =  8'h52;  
     RAM[83] =  8'h53;  
     RAM[84] =  8'h54;  
     RAM[85] =  8'h55;  
     RAM[86] =  8'h56;  
     RAM[87] =  8'h57;  
     RAM[88] =  8'h58;  
     RAM[89] =  8'h59;  
     RAM[90] =  8'h5A;  
     RAM[91] =  8'h5B;  
     RAM[92] =  8'h5C;  
     RAM[93] =  8'h5D;  
     RAM[94] =  8'h5E;  
     RAM[95] =  8'h5F;  
     RAM[96] =  8'h60;  
     RAM[97] =  8'h61;  
     RAM[98] =  8'h62;  
     RAM[99] =  8'h63;  
     RAM[100] = 8'h64;  
     RAM[101] = 8'h65;  
     RAM[102] = 8'h66;  
     RAM[103] = 8'h67;  
     RAM[104] = 8'h68;  
     RAM[105] = 8'h69;  
     RAM[106] = 8'h6A;  
     RAM[107] = 8'h6B;  
     RAM[108] = 8'h6C;  
     RAM[109] = 8'h6D;  
     RAM[110] = 8'h6E;  
     RAM[111] = 8'h6F;  
     RAM[112] = 8'h70;  
     RAM[113] = 8'h71;  
     RAM[114] = 8'h72;  
     RAM[115] = 8'h73;  
     RAM[116] = 8'h74;  
     RAM[117] = 8'h75;  
     RAM[118] = 8'h76;  
     RAM[119] = 8'h77;  
     RAM[120] = 8'h78;  
     RAM[121] = 8'h79;  
     RAM[122] = 8'h7A;  
     RAM[123] = 8'h7B;  
     RAM[124] = 8'h7C;  
     RAM[125] = 8'h7D;  
     RAM[126] = 8'h7E;  
     RAM[127] = 8'h7F;  
  end

  always @(negedge CLK)
  begin
    if((CS == 1'b1) && (WE == 1'b1)) begin
      // RAM[WADDR]     <= Mem_in[7:0];
	    // RAM[WADDR + 1] <= Mem_in[15:8];
	    // RAM[WADDR + 2] <= Mem_in[23:16];
	    // RAM[WADDR + 3] <= Mem_in[31:24];
	  end
    Mem_out <= {RAM[RADDR+3],RAM[RADDR+2],RAM[RADDR+1],RAM[RADDR]};
  end
endmodule