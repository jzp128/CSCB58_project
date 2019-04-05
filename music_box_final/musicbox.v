`timescale 1ns / 1ns

module musicbox
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
		VGA_B,   						//	VGA Blue[9:0]
		HEX0,
		HEX2,
		HEX3,
		GPIO
	);

	input			CLOCK_50;				//	50 MHz
	input   [17:0]   SW;
	input   [3:0]   KEY;
	output  [17:0] 	LEDR;
	output  [6:0] HEX0;
	output [6:0] HEX2,HEX3;
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
	output [9:0] GPIO;
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(1'b1),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "background.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
	wire [2:0] selected;
	wire start_song, update;
	wire done;
	hex_decoder h0(selected,HEX0);
	wire [5:0] debug;
	
	hex_decoder h2(debug[3:0],HEX2);
	hex_decoder h3(debug[5:3],HEX3);

	control c1(
		.resetn(KEY[0]),
		.clk(CLOCK_50),
		.prev(KEY[2]),
		.next(KEY[1]),
		.play(KEY[3]),
		.song_selected(selected), // this gives you the selected song (0,1,2,3,4,5)
		.start_song(start_song), // this is the signal you can use to see if a song is in progress or not (maybe we can just use key[3] also)
		.song_done(finished_song), // DEBUG FOR NOW CAUSE I DONT HAVE THE SOUND MODULE (this is an input to check if the song playing is finished or not)
		.state_debug(debug)
	);
	// so far it just draws dots, but we can change its shapes
	datapath d1(
		.clk(CLOCK_50),
		.selected(selected),
		.start_song(start_song),
		.song_done(finished_song),
		.x_out(x),
		.y_out(y),
		.c_out(colour)
	);
	
	wire [16:0] ledr;
   assign LEDR[16:0] = ledr[16:0];
	wire finished_song;
	wire ledg;
   assign LEDR[17] = ledg;
	top boombox(
	.CLOCK_50(CLOCK_50),
	.KEY(KEY [3:0]),
	.select_signal(selected [2:0]),
	.play_in(SW[0]),
	.GPIO(GPIO),
	.LEDR(ledr[16:0]),
	.LEDG(ledg),
	.done_playing(finished_song)
	);
endmodule

module datapath(
	input clk,
	input song_done,
	input [2:0] selected,
	input start_song,
	output [7:0] x_out,
	output reg [6:0] y_out,
	output reg [2:0] c_out
	);

	localparam  WAIT = 2'd0,
					DRAW = 2'd1,
					ERASE = 2'd2,
					DONE = 2'd3;

	assign x_out = 9'd10;
	reg [6:0] y_pos, y_pos_prev;
	reg [1:0] state;

	initial y_pos = 7'd10;
	initial y_pos_prev = 7'd0;
	always@(posedge clk)
	begin
		case(state)
			WAIT: begin
				state = DRAW;
			end
			
			ERASE: begin
				// do erasing
				y_out = y_pos_prev;
				c_out = 3'b111;
				y_pos_prev = y_pos;
				state = DONE;
			end

			DRAW: begin
					// get location to draw the dot based on song
					case(selected)
						3'd0: begin
							y_pos = 7'd8;
						end
						3'd1: begin
							y_pos = 7'd21;
						end
						3'd2: begin
							y_pos = 7'd34;
						end
						3'd3: begin
							y_pos = 7'd47;
						end
						3'd4: begin
							y_pos = 7'd60;
						end
						3'd5: begin
							y_pos = 7'd73;
						end
					endcase
						if (y_pos != y_pos_prev) begin
							// draws green dot
							y_out = y_pos;
							c_out = 3'b010;
							state = ERASE;
						end
						else begin
							if (start_song) begin
								y_out = y_pos;
								c_out = 3'b100;
							end
							state = DONE;
						end
			end
			DONE: begin
				state = WAIT;
			end
	endcase
			
	end
endmodule

module control(
	input resetn,
	input clk,
	input prev,
	input next,
	input play,
	input song_done,
	input draw_done,
	output reg [2:0] song_selected,
	output reg start_song,
	output [4:0] state_debug
);
	assign state_debug = curr_state;
	reg [4:0] curr_state, next_state;
	localparam 
					SELECT_1 = 5'd0,
					WAIT_12 = 5'd1,
					WAIT_21 = 5'd2,
					SELECT_2 = 5'd3,
					WAIT_23 = 5'd4,
					WAIT_32 = 5'd5,
					SELECT_3 = 5'd6,
					WAIT_34 = 5'd7,
					WAIT_43 = 5'd8,
					SELECT_4 = 5'd9,
					WAIT_45 = 5'd10,
					WAIT_54 = 5'd11,
					SELECT_5 = 5'd12,
					WAIT_56 = 5'd13,
					WAIT_65 = 5'd14,
					SELECT_6 = 5'd15,
					WAIT_61 = 5'd16,
					WAIT_16 = 5'd17,
					PLAY_SELECTED = 5'd18;

	// the wait states are there to stop the buttons from bouncing
	reg [4:0] prev_state; // only store the song ones
	always@(*)
	begin: state_table
		case (curr_state)
			WAIT_16: next_state = prev ? SELECT_6 : WAIT_16;
			SELECT_1: begin
				if(~prev) begin
					next_state = WAIT_16;
				end
				else if (~next) begin
					next_state = WAIT_12;
				end
				else if (~play) begin
					prev_state <= SELECT_1;
					next_state <= PLAY_SELECTED;
					end
				else
					next_state = SELECT_1;
			end
			WAIT_12: next_state = next ? SELECT_2 : WAIT_12;
			WAIT_21: next_state = prev ? SELECT_1 : WAIT_21;
			SELECT_2: begin
				if(~prev) begin
					next_state = WAIT_21;
				end
				else if (~next) begin
					next_state = WAIT_23;
				end
				else if (~play) begin
					prev_state <= SELECT_2;
					next_state <= PLAY_SELECTED;
					end
				else
					next_state = SELECT_2;
			end

			WAIT_23: next_state = next ? SELECT_3 : WAIT_23;
			WAIT_32: next_state = prev ? SELECT_2 : WAIT_32;

			SELECT_3: begin
				if(~prev) begin
					next_state = WAIT_32;
				end
				else if (~next) begin
					next_state = WAIT_34;
				end
				else if (~play) begin
					prev_state <= SELECT_3;
					next_state <= PLAY_SELECTED;
					end
				else
					next_state = SELECT_3;
			end

			WAIT_34: next_state = next ? SELECT_4 : WAIT_34;
			WAIT_43: next_state = prev ? SELECT_3 : WAIT_43;

			SELECT_4: begin
				if(~prev) begin
					next_state = WAIT_43;
				end
				else if (~next) begin
					next_state = WAIT_45;
				end
				else if (~play) begin
					prev_state <= SELECT_4;
					next_state <= PLAY_SELECTED;
					end
				else
					next_state = SELECT_4;
			end
			
			WAIT_45: next_state = next ? SELECT_5 : WAIT_45;
			WAIT_54: next_state = prev ? SELECT_4 : WAIT_54;

			SELECT_5: begin
				if(~prev) begin
					next_state = WAIT_54;
				end
				else if (~next) begin
					next_state = WAIT_56;
				end
				else if (~play) begin
					prev_state <= SELECT_5;
					next_state <= PLAY_SELECTED;
					end
				else
					next_state = SELECT_5;
			end
			
			WAIT_56: next_state = next ? SELECT_6 : WAIT_56;
			WAIT_65: next_state = prev ? SELECT_5 : WAIT_65;

			SELECT_6: begin
				if(~prev) begin
					next_state = WAIT_65;
				end
				else if (~next) begin
					next_state = WAIT_61;
				end
				else if (~play) begin
					prev_state = SELECT_6;
					next_state = PLAY_SELECTED;
					end
				else
					next_state = SELECT_6;
			end
			
			WAIT_61: next_state = next ? SELECT_1 : WAIT_61;

			PLAY_SELECTED: next_state = song_done ? prev_state : PLAY_SELECTED; // this part is glitchy af for some reason, probably because prev_state can be unset?
			default : next_state = SELECT_1;  // should never happen tbh
		endcase
	end // state table
	
	initial song_selected = 3'd0;
	always@(*)
	begin: enable_signals
		start_song = 0;
		case(curr_state)
			SELECT_1: begin
				song_selected = 3'd0;
			end
			SELECT_2: begin 
				song_selected = 3'd1;
			end
			SELECT_3: begin 
				song_selected = 3'd2;
			end
			SELECT_4: begin 
				song_selected = 3'd3;
			end
			SELECT_5: begin 
				song_selected = 3'd4;
			end
			SELECT_6: begin 
				song_selected = 3'd5;
			end
			// these are to prevent the dot from "jumping" back to pos 0
			WAIT_12: song_selected = 3'd0;
			WAIT_16: song_selected = 3'd0;

			WAIT_21: song_selected = 3'd1;
			WAIT_23: song_selected = 3'd1;
			
			WAIT_32: song_selected = 3'd2;
			WAIT_34: song_selected = 3'd2;
			
			WAIT_43: song_selected = 3'd3;
			WAIT_45: song_selected = 3'd3;
			
			WAIT_54: song_selected = 3'd4;
			WAIT_56: song_selected = 3'd4;
			
			WAIT_61: song_selected = 3'd5;
			WAIT_65: song_selected = 3'd5;

			PLAY_SELECTED: begin
			// theres probably a better way to do this but idc anymore
				start_song = 1;
				case(prev_state)
					SELECT_1: begin
					song_selected = 3'd0;
					end
					SELECT_2: begin 
						song_selected = 3'd1;
					end
					SELECT_3: begin 
						song_selected = 3'd2;
					end
					SELECT_4: begin 
						song_selected = 3'd3;
					end
					SELECT_5: begin 
						song_selected = 3'd4;
					end
					SELECT_6: begin 
						song_selected = 3'd5;
					end
				endcase
			end

			default: begin
				start_song = 0;
			end
		endcase
	end// enable_signals
	always@(posedge clk)
    begin: state_FFS
      curr_state = ~resetn ? SELECT_1 :next_state;
		
    end
endmodule

module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;

    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;
            default: segments = 7'h7f;
        endcase
endmodule
