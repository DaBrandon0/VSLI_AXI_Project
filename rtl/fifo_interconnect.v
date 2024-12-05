`timescale 1ns/1ps

module fifo_interconnect #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 2
)(
    input clk,
    input clr,                              // clear FIFO (active low)
    input read_en,                          // enable read
    input write_en,                         // enable write
    input [DATA_WIDTH-1:0] data_in,         // data input
    output reg [DATA_WIDTH-1:0] data_out,   // data output
    output empty,                           // indicates if FIFO is empty
    output full,                            // indicates the FIFO is full
    output [DATA_WIDTH-1:0] head            // head of FIFO (what you would read)
);

    // parameters
    localparam ADDR_WIDTH = $clog2(DEPTH);

    // internal signals
    reg [DATA_WIDTH-1:0] mem [DEPTH-1:0];
    reg [ADDR_WIDTH-1:0] write_ptr, read_ptr;
    reg [ADDR_WIDTH:0] count;
    reg prev_read_en;

    // assignments
    wire read_allowed = (read_en && !empty);
    wire write_allowed = (write_en && !full);
    assign empty = (count == 0);
    assign full = (count == DEPTH);
    assign head = mem[read_ptr];

    // FIFO logic
    always @(posedge clk or negedge clr) begin
        if (!clr) begin
            write_ptr <= 0;
            read_ptr <= 0;
            data_out <= 0;
            count <= 0;
        end else begin
            // write
            if (write_allowed) begin
                mem[write_ptr] <= data_in;
                write_ptr <= write_ptr + 1;
            end

            // read
            if (read_allowed) begin
                data_out <= mem[read_ptr];
                read_ptr <= read_ptr + 1;
            end

            // count
            if (write_allowed && !(read_allowed)) begin
                count <= count + 1;
            end else if (!(write_allowed) && (read_allowed)) begin
                count <= count - 1;
            end else begin
                count <= count;
            end
        end
    end
endmodule