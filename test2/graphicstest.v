module graphicstest
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		  LEDR,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B ,  						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;
	output  [3:0] 	LEDR;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;
	assign colour = SW[9:7];

//	assign writeEn = KEY[3]; // change this

	wire [6:0] out_x, out_y;
	wire [2:0] out_colour;


	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(out_colour),
			.x(out_x),
			.y(out_y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "320x240";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
	wire [5:0] offset;
	wire [5:0] current_state;
	// wire drawing_done;

	wire screen_reset, drawing_done, wait_done, input_checked, hit, miss, hit_finish, miss_finish, coloured_line;
//	wire [5:0] offset;
	wire [2:0] bottom_line;
	wire reset_out, draw_out, wait_out, edge_out, offset_increase, check_input;
	// fsm master_state_machine(
	// 	.clk(CLOCK_50),
	// 	.reset(KEY[0]),
	// 	.start(KEY[3]),
	// 	.screen
	// );

	counteroffset lineface(
		.clk(CLOCK_50),
		.resetn(KEY[0]),
		.startn(KEY[3]),
		.current_state(6'b000001),
		.edge_go(edge_go),
		.offset_increase(offset_increase),
		.offset(offset[5:0])
		);
	
	assign LEDR[0] = KEY[3];
	sickomode pickandroll(
		.clk(KEY[1]),
		.resetn(KEY[0]),
		.start(KEY[3]),
		.offset(offset),
		.row_1(3'b000),
		.master_state(6'b000001),
		.all_done(drawing_done),
		.x_out(out_x),
		.y_out(out_y),
		.c_out(out_colour),
		.writeEN(writeEn),
		.stateoutputTest(LEDR[3:1])
	);

	//wire [27:0] w1hzout;
	wire w1hzout;
	assign w1hzout = SW[0];
	//assign clokty = (w1hzout == 0) ? 1 : 0;
	//rate_divider2 rd1hz(clk, w1hzout);
endmodule

// module ratedivider(enable, load, clk, clear_b, q);
//     input enable, clk, clear_b;
//     input [27:0] load;
//     output reg [27:0] q;


//     always @(posedge clk)
//          begin
//             if (clear_b == 1'b0)
//                 q <= load;
//             else if (q == 0)
//                 q <= load;
//             else if (enable == 1'b1)
//                 q <= q - 1'b1;
//     end
// endmodule

module rate_divider2(clkin,clkout);
    reg [24:0] counter;
    output reg clkout;
    input clkin;
    initial begin
         counter = 0;
         clkout = 0;
    end
    always @(posedge clkin)
    begin
         if (counter == 0) begin
              counter <= 28'd49999999 / 2;
              clkout <= ~clkout;
         end else begin
              counter <= counter -1;
         end
    end
endmodule
