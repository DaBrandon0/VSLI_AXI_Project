`timescale 1ns / 1ps

module example_tb;

    // Inputs
    reg clk;
    reg reset;
    reg CarDetected;

    // Outputs
    wire [1:0] LightState;
    wire TimerExpired;

    // Instantiate the Unit Under Test (UUT)
    example uut (
        .clk(clk),
        .reset(reset),
        .CarDetected(CarDetected),
        .LightState(LightState),
        .TimerExpired(TimerExpired)
    );

    // Clock generation: 10ns period (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test stimulus
    initial begin
        // Initialize Inputs
        reset = 0;
        CarDetected = 0;

        // Apply reset
        #10;
        reset = 1;
        #10;

        // Test Case 1: No car detected, light should stay RED
        CarDetected = 0;
        #50; // Wait for 50ns

        // Test Case 2: Car detected, light should turn GREEN
        CarDetected = 1;
        #50;

        // Test Case 3: Car no longer detected, light should go to YELLOW, then RED
        CarDetected = 0;
        #100;

        // Test Case 4: Another car arrives, light should turn GREEN again
        CarDetected = 1;
        #50;

        // Test Case 5: Continuous detection and loss of car
        CarDetected = 0;
        #50;
        CarDetected = 1;
        #50;
        CarDetected = 0;
        #100;

        // End simulation
        #100;
        $stop;
    end

    // Monitor outputs
    initial begin
        $monitor("Time=%0t | reset=%b | CarDetected=%b | LightState=%b | TimerExpired=%b",
                 $time, reset, CarDetected, LightState, TimerExpired);
    end

endmodule
