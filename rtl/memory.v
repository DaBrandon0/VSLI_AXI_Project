module Memory(CS, WE, CLK, WADDR, RADDR, Mem_in, Mem_out);
  input CS;
  input WE;
  input CLK;
  input [6:0] WADDR;
  input [6:0] RADDR;
  input [31:0] Mem_in;
  input [31:0] Mem_out;

  reg [31:0] data_out;
  reg [7:0] RAM [0:127];
  integer i;
  initial
  begin
    $readmemh("memories.mem",RAM);
  end

  always @(negedge CLK)
  begin
    if((CS == 1'b1) && (WE == 1'b1))
	begin
      RAM[ADDR1] <= MEM_in[7:0];
	  RAM[ADDR2] <= MEM_in[15:8];
	  RAM[ADDR3] <= MEM_in[23:16];
	  RAM[ADDR4] <= MEM_in[31:24];
	end
    MEM_out <= {RAM[RADDR+3],RAM[RADDR+2],RAM[RADDR+1],RAM[RADDR]};
  end
endmodule