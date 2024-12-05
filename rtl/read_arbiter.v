`timescale 1ns/1ps

module read_arbiter #(
    parameter M = 2,
    parameter S = 2,
    parameter NUM_OUTSTANDING_TRANS = 2,
    parameter ADDR_WIDTH = 32
)(
    input clk,
    input clr,

    // read address channel signals
    input [(M*1)-1:0] AR_request_f,
    input [(M*ADDR_WIDTH)-1:0] AR_addr_f,
    input [(M*$clog2(NUM_OUTSTANDING_TRANS))-1:0] AR_id_f,
    output [(M*1)-1:0] AR_grant_f,
    output [(M*$clog2(S))-1:0] AR_sel_f,

    // read data channel signals
    input [(M*1)-1:0] R_request_f,
    input [(M*ADDR_WIDTH)-1:0] R_addr_f,
    input [(M*($clog2(M)+$clog2(NUM_OUTSTANDING_TRANS)))-1:0] R_id_f,
    output [(M*1)-1:0] R_grant_f,
    output [(M*$clog2(S))-1:0] R_sel_f
);
    genvar i, j;
    integer x, y;

    // unflatten signals
    wire [1-1:0] AR_request [M-1:0];
    wire [ADDR_WIDTH-1:0] AR_addr [M-1:0];
    wire [($clog2(NUM_OUTSTANDING_TRANS))-1:0] AR_id [M-1:0];
    reg [1-1:0] AR_grant [M-1:0];
    wire [$clog2(S)-1:0] AR_sel [M-1:0];

    wire [1-1:0] R_request [M-1:0];
    wire [ADDR_WIDTH-1:0] R_addr [M-1:0];
    wire [($clog2(M)+$clog2(NUM_OUTSTANDING_TRANS))-1:0] R_id [M-1:0];
    reg [1-1:0] R_grant [M-1:0];
    wire [$clog2(S)-1:0] R_sel [M-1:0];

    generate
        for (i = 0; i < M; i = i + 1) begin : UNFLATTEN
            assign AR_request[i] = AR_request_f[i];
            assign AR_addr[i] = AR_addr_f[(i+1)*ADDR_WIDTH-1:i*ADDR_WIDTH];
            assign AR_id[i] = AR_id_f[(i+1)*$clog2(NUM_OUTSTANDING_TRANS)-1:i*$clog2(NUM_OUTSTANDING_TRANS)];
            assign AR_grant_f[i] = AR_grant[i];
            assign AR_sel_f[(i+1)*$clog2(S)-1:i*$clog2(S)] = AR_sel[i];

            assign R_request[i] = R_request_f[i];
            assign R_addr[i] = R_addr_f[(i+1)*ADDR_WIDTH-1:i*ADDR_WIDTH];
            assign R_id[i] = R_addr_f[(i+1)*($clog2(M)+$clog2(NUM_OUTSTANDING_TRANS))-1:i*($clog2(M)+$clog2(NUM_OUTSTANDING_TRANS))];
            assign R_grant_f[i] = R_grant[i];
            assign R_sel_f[(i+1)*$clog2(S)-1:i*$clog2(S)] = R_sel[i];
        end
    endgenerate

    // address decode
    generate
        for (i = 0; i < M; i = i + 1) begin : addr_decode_gen
            addr_decode #(
                .ADDR_WIDTH(ADDR_WIDTH)
            ) addr_decode (
                .addr(AR_addr[i]),
                .sel(AR_sel[i])
            );
        end
    endgenerate

    // in order fifo
    localparam FIFO_DATA_SIZE = $clog2(S);

    reg ID_fifo_write_en [NUM_OUTSTANDING_TRANS-1:0][M-1:0];
    reg ID_fifo_read_en [NUM_OUTSTANDING_TRANS-1:0][M-1:0];
    reg [FIFO_DATA_SIZE-1:0] ID_fifo_data_in [NUM_OUTSTANDING_TRANS-1:0][M-1:0];
    wire [FIFO_DATA_SIZE-1:0] ID_fifo_data_out [NUM_OUTSTANDING_TRANS-1:0][M-1:0];
    wire ID_fifo_empty [NUM_OUTSTANDING_TRANS-1:0][M-1:0];
    wire ID_fifo_full [NUM_OUTSTANDING_TRANS-1:0][M-1:0];

    generate
        for (i = 0; i < NUM_OUTSTANDING_TRANS; i = i + 1) begin : FIFO_TRANS
            for (j = 0; j < M; j = j + 1) begin : FIFO_INSTANCES
                fifo #(
                    .DATA_WIDTH(FIFO_DATA_SIZE),
                    .DEPTH(NUM_OUTSTANDING_TRANS)
                ) fifo_inst (
                    .clk(clk),
                    .clr(clr),
                    .read_en(ID_fifo_read_en[i][j]),
                    .write_en(ID_fifo_write_en[i][j]),
                    .data_in(ID_fifo_data_in[i][j]),
                    .data_out(ID_fifo_data_out[i][j]),
                    .empty(ID_fifo_empty[i][j]),
                    .full(ID_fifo_full[i][j])
                );
            end
        end
    endgenerate

    // read address channel arbiter
    reg [$clog2(M)-1:0] AR_sender;
    reg [2-1:0] curr_state, next_state;

    localparam IDLE     = 0;
    localparam REGISTER = 1;
    localparam ALLOW    = 2;

    always @(posedge clk or negedge clr) begin
        if (!clr) begin
            curr_state <= IDLE;
            AR_sender <= 0;
        end else begin
            curr_state <= next_state;

            case (curr_state)
                IDLE: begin
                    if (!(AR_request[AR_sender] && !ID_fifo_full[AR_id[AR_sender]][AR_sender])) begin
                        AR_sender <= (AR_sender + 1) % M;
                    end
                end

                ALLOW: begin
                    if (!(AR_request[AR_sender] && !ID_fifo_full[AR_id[AR_sender]][AR_sender])) begin
                        AR_sender <= (AR_sender + 1) % M;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        case (curr_state)
            IDLE: begin
                for (x = 0; x < M; x = x + 1) begin
                    AR_grant[x] = 0;
                end

                for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
                    for (y = 0; y < M; y = y + 1) begin
                        ID_fifo_write_en[x][y] = 0;
                        ID_fifo_data_in[x][y] = 0;
                    end
                end

                if (AR_request[AR_sender] && !ID_fifo_full[AR_id[AR_sender]][AR_sender]) begin
                    next_state = REGISTER;
                end else begin
                    next_state = IDLE;
                end
            end

            REGISTER: begin
                for (x = 0; x < M; x = x + 1) begin
                    AR_grant[x] = 0;
                end

                for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
                    for (y = 0; y < M; y = y + 1) begin
                        ID_fifo_write_en[x][y] = 0;
                        ID_fifo_data_in[x][y] = 0;
                    end
                end

                ID_fifo_write_en[AR_id[AR_sender]][AR_sender] = 1;
                ID_fifo_data_in[AR_id[AR_sender]][AR_sender] = {AR_sel[AR_sender]};

                next_state = ALLOW;
            end

            ALLOW: begin
                for (x = 0; x < M; x = x + 1) begin
                    AR_grant[x] = 0;
                end

                AR_grant[AR_sender] = 1;

                for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
                    for (y = 0; y < M; y = y + 1) begin
                        ID_fifo_write_en[x][y] = 0;
                        ID_fifo_data_in[x][y] = 0;
                    end
                end

                if (!AR_request[AR_sender]) begin
                    next_state = IDLE;
                end else begin
                    next_state = ALLOW;
                end
            end
        endcase
    end

endmodule