module Memory(CS, WE, CLK, ADDR, Mem_in, Mem_out);
  input CS;
  input WE;
  input CLK;
  input [6:0] ADDR;
  input [31:0] Mem_in;
  input [31:0] Mem_out;

  reg [31:0] data_out;
  reg [31:0] RAM [0:127];
  integer i;
  initial
  begin
    $readmemh("memories.mem",RAM);
  end

  always @(negedge CLK)
  begin
    if((CS == 1'b1) && (WE == 1'b1))
	begin
      RAM[ADDR] <= MEM_in[31:0];
	end
    MEM_out <= RAM[ADDR];
  end
endmodule