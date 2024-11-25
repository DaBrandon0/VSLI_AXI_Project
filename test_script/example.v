module example (
    input clk,
    input reset,
    input CarDetected,
    output reg [1:0] LightState,
    output reg TimerExpired
);

    reg [1:0] current_state;
    reg [1:0] next_state;

    // State encodings
    parameter RED = 2'd0;
    parameter GREEN = 2'd1;
    parameter YELLOW = 2'd2;

    // State transition
    always @(posedge clk or negedge reset) begin
        if (!reset)
            current_state <= RED;
        else
            current_state <= next_state;
    end

    // Next state and output logic
    always @(*) begin
        next_state = current_state;
        LightState = 2'd0;
        TimerExpired = 0;

        case (current_state)
            RED: begin
                if (CarDetected == 0) begin
                    next_state = RED;
                    LightState = 2'd0;
                    TimerExpired = 0;
                end
                if (CarDetected == 1) begin
                    next_state = GREEN;
                    LightState = 2'd1;
                    TimerExpired = 0;
                end
            end
            GREEN: begin
                if (CarDetected == 0) begin
                    next_state = YELLOW;
                    LightState = 2'd2;
                    TimerExpired = 1;
                end
            end
            YELLOW: begin
                if (CarDetected == 0) begin
                    next_state = RED;
                    LightState = 2'd0;
                    TimerExpired = 1;
                end
            end
        endcase
    end

endmodule
