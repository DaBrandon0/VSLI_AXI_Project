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
    input [(M*1)-1:0] AW_request_f,
    input [(M*ADDR_WIDTH)-1:0] AW_addr_f,
    input [(M*$clog2(NUM_OUTSTANDING_TRANS))-1:0] AW_id_f,
    output [(M*1)-1:0] AW_grant_f,
    output [(M*$clog2(S))-1:0] AW_sel_f,

    // read data channel signals
    input [(M*1)-1:0] AW_request_f,
    input [(M*ADDR_WIDTH)-1:0] AW_addr_f,
    input [(M*($clog2(M)+$clog2(NUM_OUTSTANDING_TRANS)))-1:0] AW_id_f,
    input [(M*1)-1:0] AW_last_f,
    output [(M*1)-1:0] AW_grant_f,
    output [(M*$clog2(S))-1:0] AW_sel_f
);
    genvar i, j;
    integer x, y;

    // unflatten signals
    wire [1-1:0] AW_request [M-1:0];
    wire [ADDR_WIDTH-1:0] AW_addr [M-1:0];
    wire [($clog2(NUM_OUTSTANDING_TRANS))-1:0] AW_id [M-1:0];
    reg [1-1:0] AW_grant [M-1:0];
    wire [$clog2(S)-1:0] AW_sel [M-1:0];

    wire [1-1:0] AW_request [M-1:0];
    wire [ADDR_WIDTH-1:0] AW_addr [M-1:0];
    wire [$clog2(M)-1:0] AW_master_id [M-1:0];
    wire [$clog2(NUM_OUTSTANDING_TRANS)-1:0] AW_transaction_id [M-1:0];
    wire [1-1:0] AW_last [M-1:0];
    reg [1-1:0] AW_grant [M-1:0];
    wire [$clog2(S)-1:0] AW_sel [M-1:0];

    generate
        for (i = 0; i < M; i = i + 1) begin : UNFLATTEN
            assign AW_request[i] = AW_request_f[i];
            assign AW_addr[i] = AW_addr_f[(i+1)*ADDR_WIDTH-1:i*ADDR_WIDTH];
            assign AW_id[i] = AW_id_f[(i+1)*$clog2(NUM_OUTSTANDING_TRANS)-1:i*$clog2(NUM_OUTSTANDING_TRANS)];
            assign AW_grant_f[i] = AW_grant[i];
            assign AW_sel_f[(i+1)*$clog2(S)-1:i*$clog2(S)] = AW_sel[i];

            assign AW_request[i] = AW_request_f[i];
            assign AW_addr[i] = AW_addr_f[(i+1)*ADDR_WIDTH-1:i*ADDR_WIDTH];
            assign AW_master_id[i] = AW_id_f[(i+1)*($clog2(M) + $clog2(NUM_OUTSTANDING_TRANS)) - 1 :
                                            (i+1)*$clog2(NUM_OUTSTANDING_TRANS)];
            assign AW_transaction_id[i] = AW_id_f[(i+1)*$clog2(NUM_OUTSTANDING_TRANS) - 1 :
                                                i*$clog2(NUM_OUTSTANDING_TRANS)];
            assign AW_last[i] = AW_last_f[i];
            assign AW_grant_f[i] = AW_grant[i];
            assign AW_sel_f[(i+1)*$clog2(S)-1:i*$clog2(S)] = AW_sel[i];
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
                fifo #(
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
                    if (!(AW_request[AW_sender] && !ID_fifo_full[AW_sender][AW_id[AW_sender]])) begin
                        AW_sender <= (AW_sender + 1) % M;
                    end
                end

                AW_ALLOW: begin
                    if (!(AW_request[AW_sender])) begin
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

                if (AW_request[AW_sender] && !ID_fifo_full[AW_sender][AW_id[AW_sender]]) begin
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

                if (!AW_request[AW_sender]) begin
                    AW_next_state = AW_IDLE;
                end else begin
                    AW_next_state = AW_ALLOW;
                end
            end
        endcase
    end

    // read data channel arbiter
    reg [$clog2(S)-1:0] AW_sender;
    reg [2-1:0] AW_curr_state, AW_next_state;

    localparam AW_IDLE     = 0;
    localparam AW_UNREGISTER = 1;
    localparam AW_ALLOW    = 2;

    always @(posedge clk or negedge clr) begin
        if (!clr) begin
            AW_curr_state <= AW_IDLE;
            AW_sender <= 0;
        end else begin
            AW_curr_state <= AW_next_state;

            case (AW_curr_state)
                AW_IDLE: begin
                    if (!(AW_request[AW_sender] &&
                        !ID_fifo_empty[AW_master_id[AW_sender]][AW_transaction_id[AW_sender]] &&
                        ID_fifo_head[AW_master_id[AW_sender]][AW_transaction_id[AW_sender]] == AW_sender)) begin
                        AW_sender <= (AW_sender + 1) % S;
                    end
                end

                AW_ALLOW: begin
                    if (AW_last[AW_sender]) begin
                        AW_sender <= (AW_sender + 1) % S;
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

                for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
                    for (y = 0; y < M; y = y + 1) begin
                        ID_fifo_read_en[x][y] = 0;
                    end
                end

                if (AW_request[AW_sender] &&
                    !ID_fifo_empty[AW_master_id[AW_sender]][AW_transaction_id[AW_sender]] &&
                    ID_fifo_head[AW_master_id[AW_sender]][AW_transaction_id[AW_sender]] == AW_sender) begin
                    AW_next_state = AW_UNREGISTER;
                end else begin
                    AW_next_state = AW_IDLE;
                end
            end

            AW_UNREGISTER: begin
                for (x = 0; x < M; x = x + 1) begin
                    AW_grant[x] = 0;
                end

                for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
                    for (y = 0; y < M; y = y + 1) begin
                        ID_fifo_read_en[x][y] = 0;
                    end
                end

                ID_fifo_read_en[AW_master_id[AW_sender]][AW_transaction_id[AW_sender]] = 1;

                AW_next_state = AW_ALLOW;
            end

            AW_ALLOW: begin
                for (x = 0; x < M; x = x + 1) begin
                    AW_grant[x] = 0;
                end

                AW_grant[AW_sender] = 1;

                for (x = 0; x < NUM_OUTSTANDING_TRANS; x = x + 1) begin
                    for (y = 0; y < M; y = y + 1) begin
                        ID_fifo_read_en[x][y] = 0;
                    end
                end

                if (AW_last[AW_sender]) begin
                    AW_next_state = AW_IDLE;
                end else begin
                    AW_next_state = AW_ALLOW;
                end
            end
        endcase
    end

endmodule
