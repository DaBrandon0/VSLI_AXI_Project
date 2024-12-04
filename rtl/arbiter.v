`define M 2
`define S 2

module arbiter #(
    parameter NUM_OUTSTANDING_TRANS = 4,
    parameter ID_WIDTH = 4,
    parameter ADDR_WIDTH = 32
)(
    input clk,
    input rst,

    // write address channel signals
    input M0_AWrequest,
    input [ADDR_WIDTH-1:0] M0_AWaddr,
    output reg M0_AWgrant,
    output reg [$clog2(`S)-1:0] M0_AWsel,
    
    input M1_AWrequest,
    input [ADDR_WIDTH-1:0] M1_AWaddr,
    output reg M1_AWgrant,
    output reg [$clog2(`S)-1:0] M1_AWsel,

    // write data channel signals
    input M0_Wrequest,
    input [ADDR_WIDTH-1:0] M0_Waddr,
    output reg M0_Wgrant,
    output reg [$clog2(`S)-1:0] M0_Wsel,
    
    input M1_Wrequest,
    input [ADDR_WIDTH-1:0] M1_Waddr,
    output reg M1_Wgrant,
    output reg [$clog2(`S)-1:0] M1_Wsel,

    // write response channel signals
    input M0_Brequest,
    input [ADDR_WIDTH-1:0] M0_Baddr,
    output reg M0_Bgrant,
    output reg [$clog2(`S)-1:0] M0_Bsel,
    
    input M1_Brequest,
    input [ADDR_WIDTH-1:0] M1_Baddr,
    output reg M1_Bgrant,
    output reg [$clog2(`S)-1:0] M1_Bsel,

    // read address channel signals
    input M0_ARrequest,
    input [ADDR_WIDTH-1:0] M0_ARaddr,
    output reg M0_ARgrant,
    output reg [$clog2(`S)-1:0] M0_ARsel,
    
    input M1_ARrequest,
    input [ADDR_WIDTH-1:0] M1_ARaddr,
    output reg M1_ARgrant,
    output reg [$clog2(`S)-1:0] M1_ARsel,

    // read data channel signals
    input M0_Rrequest,
    input [ADDR_WIDTH-1:0] M0_Raddr,
    output reg M0_Rgrant,
    output reg [$clog2(`S)-1:0] M0_Rsel,
    
    input M1_Rrequest,
    input [ADDR_WIDTH-1:0] M1_Raddr,
    output reg M1_Rgrant,
    output reg [$clog2(`S)-1:0] M1_Rsel
);

// // write tracker
// reg [$clog2(`M)-1:0] write_tracker_master_id [NUM_OUTSTANDING_TRANS-1:0][`M-1:0];
// reg [$clog2(`S)-1:0] write_tracker_slave_id [NUM_OUTSTANDING_TRANS-1:0][`M-1:0];
// reg [ID_WIDTH-1:0] write_tracker_transaction_id [NUM_OUTSTANDING_TRANS-1:0][`M-1:0];
// reg write_tracker_valid [NUM_OUTSTANDING_TRANS-1:0][`M-1:0];

// address decode
// wire [`S-1:0] M0_AWslave_sel;
wire [`S-1:0] M0_ARslave_sel;
// wire [`S-1:0] M1_AWslave_sel;
wire [`S-1:0] M1_ARslave_sel;

// addr_decode #(
//     .ADDR_WIDTH(ADDR_WIDTH)
// )(
//     .addr(M0_AWaddr),
//     .sel(M0_AWslave_sel)
// );

addr_decode #(
    .ADDR_WIDTH(ADDR_WIDTH)
)(
    .addr(M0_ARaddr),
    .sel(M0_ARslave_sel)
);

// addr_decode #(
//     .ADDR_WIDTH(ADDR_WIDTH)
// )(
//     .addr(M1_AWaddr),
//     .sel(M1_AWslave_sel)
// );

addr_decode #(
    .ADDR_WIDTH(ADDR_WIDTH)
)(
    .addr(M1_ARaddr),
    .sel(M1_ARslave_sel)
);

// // write tracker logic
// always @(posedge clk or negedge rst) begin
//     integer i, j;
//     if (!rst) begin
//         for (i = 0; i < NUM_OUTSTANDING_TRANS; i = i + 1) begin
//             for (j = 0; j < `M; j = i + 1) begin
//                 write_tracker_master_id[i][j] <= 0;
//                 write_tracker_slave_id[i][j] <= 0;
//                 write_tracker_transaction_id[i][j] <= 0;
//                 write_tracker_valid[i][j] <= 0;
//             end
//         end
//     end else begin

//     end
// end

// read address channel arbiter
reg [$clog2(`M)-1:0] ARsender;
reg ARsending;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        M0_ARgrant <= 0;
        M0_ARsel <= 0;
        M1_ARgrant <= 0;
        M1_ARsel <= 0;

        ARsender <= 0;
        ARsending <= 0;
    end else begin
        if (!ARsending) begin
            case (ARsender):
                0: begin
                    if (M0_ARrequest) begin
                        ARsending <= 1;
                        M0_ARgrant <= 1;
                        M0_ARsel <= M0_ARslave_sel;
                    end else begin
                        ARsender <= (ARsender + 1) % `M;
                    end
                end

                1: begin
                    if (M1_ARrequest) begin
                        ARsending <= 1;
                        M1_ARgrant <= 1;
                        M1_ARsel <= M1_ARslave_sel;
                    end else begin
                        ARsender <= (ARsender + 1) % `M;
                    end
                end
            endcase
        end else begin
            case (ARsender):
                0: begin
                    if (!M0_ARrequest) begin
                        ARsending <= 0;
                        M0_ARgrant <= 0;
                        ARsender <= (ARsender + 1) % `M;
                    end
                end

                1: begin
                    if (!M1_ARrequest) begin
                        ARsending <= 0;
                        M1_ARgrant <= 0;
                        ARsender <= (ARsender + 1) % `M;
                    end
                end
            endcase
        end
    end
end

endmodule