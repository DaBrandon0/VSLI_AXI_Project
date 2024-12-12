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
    input [(S*($clog2(M)+$clog2(NUM_OUTSTANDING_TRANS)))-1:0] R_id_f,
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
            assign R_last[i] = R_last_f[i];
            assign R_grant_f[i] = R_grant[i];
            assign R_sel_f[(i+1)*$clog2(S)-1:i*$clog2(S)] = R_master_id[i];
        end
    endgenerate
    assign R_transaction_id[0] = R_id_f[0];
    assign R_transaction_id[1] = R_id_f[2];
    assign R_master_id[0] = R_id_f[1];
    assign R_master_id[1] = R_id_f[3];

    // address decode
    generate
        for (i = 0; i < M; i = i + 1) begin : addr_decode_gen
            addr_decode #(
                .ADDR_WIDTH(ADDR_WIDTH),
                .S(S),
                .SLICE_SIZE(32'h00000080)
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

    // read address channel arbiter master 0
    wire [$clog2(M)-1:0] M0_AR_sender = 0;
    reg [2-1:0] M0_AR_curr_state, M0_AR_next_state;

    localparam M0_AR_IDLE     = 0;
    localparam M0_AR_REGISTER = 1;
    localparam M0_AR_ALLOW    = 2;

    always @(posedge clk or negedge clr) begin
        if (!clr) begin
            M0_AR_curr_state <= M0_AR_IDLE;
        end else begin
            M0_AR_curr_state <= M0_AR_next_state;
        end
    end

    always @(*) begin
        case (M0_AR_curr_state)
            M0_AR_IDLE: begin
                AR_grant[M0_AR_sender] = 0;

                for (y = 0; y < NUM_OUTSTANDING_TRANS; y = y + 1) begin
                    ID_fifo_write_en[M0_AR_sender][y] = 0;
                    ID_fifo_data_in[M0_AR_sender][y] = 0;
                end

                if (AR_request[M0_AR_sender] && !(ID_fifo_full[M0_AR_sender][AR_id[M0_AR_sender]])) begin
                    M0_AR_next_state = M0_AR_REGISTER;
                end else begin
                    M0_AR_next_state = M0_AR_IDLE;
                end
            end

            M0_AR_REGISTER: begin
                AR_grant[M0_AR_sender] = 0;

                for (y = 0; y < NUM_OUTSTANDING_TRANS; y = y + 1) begin
                    ID_fifo_write_en[M0_AR_sender][y] = 0;
                    ID_fifo_data_in[M0_AR_sender][y] = 0;
                end

                ID_fifo_write_en[M0_AR_sender][AR_id[M0_AR_sender]] = 1;
                ID_fifo_data_in[M0_AR_sender][AR_id[M0_AR_sender]] = {AR_sel[M0_AR_sender]};

                M0_AR_next_state = M0_AR_ALLOW;
            end

            M0_AR_ALLOW: begin
                AR_grant[M0_AR_sender] = 1;

                for (y = 0; y < NUM_OUTSTANDING_TRANS; y = y + 1) begin
                    ID_fifo_write_en[M0_AR_sender][y] = 0;
                    ID_fifo_data_in[M0_AR_sender][y] = 0;
                end

                if (AR_finish[AR_sel[M0_AR_sender]]) begin
                    M0_AR_next_state = M0_AR_IDLE;
                end else begin
                    M0_AR_next_state = M0_AR_ALLOW;
                end
            end
        endcase
    end

    // read address channel arbiter master 1
    wire [$clog2(M)-1:0] M1_AR_sender = 1;
    reg [2-1:0] M1_AR_curr_state, M1_AR_next_state;

    localparam M1_AR_IDLE     = 0;
    localparam M1_AR_REGISTER = 1;
    localparam M1_AR_ALLOW    = 2;

    always @(posedge clk or negedge clr) begin
        if (!clr) begin
            M1_AR_curr_state <= M1_AR_IDLE;
        end else begin
            M1_AR_curr_state <= M1_AR_next_state;
        end
    end

    always @(*) begin
        case (M1_AR_curr_state)
            M1_AR_IDLE: begin
                AR_grant[M1_AR_sender] = 0;

                for (y = 0; y < NUM_OUTSTANDING_TRANS; y = y + 1) begin
                    ID_fifo_write_en[M1_AR_sender][y] = 0;
                    ID_fifo_data_in[M1_AR_sender][y] = 0;
                end

                if (AR_request[M1_AR_sender] &&
                    !(ID_fifo_full[M1_AR_sender][AR_id[M1_AR_sender]]) &&
                    !((M0_AR_next_state == M0_AR_REGISTER && AR_sel[M0_AR_sender] == AR_sel[M1_AR_sender]) ||
                    (M0_AR_curr_state == M0_AR_REGISTER && AR_sel[M0_AR_sender] == AR_sel[M1_AR_sender]) ||
                    (M0_AR_curr_state == M0_AR_ALLOW && AR_sel[M0_AR_sender] == AR_sel[M1_AR_sender]))) begin
                    M1_AR_next_state = M1_AR_REGISTER;
                end else begin
                    M1_AR_next_state = M1_AR_IDLE;
                end
            end

            M1_AR_REGISTER: begin
                AR_grant[M1_AR_sender] = 0;

                for (y = 0; y < NUM_OUTSTANDING_TRANS; y = y + 1) begin
                    ID_fifo_write_en[M1_AR_sender][y] = 0;
                    ID_fifo_data_in[M1_AR_sender][y] = 0;
                end

                ID_fifo_write_en[M1_AR_sender][AR_id[M1_AR_sender]] = 1;
                ID_fifo_data_in[M1_AR_sender][AR_id[M1_AR_sender]] = {AR_sel[M1_AR_sender]};

                M1_AR_next_state = M1_AR_ALLOW;
            end

            M1_AR_ALLOW: begin
                AR_grant[M1_AR_sender] = 1;

                for (y = 0; y < NUM_OUTSTANDING_TRANS; y = y + 1) begin
                    ID_fifo_write_en[M1_AR_sender][y] = 0;
                    ID_fifo_data_in[M1_AR_sender][y] = 0;
                end

                if (AR_finish[AR_sel[M1_AR_sender]]) begin
                    M1_AR_next_state = M1_AR_IDLE;
                end else begin
                    M1_AR_next_state = M1_AR_ALLOW;
                end
            end
        endcase
    end

    // read data channel arbiter slave 0
    wire [$clog2(S)-1:0] S0_R_sender = 0;
    reg [2-1:0] S0_R_curr_state, S0_R_next_state;

    localparam S0_R_IDLE     = 0;
    localparam S0_R_UNREGISTER = 1;
    localparam S0_R_ALLOW    = 2;

    always @(posedge clk or negedge clr) begin
        if (!clr) begin
            S0_R_curr_state <= S0_R_IDLE;
        end else begin
            S0_R_curr_state <= S0_R_next_state;
        end
    end

    always @(*) begin
        case (S0_R_curr_state)
            S0_R_IDLE: begin
                R_grant[S0_R_sender] = 0;

                // for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
                //     for (y = 0; y < M; y = y + 1) begin
                //         ID_fifo_read_en[x][y] = 0;
                //     end
                // end

                if (R_request[S0_R_sender] &&
                    !ID_fifo_empty[R_master_id[S0_R_sender]][R_transaction_id[S0_R_sender]] &&
                    ID_fifo_head[R_master_id[S0_R_sender]][R_transaction_id[S0_R_sender]] == S0_R_sender) begin
                    S0_R_next_state = S0_R_UNREGISTER;
                end else begin
                    S0_R_next_state = S0_R_IDLE;
                end
            end

            S0_R_UNREGISTER: begin
                R_grant[S0_R_sender] = 0;

                // for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
                //     for (y = 0; y < M; y = y + 1) begin
                //         ID_fifo_read_en[x][y] = 0;
                //     end
                // end

                // ID_fifo_read_en[R_master_id[S0_R_sender]][R_transaction_id[S0_R_sender]] = 1;

                S0_R_next_state = S0_R_ALLOW;
            end

            S0_R_ALLOW: begin
                R_grant[S0_R_sender] = 1;

                // for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
                //     for (y = 0; y < M; y = y + 1) begin
                //         ID_fifo_read_en[x][y] = 0;
                //     end
                // end

                if (R_last[S0_R_sender]) begin
                    S0_R_next_state = S0_R_IDLE;
                end else begin
                    S0_R_next_state = S0_R_ALLOW;
                end
            end
        endcase
    end

    // read data channel arbiter slave 1
    wire [$clog2(S)-1:0] S1_R_sender = 1;
    reg [2-1:0] S1_R_curr_state, S1_R_next_state;

    localparam S1_R_IDLE     = 0;
    localparam S1_R_UNREGISTER = 1;
    localparam S1_R_ALLOW    = 2;

    always @(posedge clk or negedge clr) begin
        if (!clr) begin
            S1_R_curr_state <= S1_R_IDLE;
        end else begin
            S1_R_curr_state <= S1_R_next_state;
        end
    end

    always @(*) begin
        case (S1_R_curr_state)
            S1_R_IDLE: begin
                R_grant[S1_R_sender] = 0;

                // for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
                //     for (y = 0; y < M; y = y + 1) begin
                //         ID_fifo_read_en[x][y] = 0;
                //     end
                // end

                if (R_request[S1_R_sender] &&
                    !ID_fifo_empty[R_master_id[S1_R_sender]][R_transaction_id[S1_R_sender]] &&
                    ID_fifo_head[R_master_id[S1_R_sender]][R_transaction_id[S1_R_sender]] == S1_R_sender) begin
                    S1_R_next_state = S1_R_UNREGISTER;
                end else begin
                    S1_R_next_state = S1_R_IDLE;
                end
            end

            S1_R_UNREGISTER: begin
                R_grant[S1_R_sender] = 0;

                // for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
                //     for (y = 0; y < M; y = y + 1) begin
                //         ID_fifo_read_en[x][y] = 0;
                //     end
                // end

                // ID_fifo_read_en[R_master_id[S1_R_sender]][R_transaction_id[S1_R_sender]] = 1;

                S1_R_next_state = S1_R_ALLOW;
            end

            S1_R_ALLOW: begin
                R_grant[S1_R_sender] = 1;

                // for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
                //     for (y = 0; y < M; y = y + 1) begin
                //         ID_fifo_read_en[x][y] = 0;
                //     end
                // end

                if (R_last[S1_R_sender]) begin
                    S1_R_next_state = S1_R_IDLE;
                end else begin
                    S1_R_next_state = S1_R_ALLOW;
                end
            end
        endcase
    end

    // read data channel arbiter fifo read
    always @(*) begin
        for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
            for (y = 0; y < M; y = y + 1) begin
                ID_fifo_read_en[x][y] = 0;
            end
        end

        if (S0_R_curr_state == S0_R_UNREGISTER) begin
            ID_fifo_read_en[R_master_id[S0_R_sender]][R_transaction_id[S0_R_sender]] = 1;
        end

        if (S1_R_curr_state == S1_R_UNREGISTER) begin
            ID_fifo_read_en[R_master_id[S1_R_sender]][R_transaction_id[S1_R_sender]] = 1;
        end
    end

endmodule
