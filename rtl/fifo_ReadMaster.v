`timescale 1ns/1ps

module fifo_ReadMaster #(
    parameter tagbits = 1
)
//50 bits per entry
(
    input wire clk,
    input wire rst,
    input wire write_en,
    input wire read_en,
    input [48 + tagbits:0] entry_in,
    output [48 + tagbits:0] entry_out,
    output empty,
    output full
);
    // order of things
    // input [TagBits-1:0] id_in,         //high 2 bits
    // input [BusWidth - 1:0] address_in,      //32 bits
    // input [3:0] len_in,                     //4 bits
    // input [1:0] size_in,                    //2 bits
    // input [1:0] burst_in,                   //2 bits
    // input [1:0] lock_in,                    //2 bits
    // input [3:0] cache_in,                   //4 bits
    // input [2:0] prot_in,                //low 3 bits 

    // Combined field structure
    //2 + 32 + 4 + 2 + 2 + 2 + 4 + 3 = 51 bits per entry, 48 + 2 = [50:0]
    //1 + 32 + 4 + 2 + 2 + 2 + 4 + 3 = 50 bits per entry, 48 + 1 = [49:0]
    reg [48 + tagbits:0] fifo [0:1]; 
    
    reg write_ptr;
    reg read_ptr;
    reg [1:0] count;
    // Write operation
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            write_ptr <= 0;
            count = 0;
            read_ptr <= 0;
        end
        else begin
            //read
            if (read_en && !empty) begin
                read_ptr <= read_ptr + 1;
                count = count - 1;
            end
            //write
            if (write_en && !full) begin
                fifo[write_ptr] <= entry_in;
                write_ptr <= write_ptr + 1;
                count = count + 1;
            end
        end
    end

assign entry_out = fifo[read_ptr];
assign empty = count == 0;
assign full = count == 2;
endmodule

