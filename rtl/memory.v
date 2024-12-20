`timescale 1ns/1ps

module Memory(CS, WE, CLK, WADDR, RADDR, Mem_in, Mem_out, writefinish);
  input CS;
  input WE;
  input CLK;
  input [6:0] WADDR;
  input [6:0] RADDR;
  input [31:0] Mem_in;
  output reg [31:0] Mem_out;
  output reg writefinish;

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
//below uncommented for read
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
//      RAM[61] =  8'h3D;  
//      RAM[62] =  8'h3E;  
//      RAM[63] =  8'h3F;  
//      RAM[64] =  8'h40;  
//      RAM[65] =  8'h41;  
//      RAM[66] =  8'h42;  
//      RAM[67] =  8'h43;  
//      RAM[68] =  8'h44;  
//      RAM[69] =  8'h45;  
//      RAM[70] =  8'h46;  
//      RAM[71] =  8'h47;  
//      RAM[72] =  8'h48;  
//      RAM[73] =  8'h49;  
//      RAM[74] =  8'h4A;  
//      RAM[75] =  8'h4B;  
//      RAM[76] =  8'h4C;  
//      RAM[77] =  8'h4D;  
//      RAM[78] =  8'h4E;  
//      RAM[79] =  8'h4F;  
//      RAM[80] =  8'h50;  
//      RAM[81] =  8'h51;  
//      RAM[82] =  8'h52;  
//      RAM[83] =  8'h53;  
//      RAM[84] =  8'h54;  
//      RAM[85] =  8'h55;  
//      RAM[86] =  8'h56;  
//      RAM[87] =  8'h57;  
//      RAM[88] =  8'h58;  
//      RAM[89] =  8'h59;  
//      RAM[90] =  8'h5A;  
//      RAM[91] =  8'h5B;  
//      RAM[92] =  8'h5C;  
//      RAM[93] =  8'h5D;  
//      RAM[94] =  8'h5E;  
//      RAM[95] =  8'h5F;  
//      RAM[96] =  8'h60;  
//      RAM[97] =  8'h61;  
//      RAM[98] =  8'h62;  
//      RAM[99] =  8'h63;  
//      RAM[100] = 8'h64;  
//      RAM[101] = 8'h65;  
//      RAM[102] = 8'h66;  
//      RAM[103] = 8'h67;  
//      RAM[104] = 8'h68;  
//      RAM[105] = 8'h69;  
//      RAM[106] = 8'h6A;  
//      RAM[107] = 8'h6B;  
//      RAM[108] = 8'h6C;  
//      RAM[109] = 8'h6D;  
//      RAM[110] = 8'h6E;  
//      RAM[111] = 8'h6F;  
//      RAM[112] = 8'h70;  
//      RAM[113] = 8'h71;  
//      RAM[114] = 8'h72;  
//      RAM[115] = 8'h73;  
//      RAM[116] = 8'h74;  
//      RAM[117] = 8'h75;  
//      RAM[118] = 8'h76;  
//      RAM[119] = 8'h77;  
//      RAM[120] = 8'h78;  
//      RAM[121] = 8'h79;  
//      RAM[122] = 8'h7A;  
//      RAM[123] = 8'h7B;  
//      RAM[124] = 8'h7C;  
//      RAM[125] = 8'h7D;  
//      RAM[126] = 8'h7E;  
//      RAM[127] = 8'h7F;  
  end

  always @(negedge CLK)
  begin
    if(WE == 1)
        writefinish = 0;
    if((CS == 1'b1) && (WE == 1'b1)) begin
      RAM[WADDR]     <= Mem_in[7:0];
	    RAM[WADDR + 1] <= Mem_in[15:8];
	    RAM[WADDR + 2] <= Mem_in[23:16];
	    RAM[WADDR + 3] <= Mem_in[31:24];
      writefinish =  1;
	  end
    Mem_out <= {RAM[RADDR+3],RAM[RADDR+2],RAM[RADDR+1],RAM[RADDR]};
  end
endmodule