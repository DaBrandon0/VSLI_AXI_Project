`timescale 1ns/1ps

module read_arbiter_tb;

    // Parameters
    parameter M = 2;
    parameter S = 2;
    parameter NUM_OUTSTANDING_TRANS = 2;
    parameter ADDR_WIDTH = 32;

    // Clock and Reset
    reg clk;
    reg clr;

    // Read Address Channel Signals
    reg [(M*1)-1:0] AR_request_f;
    reg [(M*ADDR_WIDTH)-1:0] AR_addr_f;
    reg [(M*$clog2(NUM_OUTSTANDING_TRANS))-1:0] AR_id_f;
    wire [(M*1)-1:0] AR_grant_f;
    wire [(M*$clog2(S))-1:0] AR_sel_f;

    // Read Data Channel Signals
    reg [(M*1)-1:0] R_request_f;
    reg [(M*ADDR_WIDTH)-1:0] R_addr_f;
    reg [(M*($clog2(M)+$clog2(NUM_OUTSTANDING_TRANS)))-1:0] R_id_f;
    reg [(M*1)-1:0] R_last_f;
    wire [(M*1)-1:0] R_grant_f;
    wire [(M*$clog2(S))-1:0] R_sel_f;

    // Instantiate the read_arbiter
    read_arbiter #(
        .M(M),
        .S(S),
        .NUM_OUTSTANDING_TRANS(NUM_OUTSTANDING_TRANS),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) uut (
        .clk(clk),
        .clr(clr),
        
        // Read address channel signals
        .AR_request_f(AR_request_f),
        .AR_addr_f(AR_addr_f),
        .AR_id_f(AR_id_f),
        .AR_grant_f(AR_grant_f),
        .AR_sel_f(AR_sel_f),
        
        // Read data channel signals
        .R_request_f(R_request_f),
        .R_addr_f(R_addr_f),
        .R_id_f(R_id_f),
        .R_last_f(R_last_f),
        .R_grant_f(R_grant_f),
        .R_sel_f(R_sel_f)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns clock period (100 MHz)
    end

    // Reset Logic
    initial begin
        clr = 0;
        #20;
        clr = 1; // Release reset after 20ns
    end

    // Initial Setup
    initial begin
        // Initialize inputs to zero
        AR_request_f = 0;
        AR_addr_f = 0;
        AR_id_f = 0;
        R_request_f = 0;
        R_addr_f = 0;
        R_id_f = 0;
        R_last_f = 0;

        // Test master 0 sending to slave 0
        #30;
        AR_request_f[0] = 1; // Master 0 requests
        AR_addr_f[ADDR_WIDTH-1:0] = 32'h0000_0000; // Address for slave 0
        AR_id_f[$clog2(NUM_OUTSTANDING_TRANS)-1:0] = 0;
        #200;
        AR_request_f[0] = 0; // Drop request after some time

        // Test master 0 sending to slave 1
        #50;
        AR_request_f[0] = 1; // Master 0 requests
        AR_addr_f[ADDR_WIDTH-1:0] = 32'h0001_0000; // Address for slave 1
        AR_id_f[$clog2(NUM_OUTSTANDING_TRANS)-1:0] = 1;
        #200;
        AR_request_f[0] = 0; // Drop request after some time

        // Test master 1 sending to slave 0
        #50;
        AR_request_f[1] = 1; // Master 1 requests
        AR_addr_f[(2*ADDR_WIDTH)-1:ADDR_WIDTH] = 32'h0000_0000; // Address for slave 0
        AR_id_f[(2*$clog2(NUM_OUTSTANDING_TRANS))-1:$clog2(NUM_OUTSTANDING_TRANS)] = 0;
        #200;
        AR_request_f[1] = 0; // Drop request after some time

        // Test master 1 sending to slave 1
        #50;
        AR_request_f[1] = 1; // Master 1 requests
        AR_addr_f[(2*ADDR_WIDTH)-1:ADDR_WIDTH] = 32'h0001_0000; // Address for slave 1
        AR_id_f[(2*$clog2(NUM_OUTSTANDING_TRANS))-1:$clog2(NUM_OUTSTANDING_TRANS)] = 1;
        #200;
        AR_request_f[1] = 0; // Drop request after some time

        // Test slave 0 sending to master 0
        #50;
        R_request_f[0] = 1; // Slave 0 requests
        R_addr_f[ADDR_WIDTH-1:0] = 32'h0000_0000; // Address for master 0
        R_id_f[($clog2(M)+$clog2(NUM_OUTSTANDING_TRANS))-1:0] = 0;
        #200;
        R_last_f[0] = 1; // Assert R_last to complete transaction
        #10;
        R_request_f[0] = 0;
        R_last_f[0] = 0;

        // Test slave 0 sending to master 0
        #50;
        R_request_f[1] = 1; // Slave 1 requests
        R_addr_f[(2*ADDR_WIDTH)-1:ADDR_WIDTH] = 32'h0000_0000; // Address for master 0
        R_id_f[(2*($clog2(M)+$clog2(NUM_OUTSTANDING_TRANS)))-1:($clog2(M)+$clog2(NUM_OUTSTANDING_TRANS))] = 1;
        #200;
        R_last_f[1] = 1; // Assert R_last to complete transaction
        #10;
        R_request_f[1] = 0;
        R_last_f[1] = 0;

        // Simulation duration
        #2000;
        $finish;
    end

endmodule
