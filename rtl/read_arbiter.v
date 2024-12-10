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
    input [(S*1)-1:0] AR_finish_f,
    input [(M*ADDR_WIDTH)-1:0] AR_addr_f,
    input [(M*$clog2(NUM_OUTSTANDING_TRANS))-1:0] AR_id_f,
    output [(M*1)-1:0] AR_grant_f,
    output [(M*$clog2(S))-1:0] AR_sel_f,

    // read data channel signals
    input [(M*1)-1:0] R_request_f,
    input [(M*($clog2(M)+$clog2(NUM_OUTSTANDING_TRANS)))-1:0] R_id_f,
    input [(S*1)-1:0] R_last_f,
    output [(S*1)-1:0] R_grant_f,
    output [(S*$clog2(M))-1:0] R_sel_f
);
    genvar i, j;
    integer x, y;

    // unflatten signals
    wire [1-1:0] AR_request [M-1:0];
    wire [1-1:0] AR_finish [S-1:0];
    wire [ADDR_WIDTH-1:0] AR_addr [M-1:0];
    wire [($clog2(NUM_OUTSTANDING_TRANS))-1:0] AR_id [M-1:0];
    reg [1-1:0] AR_grant [M-1:0];
    wire [$clog2(S)-1:0] AR_sel [M-1:0];

    wire [1-1:0] R_request [M-1:0];
    wire [$clog2(M)-1:0] R_master_id [M-1:0];
    wire [$clog2(NUM_OUTSTANDING_TRANS)-1:0] R_transaction_id [M-1:0];
    wire [1-1:0] R_last [M-1:0];
    reg [1-1:0] R_grant [M-1:0];
    // wire [$clog2(S)-1:0] R_sel [M-1:0];

    generate
        for (i = 0; i < M; i = i + 1) begin : UNFLATTEN
            assign AR_request[i] = AR_request_f[i];
            assign AR_finish[i] = AR_finish_f[i];
            assign AR_addr[i] = AR_addr_f[(i+1)*ADDR_WIDTH-1:i*ADDR_WIDTH];
            assign AR_id[i] = AR_id_f[(i+1)*$clog2(NUM_OUTSTANDING_TRANS)-1:i*$clog2(NUM_OUTSTANDING_TRANS)];
            assign AR_grant_f[i] = AR_grant[i];
            assign AR_sel_f[(i+1)*$clog2(S)-1:i*$clog2(S)] = AR_sel[i];

            assign R_request[i] = R_request_f[i];
            assign R_master_id[i] = R_id_f[(i+1)*($clog2(M) + $clog2(NUM_OUTSTANDING_TRANS)) - 1 :
                                            (i+1)*$clog2(NUM_OUTSTANDING_TRANS)];
            assign R_transaction_id[i] = R_id_f[(i+1)*$clog2(NUM_OUTSTANDING_TRANS) - 1 :
                                                i*$clog2(NUM_OUTSTANDING_TRANS)];
            assign R_last[i] = R_last_f[i];
            assign R_grant_f[i] = R_grant[i];
            assign R_sel_f[(i+1)*$clog2(S)-1:i*$clog2(S)] = R_master_id[i];
        end
    endgenerate

    // address decode
    generate
        for (i = 0; i < M; i = i + 1) begin : addr_decode_gen
            addr_decode #(
                .ADDR_WIDTH(ADDR_WIDTH),
                .S(S),
                .SLICE_SIZE(32'h00010000)
            ) addr_decode (
                .addr(AR_addr[i]),
                .sel(AR_sel[i])
            );
        end
    endgenerate

    // in order fifo
    localparam FIFO_DATA_SIZE = $clog2(S);

    reg ID_fifo_write_en [M-1:0][NUM_OUTSTANDING_TRANS-1:0];
    reg ID_fifo_read_en [M-1:0][NUM_OUTSTANDING_TRANS-1:0];
    reg [FIFO_DATA_SIZE-1:0] ID_fifo_data_in [M-1:0][NUM_OUTSTANDING_TRANS-1:0];
    wire [FIFO_DATA_SIZE-1:0] ID_fifo_data_out [M-1:0][NUM_OUTSTANDING_TRANS-1:0];
    wire ID_fifo_empty [M-1:0][NUM_OUTSTANDING_TRANS-1:0];
    wire ID_fifo_full [M-1:0][NUM_OUTSTANDING_TRANS-1:0];
    wire [FIFO_DATA_SIZE-1:0] ID_fifo_head [M-1:0][NUM_OUTSTANDING_TRANS-1:0];

    generate
        for (i = 0; i < M; i = i + 1) begin : FIFO_INSTANCES
            for (j = 0; j < NUM_OUTSTANDING_TRANS; j = j + 1) begin : FIFO_INSTANCES_TRANS
                fifo_interconnect #(
                    .DATA_WIDTH(FIFO_DATA_SIZE),
                    .DEPTH(1)
                ) fifo_inst (
                    .clk(clk),
                    .clr(clr),
                    .read_en(ID_fifo_read_en[i][j]),
                    .write_en(ID_fifo_write_en[i][j]),
                    .data_in(ID_fifo_data_in[i][j]),
                    .data_out(ID_fifo_data_out[i][j]),
                    .empty(ID_fifo_empty[i][j]),
                    .full(ID_fifo_full[i][j]),
                    .head(ID_fifo_head[i][j])
                );
            end
        end
    endgenerate

    // read address channel arbiter
    reg [$clog2(M)-1:0] AR_sender;
    reg [2-1:0] AR_curr_state, AR_next_state;

    localparam AR_IDLE     = 0;
    localparam AR_REGISTER = 1;
    localparam AR_ALLOW    = 2;

    always @(posedge clk or negedge clr) begin
        if (!clr) begin
            AR_curr_state <= AR_IDLE;
            AR_sender <= 0;
        end else begin
            AR_curr_state <= AR_next_state;

            case (AR_curr_state)
                AR_IDLE: begin
                    if (AR_next_state == AR_IDLE) begin
                        AR_sender <= (AR_sender + 1) % M;
                    end
                end

                AR_ALLOW: begin
                    if (AR_next_state == AR_IDLE) begin
                        AR_sender <= (AR_sender + 1) % M;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        case (AR_curr_state)
            AR_IDLE: begin
                for (x = 0; x < M; x = x + 1) begin
                    AR_grant[x] = 0;
                end

                for (x = 0; x < M; x = x + 1) begin
                    for (y = 0; y < NUM_OUTSTANDING_TRANS; y = y + 1) begin
                        ID_fifo_write_en[x][y] = 0;
                        ID_fifo_data_in[x][y] = 0;
                    end
                end

                if (AR_request[AR_sender] && !(ID_fifo_full[AR_sender][AR_id[AR_sender]])) begin
                    AR_next_state = AR_REGISTER;
                end else begin
                    AR_next_state = AR_IDLE;
                end
            end

            AR_REGISTER: begin
                for (x = 0; x < M; x = x + 1) begin
                    AR_grant[x] = 0;
                end

                for (x = 0; x < M; x = x + 1) begin
                    for (y = 0; y < NUM_OUTSTANDING_TRANS; y = y + 1) begin
                        ID_fifo_write_en[x][y] = 0;
                        ID_fifo_data_in[x][y] = 0;
                    end
                end

                ID_fifo_write_en[AR_sender][AR_id[AR_sender]] = 1;
                ID_fifo_data_in[AR_sender][AR_id[AR_sender]] = {AR_sel[AR_sender]};

                AR_next_state = AR_ALLOW;
            end

            AR_ALLOW: begin
                for (x = 0; x < M; x = x + 1) begin
                    AR_grant[x] = 0;
                end

                AR_grant[AR_sender] = 1;

                for (x = 0; x < M; x = x + 1) begin
                    for (y = 0; y < NUM_OUTSTANDING_TRANS; y = y + 1) begin
                        ID_fifo_write_en[x][y] = 0;
                        ID_fifo_data_in[x][y] = 0;
                    end
                end

                if (AR_finish[AR_sender]) begin
                    AR_next_state = AR_IDLE;
                end else begin
                    AR_next_state = AR_ALLOW;
                end
            end
        endcase
    end

    // read data channel arbiter
    reg [$clog2(S)-1:0] R_sender;
    reg [2-1:0] R_curr_state, R_next_state;

    localparam R_IDLE     = 0;
    localparam R_UNREGISTER = 1;
    localparam R_ALLOW    = 2;

    always @(posedge clk or negedge clr) begin
        if (!clr) begin
            R_curr_state <= R_IDLE;
            R_sender <= 0;
        end else begin
            R_curr_state <= R_next_state;

            case (R_curr_state)
                R_IDLE: begin
                    if (R_next_state == R_IDLE) begin
                        R_sender <= (R_sender + 1) % S;
                    end
                end

                R_ALLOW: begin
                    if (R_next_state == R_IDLE) begin
                        R_sender <= (R_sender + 1) % S;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        case (R_curr_state)
            R_IDLE: begin
                for (x = 0; x < S; x = x + 1) begin
                    R_grant[x] = 0;
                end

                for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
                    for (y = 0; y < M; y = y + 1) begin
                        ID_fifo_read_en[x][y] = 0;
                    end
                end

                if (R_request[R_sender] &&
                    !ID_fifo_empty[R_master_id[R_sender]][R_transaction_id[R_sender]] &&
                    ID_fifo_head[R_master_id[R_sender]][R_transaction_id[R_sender]] == R_sender) begin
                    R_next_state = R_UNREGISTER;
                end else begin
                    R_next_state = R_IDLE;
                end
            end

            R_UNREGISTER: begin
                for (x = 0; x < S; x = x + 1) begin
                    R_grant[x] = 0;
                end

                for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
                    for (y = 0; y < M; y = y + 1) begin
                        ID_fifo_read_en[x][y] = 0;
                    end
                end

                ID_fifo_read_en[R_master_id[R_sender]][R_transaction_id[R_sender]] = 1;

                R_next_state = R_ALLOW;
            end

            R_ALLOW: begin
                for (x = 0; x < S; x = x + 1) begin
                    R_grant[x] = 0;
                end

                R_grant[R_sender] = 1;

                for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
                    for (y = 0; y < M; y = y + 1) begin
                        ID_fifo_read_en[x][y] = 0;
                    end
                end

                if (R_last[R_sender]) begin
                    R_next_state = R_IDLE;
                end else begin
                    R_next_state = R_ALLOW;
                end
            end
        endcase
    end

endmodule
