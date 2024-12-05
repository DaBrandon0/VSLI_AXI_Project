`timescale 1ns/1ps

module tb_interconnect2x2;

    // Parameters
    localparam BUS_WIDTH = 32;
    localparam ID_WIDTH = 4;
    localparam ADDR_WIDTH = 32;

    // Testbench signals
    reg [ID_WIDTH-1:0] M0_AWID, M0_ARID;
    reg [ADDR_WIDTH-1:0] M0_AWADDR, M0_ARADDR;
    reg [BUS_WIDTH-1:0] M0_WDATA;
    reg M0_AWVALID, M0_ARVALID, M0_WVALID;
    wire M0_AWREADY, M0_ARREADY, M0_WREADY;
    wire [ADDR_WIDTH-1:0] S0_AWADDR, S0_ARADDR;
    wire [BUS_WIDTH-1:0] S0_WDATA;
    wire S0_AWVALID, S0_ARVALID, S0_WVALID;
    reg S0_AWREADY, S0_ARREADY, S0_WREADY;

    reg M0_write_addr_en, M0_write_data_en, M0_read_addr_en;
    reg [$clog2(2)-1:0] M0_write_addr_sel, M0_write_data_sel, M0_read_addr_sel;
    reg S0_write_resp_en, S0_read_data_en;
    reg [$clog2(2)-1:0] S0_write_resp_sel, S0_read_data_sel;

    // Instantiate the DUT
    interconnect2x2 #(
        .BUS_WIDTH(BUS_WIDTH),
        .ID_WIDTH(ID_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .M0_AWID(M0_AWID),
        .M0_AWADDR(M0_AWADDR),
        .M0_AWVALID(M0_AWVALID),
        .M0_AWREADY(M0_AWREADY),
        .M0_WDATA(M0_WDATA),
        .M0_WVALID(M0_WVALID),
        .M0_WREADY(M0_WREADY),
        .M0_ARID(M0_ARID),
        .M0_ARADDR(M0_ARADDR),
        .M0_ARVALID(M0_ARVALID),
        .M0_ARREADY(M0_ARREADY),
        .S0_AWADDR(S0_AWADDR),
        .S0_AWVALID(S0_AWVALID),
        .S0_AWREADY(S0_AWREADY),
        .S0_WDATA(S0_WDATA),
        .S0_WVALID(S0_WVALID),
        .S0_WREADY(S0_WREADY),
        .S0_ARADDR(S0_ARADDR),
        .S0_ARVALID(S0_ARVALID),
        .S0_ARREADY(S0_ARREADY),
        .M0_write_addr_sel(M0_write_addr_sel),
        .M0_write_addr_en(M0_write_addr_en),
        .M0_write_data_sel(M0_write_data_sel),
        .M0_write_data_en(M0_write_data_en),
        .M0_read_addr_sel(M0_read_addr_sel),
        .M0_read_addr_en(M0_read_addr_en),
        .S0_write_resp_sel(S0_write_resp_sel),
        .S0_write_resp_en(S0_write_resp_en),
        .S0_read_data_sel(S0_read_data_sel),
        .S0_read_data_en(S0_read_data_en)
    );

    // Test sequence
    initial begin
        // Initialize signals
        M0_AWID = 0; M0_AWADDR = 0; M0_AWVALID = 0;
        M0_WDATA = 0; M0_WVALID = 0;
        M0_ARID = 0; M0_ARADDR = 0; M0_ARVALID = 0;
        S0_AWREADY = 1; S0_WREADY = 1; S0_ARREADY = 1;

        M0_write_addr_en = 0; M0_write_addr_sel = 0;
        M0_write_data_en = 0; M0_write_data_sel = 0;
        M0_read_addr_en = 0; M0_read_addr_sel = 0;
        S0_write_resp_en = 0; S0_write_resp_sel = 0;
        S0_read_data_en = 0; S0_read_data_sel = 0;

        #10;
        
        // Test write address and data to S0
        M0_write_addr_en = 1; M0_write_addr_sel = 0;
        M0_write_data_en = 1; M0_write_data_sel = 0;
        M0_AWADDR = 32'hAABBCCDD; // Set a test address
        M0_AWVALID = 1;           // Assert write address valid
        M0_WDATA = 32'h12345678;  // Set test write data
        M0_WVALID = 1;            // Assert write data valid

        #10;
        M0_AWVALID = 0;           // Deassert write address valid
        M0_WVALID = 0;            // Deassert write data valid

        #10;

        // Test read address to S0
        M0_read_addr_en = 1; M0_read_addr_sel = 0;
        M0_ARADDR = 32'hDEADBEEF; // Set a test read address
        M0_ARVALID = 1;           // Assert read address valid

        #10;
        M0_ARVALID = 0;           // Deassert read address valid

        #50;
        
        // End simulation
        $finish;
    end

endmodule
