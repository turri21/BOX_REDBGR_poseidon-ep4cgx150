module vga_display (
    input        clk_sys,     // System Clock  50MHz
    input        reset,       // Reset signal
    output       VGA_HS,      // Horizontal sync
    output       VGA_VS,      // Vertical sync
    output [5:0] VGA_R,       // VGA red output
    output [5:0] VGA_G,       // VGA green output
    output [5:0] VGA_B        // VGA blue output
);
    // VGA 640x480 @ 60 Hz timing constants
    parameter H_DISPLAY   = 640;
    parameter H_FRONT     = 16;
    parameter H_SYNC      = 96;
    parameter H_BACK      = 48;
    parameter H_TOTAL     = 800;

    parameter V_DISPLAY   = 480;
    parameter V_FRONT     = 10;
    parameter V_SYNC      = 2;
    parameter V_BACK      = 33;
    parameter V_TOTAL     = 525;
	 
    // Box coordinates
    parameter BOX_X_START = 200;
    parameter BOX_X_END   = 400;
    parameter BOX_Y_START = 150;
    parameter BOX_Y_END   = 300;
	
    reg [9:0] h_count = 0;  // Horizontal counter (0 to 799)
    reg [9:0] v_count = 0;  // Vertical counter (0 to 524)

    // Signals for video timing
    wire video_on = (h_count < H_DISPLAY) && (v_count < V_DISPLAY);
    assign VGA_HS = (h_count >= H_DISPLAY + H_FRONT) && (h_count < H_DISPLAY + H_FRONT + H_SYNC);
    assign VGA_VS = (v_count >= V_DISPLAY + V_FRONT) && (v_count < V_DISPLAY + V_FRONT + V_SYNC);

    // Clocking for horizontal and vertical timing
    always @(posedge clk_vga or posedge reset) begin
        if (reset) begin
            h_count <= 0;
            v_count <= 0;
        end else begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 0;
                if (v_count == V_TOTAL - 1) begin
                    v_count <= 0;
                end else begin
                    v_count <= v_count + 1;
                end
            end else begin
                h_count <= h_count + 1;
            end
        end
    end
	
    wire clk_vga, locked;
 
    pll pll(
	.areset(reset),
	.inclk0(clk_sys),
	.c0(clk_vga),     //25 MHz clock for 640x480 @ 60Hz
	.locked(locked)
    );
	
    // RGB signals coming from mist_video
    wire [5:0] r, g, b;

    // Instantiation of mist_video module
    mist_video #(.COLOR_DEPTH(6)) video_inst (
        .clk_sys(clk_vga),          // 25 MHz clock
        .SPI_SCK(1'b0),             // Disable OSD
        .SPI_SS3(1'b0),             // Disable OSD
        .SPI_DI(1'b0),              // Disable OSD
        .scanlines(2'b00),          // No scanlines
        .ce_divider(3'b000),        // Default clock divider
        .scandoubler_disable(1'b0), // Enable scandoubler
        .no_csync(1'b0),            // Enable composite sync
        .ypbpr(1'b0),               // Output RGB
        .rotate(2'b00),             // No rotation
        .blend(1'b0),               // No blending
        .R(6'b000000),              // Red
        .G(6'b000000),              // Green
        .B(6'b000000),              // Blue
        .VGA_R(r),                  // VGA red output from mist_video
        .VGA_G(g),                  // VGA green output from mist_video
        .VGA_B(b),                  // VGA blue output from mist_video
        .vga_hsync(),               // Not used (handled externally)
        .vga_vsync()                // Not used (handled externally)
    );

    // Box color logic (draw a white box)
    wire is_in_box = (h_count >= BOX_X_START && h_count < BOX_X_END && v_count >= BOX_Y_START && v_count < BOX_Y_END);
	
    // Output RGB to VGA
    assign VGA_R = video_on ? (is_in_box ? 6'b111111 : 6'b111111) : 6'b000000;  // Red channel
    assign VGA_G = video_on ? (is_in_box ? 6'b111111 : 6'b000000) : 6'b000000;  // Green channel
    assign VGA_B = video_on ? (is_in_box ? 6'b111111 : 6'b000000) : 6'b000000;  // Blue channel
endmodule
