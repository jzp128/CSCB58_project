module fsm(
	input clk,
			reset,
			start,
			screen_reset,
			draw_finish,
			wait_finish,
			input_checked,
			hit,
			miss,
			hit_finish,
			miss_finish,
			colured_line,
			//offset,
			input [2:0] line_6,
	output reg reset_out,
		draw_out,
		wait_out,
		edge_out,
		offset_increase,
		check_input_out,
		hit_out,
		miss_out,
		coloured_line_out);

	localparam START = 5'd0,
				  RESET = 5'd1,
					CHECK_INPUT = 5'd7,
					HIT = 5'd8,
					MISS = 5'd9,
				  FIND = 5'd2, //????
					CHECK_FOUND = 5'd11,
				  WAIT_TO_DRAW = 5'd3,
				    DRAW_FAILED = 5'd10,
				  DRAW = 5'd4,
				  WAIT_NEXT_ROW = 5'd5,
				  NEXT_ROW = 5'd6;
	
	innitial curr_state = START;
	always @(*)
	begin: states
		case (curr_state)
			START : next_state = start ? START : RESET;
			RESET : next_state = screen_reset ? CHECK_INPUT : RESET
			CHECK_INPUT : begin
								if (hit && input_checked):
									next_state = HIT;
								else if (miss && input_checked):
									next_state = MISS;
								else if (input_checked):
									next_state = FIND;
								else
									next_state = CHECK_INPUT;
								end
			HIT : next_state = hit_finish ? DRAW : HIT;
			MISS : next_state = miss_finish ? WAIT_TO_DRAW : MISS;
			//FIND : next_edge = 
			//CHECK_FOUND: 
			WAIT_TO_DRAW : next_state = DRAW;
			//FOUND_FAIL
			DRAW_FAILED : next_state = coloured_line ? START : DRAW_FAILED;
			DRAW : next_state = draw_finish ? WAIT_NEXT_ROW : DRAW;
			WAIT_NEXT_ROW : next_state = wait_finish ? NEXT_ROW : WAIT_NEXT_ROW;
			NEXT_ROW : next_state = CHECK_INPUT;
			default: next_state = START;
		endcase
	end

	always @(*)
	begin: enable_states
		reset_out = 1'b0;
		draw_out = 1'b0;
		wait_out = 1'b0;
		edge_out = 1'b0;
		offset_increase = 1'b0;
		check_input_out = 1'b0;
		hit_out = 1'b0;
		miss_out = 1'b0;
		coloured_line_out = 1'b0;
		
		case (current_state)
			//WAIT_FOR_START :
			RESET	: reset_out = 1'b1;
			CHECK_INPUT		: check_input_out = 1'b1;
			HIT	: hit_out = 1'b1;
			MISS: miss_out = 1'b1;
			//FIND		: 
			//CHECK_FOUND		:
			WAIT_TO_DRAW		: //edge_go = 1'b1;
			DRAW_FAIL		: coloured_line_out = 1'b1;
			DRAW		: draw_out = 1'b1;
			WAIT_NEXT_ROW	: wait_out = 1'b1;
			NEXT_ROW			: offset_increase = 1'b1;
			default: reset_screen_out = 1'b0; //just to make quartus stop screaming at me
		endcase
	end //enable_signals
		
	always @(posedge clock)
	begin: state_FFs
		if (!reset)
			current_state <= START;
		else
			current_state <= next_state;
	end //state FFs
endmodule
				  