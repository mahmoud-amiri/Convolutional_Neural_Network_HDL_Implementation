`timescale 1 ns / 1 ps

module testbench_zero_padding;

    // Parameters
    parameter C_S_AXIS_TDATA_WIDTH = 24;
    parameter C_AXIS_TDATA_WIDTH = 24;
    parameter C_AXIS_FIFO_DEPTH = 16;

    // Clock and reset
    reg clk;
    reg resetn;

    // Signals for read_image_file_axis
    wire s_axis_tvalid;
    wire [C_S_AXIS_TDATA_WIDTH-1:0] s_axis_tdata;
    wire s_axis_tlast;
    wire s_axis_tuser;
    wire s_axis_tready;

    // Signals for DUT (zero_padding_axis)
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

    // Signals for axi_stream_video_size
    wire [31:0] video_width;
    wire [31:0] video_height;
    wire video_size_valid;

    int counter = 0;
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
        .C_S_AXIS_TDATA_WIDTH(C_S_AXIS_TDATA_WIDTH),
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

    // Instantiate the DUT (zero_padding_axis)
    zero_padding_axis #(
        .C_AXIS_TDATA_WIDTH(C_AXIS_TDATA_WIDTH),
        .C_AXIS_FIFO_DEPTH(C_AXIS_FIFO_DEPTH),
        .IMG_WIDTH(10),  // Original image width
        .IMG_HEIGHT(10), // Original image height
        .NUM_PADDING(1)   // Amount of padding around the image
    ) dut (
        .clk(clk),
        .resetn(resetn),
        .s00_axis_tready(s_axis_tready),
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
        .m00_axis_tready(m00_axis_tready) // Always ready to accept data
    );

    // Instantiate the axi_stream_video_size module
    axi_stream_video_size #(
        .C_AXIS_TDATA_WIDTH(C_AXIS_TDATA_WIDTH)
    ) video_size (
        .clk(clk),
        .resetn(resetn),
        .s_axis_tvalid(m00_axis_tvalid),
        .s_axis_tready(m00_axis_tready),
        .s_axis_tdata(m00_axis_tdata),
        .s_axis_tlast(m00_axis_tlast),
        .s_axis_tuser(m00_axis_tuser),
        .video_width(video_width),
        .video_height(video_height),
        .video_size_valid(video_size_valid)
    );

    // Monitor output from DUT
    // initial begin
    //     $monitor("Time: %0t, m00_axis_tvalid: %0b, m00_axis_tdata: %0h, m00_axis_tlast: %0b, m00_axis_tuser: %0b, video_width: %0d, video_height: %0d, video_size_valid: %0b", 
    //         $time, m00_axis_tvalid, m00_axis_tdata, m00_axis_tlast, m00_axis_tuser, video_width, video_height, video_size_valid);
    // end

    // Display video size when valid
    always @(posedge clk) begin
        if (video_size_valid) begin
            $display("video_width: %0d", video_width);
            $display("video_height: %0d", video_height);
        end
        if (m00_axis_tlast) begin
            $display("row counter: %0d", counter);
            counter = counter + 1;
        end
    end
    // Simulation duration
    initial begin
        #2000 $finish;
    end

endmodule
