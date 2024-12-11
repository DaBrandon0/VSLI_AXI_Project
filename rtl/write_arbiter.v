`timescale 1ns/1ps

module write_arbiter #(
    parameter M = 2,
    parameter S = 2,
    parameter NUM_OUTSTANDING_TRANS = 2,
    parameter ADDR_WIDTH = 32
)(
    input clk,
    input clr,

    // write address channel signals
    input [(M*1)-1:0] AW_valid_f,
    input [(M*ADDR_WIDTH)-1:0] AW_addr_f,
    input [(M*$clog2(NUM_OUTSTANDING_TRANS))-1:0] AW_id_f,
    output [(M*1)-1:0] AW_grant_f,
    output [(M*$clog2(S))-1:0] AW_sel_f,

    // write data/response channel signals
    input [(M*1)-1:0] B_ready_f,
    input [(M*($clog2(M)+$clog2(NUM_OUTSTANDING_TRANS)))-1:0] W_id_f,
    input [(S*1)-1:0] B_valid_f,
    output [(M*1)-1:0] W_grant_f,
    output [(S*1)-1:0] B_grant_f,
    output [(M*$clog2(S))-1:0] W_sel_f,
    output [(S*$clog2(M))-1:0] B_sel_f
);
    genvar i, j;
    integer x, y;

    // unflatten signals
    wire [1-1:0] AW_valid [M-1:0];
    wire [ADDR_WIDTH-1:0] AW_addr [M-1:0];
    wire [($clog2(M)+$clog2(NUM_OUTSTANDING_TRANS))-1:0] AW_id [M-1:0];
    reg [1-1:0] AW_grant [M-1:0];
    wire [$clog2(S)-1:0] AW_sel [M-1:0];

    wire [1-1:0] B_ready [M-1:0];
    wire [($clog2(NUM_OUTSTANDING_TRANS))-1:0] W_id [M-1:0];
    wire [1-1:0] B_valid [S-1:0];
    reg [1-1:0] W_grant [M-1:0];
    reg [1-1:0] B_grant [S-1:0];
    reg [$clog2(S)-1:0] W_sel [M-1:0];
    reg [$clog2(M)-1:0] B_sel [S-1:0];

    generate
        for (i = 0; i < M; i = i + 1) begin : UNFLATTEN_M
            assign AW_valid[i] = AW_valid_f[i];
            assign AW_addr[i] = AW_addr_f[(i+1)*ADDR_WIDTH-1:i*ADDR_WIDTH];
            assign AW_id[i] = AW_id_f[(i+1)*$clog2(NUM_OUTSTANDING_TRANS)-1:i*$clog2(NUM_OUTSTANDING_TRANS)];
            assign AW_grant_f[i] = AW_grant[i];
            assign AW_sel_f[(i+1)*$clog2(S)-1:i*$clog2(S)] = AW_sel[i];

            assign B_ready[i] = B_ready_f[i];
            assign W_grant_f[i] = W_grant[i];
            assign W_sel_f[(i+1)*$clog2(S)-1:i*$clog2(S)] = W_sel[i];
        end
        for (i = 0; i < S; i = i + 1) begin : UNFLATTEN_S
            assign B_valid[i] = B_valid_f[i];
            assign B_grant_f[i] = B_grant[i];
            assign B_sel_f[(i+1)*$clog2(M)-1:i*$clog2(M)] = B_sel[i];
        end
    endgenerate
    assign W_id[0] = W_id_f[1:0];
    assign W_id[1] = W_id_f[3:2];

    // address decode
    generate
        for (i = 0; i < M; i = i + 1) begin : addr_decode_gen
            addr_decode #(
                .ADDR_WIDTH(ADDR_WIDTH),
                .S(S),
                .SLICE_SIZE(32'h00000080)
            ) addr_decode (
                .addr(AW_addr[i]),
                .sel(AW_sel[i])
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

    // write address channel arbiter 0
    wire [$clog2(M)-1:0] M0_AW_sender = 0;
    reg [2-1:0] M0_AW_curr_state, M0_AW_next_state;

    localparam M0_AW_IDLE     = 0;
    localparam M0_AW_REGISTER = 1;
    localparam M0_AW_ALLOW    = 2;

    always @(posedge clk or negedge clr) begin
        if (!clr) begin
            M0_AW_curr_state <= M0_AW_IDLE;
        end else begin
            M0_AW_curr_state <= M0_AW_next_state;
        end
    end

    always @(*) begin
        case (M0_AW_curr_state)
            M0_AW_IDLE: begin
                AW_grant[M0_AW_sender] = 0;

                for (y = 0; y < NUM_OUTSTANDING_TRANS; y = y + 1) begin
                    ID_fifo_write_en[M0_AW_sender][y] = 0;
                    ID_fifo_data_in[M0_AW_sender][y] = 0;
                end

                if (AW_valid[M0_AW_sender] && !ID_fifo_full[M0_AW_sender][AW_id[M0_AW_sender]]) begin
                    M0_AW_next_state = M0_AW_REGISTER;
                end else begin
                    M0_AW_next_state = M0_AW_IDLE;
                end
            end

            M0_AW_REGISTER: begin
                AW_grant[M0_AW_sender] = 0;

                for (y = 0; y < NUM_OUTSTANDING_TRANS; y = y + 1) begin
                    ID_fifo_write_en[M0_AW_sender][y] = 0;
                    ID_fifo_data_in[M0_AW_sender][y] = 0;
                end

                ID_fifo_write_en[M0_AW_sender][AW_id[M0_AW_sender]] = 1;
                ID_fifo_data_in[M0_AW_sender][AW_id[M0_AW_sender]] = {AW_sel[M0_AW_sender]};

                M0_AW_next_state = M0_AW_ALLOW;
            end

            M0_AW_ALLOW: begin
                AW_grant[M0_AW_sender] = 1;

                for (y = 0; y < NUM_OUTSTANDING_TRANS; y = y + 1) begin
                    ID_fifo_write_en[M0_AW_sender][y] = 0;
                    ID_fifo_data_in[M0_AW_sender][y] = 0;
                end

                if (!AW_valid[M0_AW_sender]) begin
                    M0_AW_next_state = M0_AW_IDLE;
                end else begin
                    M0_AW_next_state = M0_AW_ALLOW;
                end
            end
        endcase
    end

    // write address channel arbiter 1
    wire [$clog2(M)-1:0] M1_AW_sender = 1;
    reg [2-1:0] M1_AW_curr_state, M1_AW_next_state;

    localparam M1_AW_IDLE     = 0;
    localparam M1_AW_REGISTER = 1;
    localparam M1_AW_ALLOW    = 2;

    always @(posedge clk or negedge clr) begin
        if (!clr) begin
            M1_AW_curr_state <= M1_AW_IDLE;
        end else begin
            M1_AW_curr_state <= M1_AW_next_state;
        end
    end

    always @(*) begin
        case (M1_AW_curr_state)
            M1_AW_IDLE: begin
                AW_grant[M1_AW_sender] = 0;

                for (y = 0; y < NUM_OUTSTANDING_TRANS; y = y + 1) begin
                    ID_fifo_write_en[M1_AW_sender][y] = 0;
                    ID_fifo_data_in[M1_AW_sender][y] = 0;
                end

                if (AW_valid[M1_AW_sender] && !ID_fifo_full[M1_AW_sender][AW_id[M1_AW_sender]] &&
                    !((M0_AW_next_state == M0_AW_REGISTER && AW_sel[M0_AW_sender] == AW_sel[M1_AW_sender]) ||
                    (M0_AW_curr_state == M0_AW_REGISTER && AW_sel[M0_AW_sender] == AW_sel[M1_AW_sender]) ||
                    (M0_AW_curr_state == M0_AW_ALLOW && AW_sel[M0_AW_sender] == AW_sel[M1_AW_sender]))) begin
                    M1_AW_next_state = M1_AW_REGISTER;
                end else begin
                    M1_AW_next_state = M1_AW_IDLE;
                end
            end

            M1_AW_REGISTER: begin
                AW_grant[M1_AW_sender] = 0;

                for (y = 0; y < NUM_OUTSTANDING_TRANS; y = y + 1) begin
                    ID_fifo_write_en[M1_AW_sender][y] = 0;
                    ID_fifo_data_in[M1_AW_sender][y] = 0;
                end

                ID_fifo_write_en[M1_AW_sender][AW_id[M1_AW_sender]] = 1;
                ID_fifo_data_in[M1_AW_sender][AW_id[M1_AW_sender]] = {AW_sel[M1_AW_sender]};

                M1_AW_next_state = M1_AW_ALLOW;
            end

            M1_AW_ALLOW: begin
                AW_grant[M1_AW_sender] = 1;

                for (y = 0; y < NUM_OUTSTANDING_TRANS; y = y + 1) begin
                    ID_fifo_write_en[M1_AW_sender][y] = 0;
                    ID_fifo_data_in[M1_AW_sender][y] = 0;
                end

                if (!AW_valid[M1_AW_sender]) begin
                    M1_AW_next_state = M1_AW_IDLE;
                end else begin
                    M1_AW_next_state = M1_AW_ALLOW;
                end
            end
        endcase
    end

    // write data/response channel arbiter slave 0
    wire [$clog2(M)-1:0] M0_W_sender = 0;
    reg [$clog2(S)-1:0] M0_W_receiver;
    reg [2-1:0] M0_W_curr_state, M0_W_next_state;

    localparam M0_W_IDLE       = 0;
    localparam M0_W_UNREGISTER = 1;
    localparam M0_W_ALLOW    = 2;

    always @(posedge clk or negedge clr) begin
        if (!clr) begin
            M0_W_curr_state <= M0_W_IDLE;
            M0_W_receiver <= 0;
        end else begin
            M0_W_curr_state <= M0_W_next_state;

            case (M0_W_curr_state)
                M0_W_UNREGISTER: begin
                    M0_W_receiver <= ID_fifo_head[M0_W_sender][W_id[M0_W_sender]];
                end
            endcase
        end
    end

    always @(*) begin
        case (M0_W_curr_state)
            M0_W_IDLE: begin
                W_grant[M0_W_sender] = 0;
                W_sel[M0_W_sender] = 0;

                // for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
                //     for (y = 0; y < M; y = y + 1) begin
                //         ID_fifo_read_en[x][y] = 0;
                //     end
                // end

                if (B_ready[M0_W_sender] &&
                    !ID_fifo_empty[M0_W_sender][W_id[M0_W_sender]]) begin
                    M0_W_next_state = M0_W_UNREGISTER;
                end else begin
                    M0_W_next_state = M0_W_IDLE;
                end
            end

            M0_W_UNREGISTER: begin
                W_grant[M0_W_sender] = 0;
                W_sel[M0_W_sender] = 0;

                // for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
                //     for (y = 0; y < M; y = y + 1) begin
                //         ID_fifo_read_en[x][y] = 0;
                //     end
                // end

                // ID_fifo_read_en[M0_W_sender][W_id[M0_W_sender]] = 1;

                M0_W_next_state = M0_W_ALLOW;
            end

            M0_W_ALLOW: begin
                W_grant[M0_W_sender] = 1;
                

                W_sel[M0_W_sender] = M0_W_receiver;
                

                // for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
                //     for (y = 0; y < M; y = y + 1) begin
                //         ID_fifo_read_en[x][y] = 0;
                //     end
                // end

                if (B_valid[M0_W_sender]) begin
                    M0_W_next_state = M0_W_IDLE;
                end else begin
                    M0_W_next_state = M0_W_ALLOW;
                end
            end
        endcase
    end

    // write data/response channel arbiter slave 1
    wire [$clog2(M)-1:0] M1_W_sender = 1;
    reg [$clog2(S)-1:0] M1_W_receiver;
    reg [2-1:0] M1_W_curr_state, M1_W_next_state;

    localparam M1_W_IDLE       = 0;
    localparam M1_W_UNREGISTER = 1;
    localparam M1_W_ALLOW    = 2;

    always @(posedge clk or negedge clr) begin
        if (!clr) begin
            M1_W_curr_state <= M1_W_IDLE;
            M1_W_receiver <= 0;
        end else begin
            M1_W_curr_state <= M1_W_next_state;

            case (M1_W_curr_state)
                M1_W_UNREGISTER: begin
                    M1_W_receiver <= ID_fifo_head[M1_W_sender][W_id[M1_W_sender]];
                end
            endcase
        end
    end

    always @(*) begin
        case (M1_W_curr_state)
            M1_W_IDLE: begin
                W_grant[M1_W_sender] = 0;
                W_sel[M1_W_sender] = 0;

                // for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
                //     for (y = 0; y < M; y = y + 1) begin
                //         ID_fifo_read_en[x][y] = 0;
                //     end
                // end

                if (B_ready[M1_W_sender] &&
                    !ID_fifo_empty[M1_W_sender][W_id[M1_W_sender]]) begin
                    M1_W_next_state = M1_W_UNREGISTER;
                end else begin
                    M1_W_next_state = M1_W_IDLE;
                end
            end

            M1_W_UNREGISTER: begin
                W_grant[M1_W_sender] = 0;
                W_sel[M1_W_sender] = 0;

                // for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
                //     for (y = 0; y < M; y = y + 1) begin
                //         ID_fifo_read_en[x][y] = 0;
                //     end
                // end

                // ID_fifo_read_en[M1_W_sender][W_id[M1_W_sender]] = 1;

                M1_W_next_state = M1_W_ALLOW;
            end

            M1_W_ALLOW: begin
                W_grant[M1_W_sender] = 1;
                

                W_sel[M1_W_sender] = M1_W_receiver;
                

                // for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
                //     for (y = 0; y < M; y = y + 1) begin
                //         ID_fifo_read_en[x][y] = 0;
                //     end
                // end

                if (B_valid[M1_W_sender]) begin
                    M1_W_next_state = M1_W_IDLE;
                end else begin
                    M1_W_next_state = M1_W_ALLOW;
                end
            end
        endcase
    end

    // write data/response channel arbiter fifo read
    always @(*) begin
        for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
            for (y = 0; y < M; y = y + 1) begin
                ID_fifo_read_en[x][y] = 0;
            end
        end

        if (M0_W_curr_state == M0_W_ALLOW) begin
            ID_fifo_read_en[M0_W_sender][W_id[M0_W_sender]] = 1;
        end

        if (M1_W_curr_state == M1_W_ALLOW) begin
            ID_fifo_read_en[M1_W_sender][W_id[M1_W_sender]] = 1;
        end
    end

    // write data/response channel arbiter B grant/sel
    always @(*) begin
        for (x = 0; x < S; x = x + 1) begin
            B_grant[x] = 0;
            B_sel[x] = 0;
        end

        if (M0_W_curr_state == M0_W_UNREGISTER) begin
            B_grant[M0_W_receiver] = 1;
            B_sel[M0_W_receiver] = M0_W_sender;
        end

        if (M1_W_curr_state == M1_W_UNREGISTER) begin
            B_grant[M1_W_receiver] = 1;
            B_sel[M1_W_receiver] = M1_W_sender;
        end        
    end

endmodule
