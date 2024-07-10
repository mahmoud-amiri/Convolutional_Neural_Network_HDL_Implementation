`timescale 1 ns / 1 ps

module testbench_relu;

    // Parameters
    parameter SUB_ELEMENT_WIDTH = 8;
    parameter NUM_SUB_ELEMENTS = 4;
    parameter NUM_PLATES = 3;
    parameter C_AXIS_FIFO_DEPTH = 16;
    parameter C_AXIS_TDATA_WIDTH = SUB_ELEMENT_WIDTH * NUM_SUB_ELEMENTS * NUM_PLATES;

    // Clock and reset
    reg clk;
    reg resetn;

    // Signals for read_image_file_axis
    wire s_axis_tvalid;
    wire [C_AXIS_TDATA_WIDTH-1:0] s_axis_tdata;
    wire s_axis_tlast;
    wire s_axis_tuser;
    wire s_axis_tready;

    // Signals for DUT (relu_axis)
    wire s00_axis_tready;
    wire [C_AXIS_TDATA_WIDTH-1:0] s00_axis_tdata;
    wire [(C_AXIS_TDATA_WIDTH/8)-1:0] s00_axis_tstrb;
    wire s00_axis_tlast;
    wire s00_axis_tvalid;
    wire s00_axis_tuser;
    wire m00_axis_tvalid;
    wire [C_AXIS_TDATA_WIDTH-1:0] m00_axis_tdata;
    wire [(C_AXIS_TDATA_WIDTH/8)-1:0] m00_axis_tstrb;
    wire m00_axis_tlast;
    wire m00_axis_tuser;
    wire m00_axis_tready;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // Reset generation
    initial begin
        resetn = 0;
        #20 resetn = 1;
    end

    // Instantiate the read_image_file_axis module
    read_image_file_axis #(
        .C_S_AXIS_TDATA_WIDTH(C_AXIS_TDATA_WIDTH),
        .FILENAME("image_with_header.txt")
    ) read_image_file (
        .clk(clk),
        .reset_n(resetn),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tlast(s_axis_tlast),
        .s_axis_tuser(s_axis_tuser),
        .s_axis_tready(s_axis_tready)
    );

    // Instantiate the DUT (relu_axis)
    relu_axis #(
        .C_AXIS_FIFO_DEPTH(C_AXIS_FIFO_DEPTH),
        .SUB_ELEMENT_WIDTH(SUB_ELEMENT_WIDTH),
        .NUM_SUB_ELEMENTS(NUM_SUB_ELEMENTS),
        .NUM_PLATES(NUM_PLATES)
    ) dut (
        .clk(clk),
        .resetn(resetn),
        .s00_axis_tready(s00_axis_tready),
        .s00_axis_tdata(s_axis_tdata),
        .s00_axis_tstrb({(C_AXIS_TDATA_WIDTH/8){1'b1}}), // Assuming full byte enable
        .s00_axis_tlast(s_axis_tlast),
        .s00_axis_tvalid(s_axis_tvalid),
        .s00_axis_tuser(s_axis_tuser),
        .m00_axis_tvalid(m00_axis_tvalid),
        .m00_axis_tdata(m00_axis_tdata),
        .m00_axis_tstrb(m00_axis_tstrb),
        .m00_axis_tlast(m00_axis_tlast),
        .m00_axis_tuser(m00_axis_tuser),
        .m00_axis_tready(1'b1) // Always ready to accept data
    );

    // Monitor output from DUT
    initial begin
        $monitor("Time: %0t, m00_axis_tvalid: %0b, m00_axis_tdata: %0h, m00_axis_tlast: %0b, m00_axis_tuser: %0b", 
            $time, m00_axis_tvalid, m00_axis_tdata, m00_axis_tlast, m00_axis_tuser);
    end

    // Simulation duration
    initial begin
        #2000 $finish;
    end

endmodule
