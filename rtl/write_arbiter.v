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
    input [(M*($clog2(NUM_OUTSTANDING_TRANS)))-1:0] W_id_f,
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
    wire [($clog2(NUM_OUTSTANDING_TRANS))-1:0] AW_id [M-1:0];
    reg [1-1:0] AW_grant [M-1:0];
    wire [$clog2(S)-1:0] AW_sel [M-1:0];

    wire [(M*1)-1:0] B_ready [M-1:0];
    wire [($clog2(NUM_OUTSTANDING_TRANS))-1:0] W_id [M-1:0];
    wire [(S*1)-1:0] B_valid [S-1:0];
    reg [(M*1)-1:0] W_grant [M-1:0];
    reg [(S*1)-1:0] B_grant [S-1:0];
    reg [(M*$clog2(S))-1:0] W_sel [M-1:0];
    reg [(S*$clog2(M))-1:0] B_sel [S-1:0];

    generate
        for (i = 0; i < M; i = i + 1) begin : UNFLATTEN_M
            assign AW_valid[i] = AW_valid_f[i];
            assign AW_addr[i] = AW_addr_f[(i+1)*ADDR_WIDTH-1:i*ADDR_WIDTH];
            assign AW_id[i] = AW_id_f[(i+1)*$clog2(NUM_OUTSTANDING_TRANS)-1:i*$clog2(NUM_OUTSTANDING_TRANS)];
            assign AW_grant_f[i] = AW_grant[i];
            assign AW_sel_f[(i+1)*$clog2(S)-1:i*$clog2(S)] = AW_sel[i];

            assign B_ready[i] = B_ready_f[i];
            assign W_id[i] = W_id_f[(i+1)*$clog2(NUM_OUTSTANDING_TRANS)-1:i*$clog2(NUM_OUTSTANDING_TRANS)];
            assign W_grant_f[i] = W_grant[i];
            assign W_sel_f[(i+1)*$clog2(S)-1:i*$clog2(S)] = W_sel[i];
        end
        for (i = 0; i < M; i = i + 1) begin : UNFLATTEN_S
            assign B_valid[i] = B_valid_f[i];
            assign B_grant_f[i] = B_grant[i];
            assign B_sel_f[(i+1)*$clog2(M)-1:i*$clog2(M)] = B_sel[i];
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

    // write address channel arbiter
    reg [$clog2(M)-1:0] AW_sender;
    reg [2-1:0] AW_curr_state, AW_next_state;

    localparam AW_IDLE     = 0;
    localparam AW_REGISTER = 1;
    localparam AW_ALLOW    = 2;

    always @(posedge clk or negedge clr) begin
        if (!clr) begin
            AW_curr_state <= AW_IDLE;
            AW_sender <= 0;
        end else begin
            AW_curr_state <= AW_next_state;

            case (AW_curr_state)
                AW_IDLE: begin
                    if (AW_next_state == AW_IDLE) begin
                        AW_sender <= (AW_sender + 1) % M;
                    end
                end

                AW_ALLOW: begin
                    if (AW_next_state == AW_IDLE) begin
                        AW_sender <= (AW_sender + 1) % M;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        case (AW_curr_state)
            AW_IDLE: begin
                for (x = 0; x < M; x = x + 1) begin
                    AW_grant[x] = 0;
                end

                for (x = 0; x < M; x = x + 1) begin
                    for (y = 0; y < NUM_OUTSTANDING_TRANS; y = y + 1) begin
                        ID_fifo_write_en[x][y] = 0;
                        ID_fifo_data_in[x][y] = 0;
                    end
                end

                if (AW_valid[AW_sender] && !ID_fifo_full[AW_sender][AW_id[AW_sender]]) begin
                    AW_next_state = AW_REGISTER;
                end else begin
                    AW_next_state = AW_IDLE;
                end
            end

            AW_REGISTER: begin
                for (x = 0; x < M; x = x + 1) begin
                    AW_grant[x] = 0;
                end

                for (x = 0; x < M; x = x + 1) begin
                    for (y = 0; y < NUM_OUTSTANDING_TRANS; y = y + 1) begin
                        ID_fifo_write_en[x][y] = 0;
                        ID_fifo_data_in[x][y] = 0;
                    end
                end

                ID_fifo_write_en[AW_sender][AW_id[AW_sender]] = 1;
                ID_fifo_data_in[AW_sender][AW_id[AW_sender]] = {AW_sel[AW_sender]};

                AW_next_state = AW_ALLOW;
            end

            AW_ALLOW: begin
                for (x = 0; x < M; x = x + 1) begin
                    AW_grant[x] = 0;
                end

                AW_grant[AW_sender] = 1;

                for (x = 0; x < M; x = x + 1) begin
                    for (y = 0; y < NUM_OUTSTANDING_TRANS; y = y + 1) begin
                        ID_fifo_write_en[x][y] = 0;
                        ID_fifo_data_in[x][y] = 0;
                    end
                end

                if (!AW_valid[AW_sender]) begin
                    AW_next_state = AW_IDLE;
                end else begin
                    AW_next_state = AW_ALLOW;
                end
            end
        endcase
    end

    // write data/response channel arbiter
    reg [$clog2(M)-1:0] W_sender;
    reg [$clog2(S)-1:0] W_receiver;
    reg [2-1:0] W_curr_state, W_next_state;

    localparam W_IDLE       = 0;
    localparam W_UNREGISTER = 1;
    localparam W_ALLOW    = 2;

    always @(posedge clk or negedge clr) begin
        if (!clr) begin
            W_curr_state <= W_IDLE;
            W_sender <= 0;
            W_receiver <= 0;
        end else begin
            W_curr_state <= W_next_state;

            case (W_curr_state)
                W_IDLE: begin
                    if (W_next_state == W_IDLE) begin
                        W_sender <= (W_sender + 1) % M;
                    end
                end

                W_UNREGISTER: begin
                    W_receiver <= ID_fifo_head[W_sender][W_id[W_sender]];
                end

                W_ALLOW: begin
                    if (W_next_state == W_IDLE) begin
                        W_sender <= (W_sender + 1) % M;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        case (W_curr_state)
            W_IDLE: begin
                for (x = 0; x < M; x = x + 1) begin
                    W_grant[x] = 0;
                    W_sel[x] = 0;
                end

                for (x = 0; x < S; x = x + 1) begin
                    B_grant[x] = 0;
                    B_sel[x] = 0;
                end


                for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
                    for (y = 0; y < M; y = y + 1) begin
                        ID_fifo_read_en[x][y] = 0;
                    end
                end

                if (B_ready[W_sender] &&
                    !ID_fifo_empty[W_sender][W_id[W_sender]] &&
                    ID_fifo_head[W_sender][W_id[W_sender]] == W_sender) begin
                    W_next_state = W_UNREGISTER;
                end else begin
                    W_next_state = W_IDLE;
                end
            end

            W_UNREGISTER: begin
                for (x = 0; x < M; x = x + 1) begin
                    W_grant[x] = 0;
                    W_sel[x] = 0;
                end

                for (x = 0; x < S; x = x + 1) begin
                    B_grant[x] = 0;
                    B_sel[x] = 0;
                end


                for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
                    for (y = 0; y < M; y = y + 1) begin
                        ID_fifo_read_en[x][y] = 0;
                    end
                end

                ID_fifo_read_en[W_sender][W_id[W_sender]] = 1;

                W_next_state = W_ALLOW;
            end

            W_ALLOW: begin
                for (x = 0; x < M; x = x + 1) begin
                    W_grant[x] = 0;
                    W_sel[x] = 0;
                end

                for (x = 0; x < S; x = x + 1) begin
                    B_grant[x] = 0;
                    B_sel[x] = 0;
                end

                W_grant[W_sender] = 1;
                B_grant[W_receiver] = 1;

                W_sel[W_sender] = W_receiver;
                B_sel[W_receiver] = W_sender;

                for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
                    for (y = 0; y < M; y = y + 1) begin
                        ID_fifo_read_en[x][y] = 0;
                    end
                end

                if (B_valid[W_sender]) begin
                    W_next_state = W_IDLE;
                end else begin
                    W_next_state = W_ALLOW;
                end
            end
        endcase
    end

endmodule
