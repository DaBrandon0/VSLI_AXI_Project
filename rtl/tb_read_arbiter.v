`timescale 1ns/1ps

module read_arbiter_tb;
    // Parameters
    parameter M = 2;
    parameter S = 2;
    parameter NUM_OUTSTANDING_TRANS = 2;
    parameter ADDR_WIDTH = 32;

    // Signals
    reg clk;
    reg clr;
    reg [(M*1)-1:0] AR_request_f;
    reg [(M*ADDR_WIDTH)-1:0] AR_addr_f;
    reg [(M*$clog2(NUM_OUTSTANDING_TRANS))-1:0] AR_id_f;
    wire [(M*1)-1:0] AR_grant_f;
    wire [(M*$clog2(S))-1:0] AR_sel_f;

    // Instantiate the module under test
    read_arbiter #(
        .M(M),
        .S(S),
        .NUM_OUTSTANDING_TRANS(NUM_OUTSTANDING_TRANS),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) uut (
        .clk(clk),
        .clr(clr),
        .AR_request_f(AR_request_f),
        .AR_addr_f(AR_addr_f),
        .AR_id_f(AR_id_f),
        .AR_grant_f(AR_grant_f),
        .AR_sel_f(AR_sel_f)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period
    end

    // Test sequence
    initial begin
        // Initialization
        clr = 1;
        AR_request_f = 0;
        AR_addr_f = 0;
        AR_id_f = 0;

        // Reset
        clr = 0;
        #10;
        clr = 1;

        // Test Case 1: Single Master Request
        AR_request_f[0] = 1;
        AR_addr_f[ADDR_WIDTH-1:0] = 32'hA000_0000;
        AR_id_f[$clog2(NUM_OUTSTANDING_TRANS)-1:0] = 0;
        #20;

        AR_request_f[0] = 0;
        #20;

        // Test Case 2: Multiple Master Requests
        AR_request_f[0] = 1;
        AR_request_f[1] = 1;
        AR_addr_f[(1*ADDR_WIDTH)-1:0] = 32'hB000_0000;
        AR_addr_f[(2*ADDR_WIDTH)-1:ADDR_WIDTH] = 32'hC000_0000;
        AR_id_f[($clog2(NUM_OUTSTANDING_TRANS))-1:0] = 0;
        AR_id_f[(2*$clog2(NUM_OUTSTANDING_TRANS))-1:($clog2(NUM_OUTSTANDING_TRANS))] = 1;
        #40;

        AR_request_f[0] = 0;
        #40;

        AR_request_f = 0;
        #200;

        // Test Case 3: Back-to-Back Requests
        AR_request_f[0] = 1;
        AR_addr_f[ADDR_WIDTH-1:0] = 32'hD000_0000;
        AR_id_f[$clog2(NUM_OUTSTANDING_TRANS)-1:0] = 0;
        #20;

        AR_request_f[0] = 0;
        AR_request_f[1] = 1;
        AR_addr_f[(2*ADDR_WIDTH)-1:ADDR_WIDTH] = 32'hE000_0000;
        AR_id_f[(2*$clog2(NUM_OUTSTANDING_TRANS))-1:($clog2(NUM_OUTSTANDING_TRANS))] = 1;
        #20;

        AR_request_f = 0;
        #20;

        // End of test
        $stop;
    end
endmodule