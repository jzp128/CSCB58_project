// Part 2 skeleton

module part2
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
		VGA_B   						//	VGA Blue[9:0]
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
	assign writeEn = KEY[3];
	wire ld_x, ld_y, ld_r;
	assign LEDR[0] = ld_x;
	assign LEDR[1] = ld_y;
	assign LEDR[2] = ld_r;
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
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
    

    // Instansiate datapath
	datapath d0(
		.clk(CLOCK_50),
		.resetn(resetn),
		.colour(colour),
		.data_in(SW[6:0]),
		.ld_x(ld_x),
		.ld_y(ld_y),
		.ld_r(ld_r),
		.out_x(out_x),
		.out_y(out_y),
		.out_colour(out_colour)
	);

	// Instansiate FSM control
	control C0(
        .clk(CLOCK_50),
        .resetn(resetn),
        .go(writeEn),
        .ld_x(ld_x),
        .ld_y(ld_y),
        .ld_r(ld_r) 
    );

    
endmodule

module control(
    input clk,
    input resetn,
    input go,
    output reg  ld_x, ld_y, ld_r
    );

    reg [3:0] current_state, next_state; 
    
    localparam  S_LOAD_X        = 3'd0,
                S_LOAD_X_WAIT   = 3'd1,
                S_LOAD_Y        = 3'd2,
                S_LOAD_Y_WAIT   = 3'd3,
                S_CYCLE_0       = 3'd4,
					 S_CYCLE_0_WAIT  = 3'd5;
    
    // Next state logic aka our state table
    always@(*)
    begin: state_table 
            case (current_state)
                S_LOAD_X: next_state = go ? S_LOAD_X_WAIT : S_LOAD_X; // Loop in current state until value is input
                S_LOAD_X_WAIT: next_state = go ? S_LOAD_X_WAIT : S_LOAD_Y; // Loop in current state until go signal goes low
                S_LOAD_Y: next_state = go ? S_LOAD_Y_WAIT : S_LOAD_Y; // Loop in current state until value is input
                S_LOAD_Y_WAIT: next_state = go ? S_LOAD_Y_WAIT : S_CYCLE_0; // Loop in current state until go signal goes low
                S_CYCLE_0: next_state = go ? S_CYCLE_0_WAIT : S_CYCLE_0; // Loop in current state until value is input
                S_CYCLE_0_WAIT: next_state = go ? S_CYCLE_0_WAIT : S_LOAD_X; // Loop in current state until go signal goes lowr
            default:     next_state = S_LOAD_X;
        endcase
    end // state_table
   

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
        ld_x = 1'b0;
        ld_y = 1'b0;
        ld_r = 1'b0;

        case (current_state)
            S_LOAD_X_WAIT: begin
                ld_x = 1'b1;
                end
            S_LOAD_Y_WAIT: begin
                ld_y = 1'b1;
                end
				S_CYCLE_0_WAIT: begin 
                ld_r = 1'b1;
 
            end
        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals
   
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_LOAD_X;
        else
            current_state <= next_state;
    end // state_FFS
endmodule


module datapath(
		input clk,
		input resetn,
		input [2:0] colour,
		input [6:0] data_in,
		input ld_x, ld_y,
		input ld_r,
		output reg [6:0] out_x,
		output reg [6:0] out_y,
		output reg [2:0] out_colour
	);
	
	reg [6:0] x, y;
	reg [3:0] offset;

	// Registers a, b, c, x with respective input logic
    always@(posedge clk) begin
        if(!resetn) begin
            x <= 6'b0; 
            y <= 6'b0; 
        end
        else begin
            if(ld_x)
                x <= data_in;
            if(ld_y)
                y <= data_in;
        end
    end
	
	// Output result register
    always@(posedge clk) begin
        if(!resetn) begin
            out_x <= 6'b0;
				out_y <= 6'b0;
				out_colour <= 3'b0;
        end
        else begin
            if(ld_r) begin
						out_x <= x + offset[3:2];
						out_y <= y + offset[1:0];
						out_colour <= colour;
						offset <= offset + 1'b1;
						if(offset == 4'd15)
							offset <= 4'b0;
				end
			end
    end

endmodule