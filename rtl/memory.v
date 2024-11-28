//UNMODIFIED from lab 3
//can maybe adjust this to use as our memory module for testing programs?

//
// mem.v
//
// David Van Campenhout
//
// Very simple memory: 
// 	memory samples at posedge phi1
//


`define memsize 81920
`include "test.config"

module memory( dataBus, addressBus, r, w, phi1, phi2);
  
  inout [31:0] 	dataBus; 	
  input [25:0] 	addressBus;
  input 	r;
  input 	w;
  input		phi1;
  input		phi2;
  reg	[31:0]	wordAddress;
  reg	[31:0]	value;

  reg	[31:0]	mem[0:`memsize];

  initial 
	begin
case (`TESTPROGRAM)
	`TEST_MULTI : 
	if (`BINFILE) $readmemb(`RAMFILE_MULTI, mem, 0, `memsize - 1);
	else $readmemh(`RAMFILE_MULTI, mem, 0, `memsize - 1);
	`TEST_MULT : 
	if (`BINFILE) $readmemb(`RAMFILE_MULT, mem, 0, `memsize - 1);
	else $readmemh(`RAMFILE_MULT, mem, 0, `memsize - 1);
	`TEST_DIV : 
	if (`BINFILE) $readmemb(`RAMFILE_DIV, mem, 0, `memsize - 1);
	else $readmemh(`RAMFILE_DIV, mem, 0, `memsize - 1);
	endcase
	
	end


//  tribuf #(`numbits,`imptype,`group)
//	dataOut_tribuf( .EN(r), .IN0(value), .Y(dataBus));

  assign dataBus = (r) ? value : 32'bz;

  always @(posedge phi1)
	begin
	wordAddress = addressBus >> 2;
	if (w)
		begin
		if (wordAddress >= `memsize) ; 	//error 
		mem[wordAddress] = dataBus;
		end
	end

// read
  
  always @(r or addressBus)
	begin
	#1;
	wordAddress = addressBus >> 2;
	if (r)
		begin
		if (wordAddress >= `memsize) ;	// error 
		value = mem[wordAddress];
		end
	end

endmodule
	







