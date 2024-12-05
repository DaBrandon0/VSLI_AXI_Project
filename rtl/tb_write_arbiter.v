  `timescale 1ns/1ps

module write_arbiter_tb;

    // Parameters
    parameter M = 2;
    parameter S = 2;
    parameter NUM_OUTSTANDING_TRANS = 2;
    parameter ADDR_WIDTH = 32;

    // Clock and reset
    reg clk;
    reg clr;

    // Write address channel signals
    reg [(M*1)-1:0] AW_valid_f;
    reg [(M*ADDR_WIDTH)-1:0] AW_addr_f;
    reg [(M*$clog2(NUM_OUTSTANDING_TRANS))-1:0] AW_id_f;
    wire [(M*1)-1:0] AW_grant_f;
    wire [(M*$clog2(S))-1:0] AW_sel_f;

    // Write data/response channel signals
    reg [(M*1)-1:0] B_ready_f;
    reg [(M*($clog2(NUM_OUTSTANDING_TRANS)))-1:0] W_id_f;
    reg [(S*1)-1:0] B_valid_f;
    wire [(M*1)-1:0] W_grant_f;
    wire [(S*1)-1:0] B_grant_f;
    wire [(M*$clog2(S))-1:0] W_sel_f;
    wire [(S*$clog2(M))-1:0] B_sel_f;

    // Instantiate the write arbiter
    write_arbiter #(
        .M(M),
        .S(S),
        .NUM_OUTSTANDING_TRANS(NUM_OUTSTANDING_TRANS),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) uut (
        .clk(clk),
        .clr(clr),
        .AW_valid_f(AW_valid_f),
        .AW_addr_f(AW_addr_f),
        .AW_id_f(AW_id_f),
        .AW_grant_f(AW_grant_f),
        .AW_sel_f(AW_sel_f),
        .B_ready_f(B_ready_f),
        .W_id_f(W_id_f),
        .B_valid_f(B_valid_f),
        .W_grant_f(W_grant_f),
        .B_grant_f(B_grant_f),
        .W_sel_f(W_sel_f),
        .B_sel_f(B_sel_f)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    // Reset generation
    initial begin
        clr = 0;
        #15;
        clr = 1;
    end

    // Testbench setup (value assignment to inputs)
    initial begin
        // Initialize inputs
        AW_valid_f = 0;
        AW_addr_f = 0;
        AW_id_f = 0;
        B_ready_f = 0;
        W_id_f = 0;
        B_valid_f = 0;

        // Wait for reset de-assertion
        @(posedge clr);
        #10;

        // Master 0 sets up transaction to slave 0 (AW channel)
        AW_valid_f[0] = 1;
        AW_addr_f[ADDR_WIDTH-1:0] = 32'h00000000; // Address targeting slave 0
        AW_id_f[$clog2(NUM_OUTSTANDING_TRANS)-1:0] = 0;
        #100;
        AW_valid_f[0] = 0;

        // Master 0 writes to slave 0 (W/B channel)
        B_ready_f[0] = 1;
        W_id_f[$clog2(NUM_OUTSTANDING_TRANS)-1:0] = 0;
        #50;
        B_valid_f[0] = 1;
        #100;
        B_ready_f[0] = 0;
        B_valid_f[0] = 0;

        // Master 1 sets up transaction to slave 1 (AW channel)
        AW_valid_f[1] = 1;
        AW_addr_f[(2*ADDR_WIDTH)-1:ADDR_WIDTH] = 32'h00010000; // Address targeting slave 1
        AW_id_f[(2*$clog2(NUM_OUTSTANDING_TRANS))-1:$clog2(NUM_OUTSTANDING_TRANS)] = 1;
        #100;
        AW_valid_f[1] = 0;

        // Master 1 writes to slave 1 (W/B channel)
        B_ready_f[1] = 1;
        W_id_f[(2*$clog2(NUM_OUTSTANDING_TRANS))-1:$clog2(NUM_OUTSTANDING_TRANS)] = 1;
        #50;
        B_valid_f[1] = 1;
        #100;
        B_ready_f[1] = 0;
        B_valid_f[1] = 0;

        #200;
        $finish;
    end

endmodule
