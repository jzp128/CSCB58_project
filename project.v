


module sickomode(
  input clk,
  input resetn,
  input start,
  input startdraw,
  input [5:0] offset,
  input [2:0] lane_1,
  input [5:0] master_state,
  output all_done,
  output [8:0] x_out,
  output [7:0] y_out,
  output [2:0] c_out);

    wire finish_draw, finish_erase;
    wire [8:0] draw_lane1_x;
    wire [7:0] draw_lane1_y;
    wire [8:0] erase_lane1_x;
    wire [7:0] erase_lane1_y;
	wire draw_done;
    wire start_draw, start_erase;
    wire draw_color, erase_color;
    draw drawlane1(
		.clk(clk),
		.startdraw(startdraw),
		.lane_number(4'b0000),
		.lane_above(lane_1),
		.offset(offset[5:0]),
		.x_out(draw_lane1_x[8:0]),
		.y_out(draw_lane1_y[7:0]),
		.c_out(draw_color),
		.finish_draw(draw_done)
	);
    
    erase eraselane1(
        .clk(clk),
        .start_erase(start_erase),
        .line_id(4'b0000),
        .line_below(3'b111),
        .offset(offset),
        .x_out(erase_lane1_x),
        .y_out(erase_lane1_y),
        .c_out(erase_color),
        .erase_done(finish_erase)
    );

    display_controller controller(
        .clk(clk),
        .resetn(resetn),
        .master_state(master_state),
        .row_draw_done(finish_draw),
        .row_erase_done(finish_erase),
        .draw_color(draw_color),
        .erase_color(erase_color),
        .draw_row1x(draw_lane1_x),
        .draw_rowy1(draw_lane1_y),
        .erase_rowy1(draw_lane1_x),
        .erase_rowy1(draw_lane1_y),
        .all_done(all_done),
        .go_draw(start_draw),
        .go_erase(start_erase),
        .x_out(x_out),
        .y_out(y_out),
        .c_out(c_out)
    );

endmodule // sickomode



module display_controller(
    input clk, 
    input resetn, 
    input start, 
    input startdraw,
    input row_draw_done, row_erase_done,
    input draw_color, erase_color,
    input [7:0] draw_row1x,
    input [7:0] erase_rowy1,
    input [8:0] draw_rowy1,
    input [8:0] erase_rowy1,
    input [5:0] master_state,
    output reg go_draw, go_erase,
    output reg [8:0] x_out,
    output reg [7:0] y_out,
    output reg [2:0] c_out,
    output reg all_done
    );

    reg [2:0] next_state;
    localparam  IDLE        = 3'd0,
                ERASE_1     = 3'd1,
                DRAW_1      = 3'd2,
                DONE        = 3'd3;

    reg curr_state;
    initial curr_state = IDLE;
    always@(*)
    begin: state_table
        case(curr_state)
            IDLE: next_state = startdraw ? ERASE_1 : IDLE;
            ERASE_1: next_state = row_erase_done ? DRAW_1 : ERASE_1; // erases row 1
            DRAW_1: next_state = row_draw_done ? DONE : DRAW_1;  // draws row 1
            DONE: next_state = startdraw ? DONE : IDLE;
            default : next_state = IDLE;
        endcase
    end //state_table

    always @(*)
    begin: enable_signals
        all_done = 1'b0;
        case(curr_state)
            ERASE_1 : begin
                go_erase = 1'b1; // enables erasing of lane 1
                x_out = erase_rowy1;
                y_out = erase_rowy1;
                c_out = 2'b000; // black like the background
                end
            DRAW_1: begin
                go_draw = 1'b1; //enables drawing of lane 1
                x_out = draw_row1x;
                y_out = draw_rowy1;
                c_out = 2'b111; // white for now, change later
                end
            DONE: begin
                all_done = 1'b1;
                x_out = 9'b0; // reset
                y_out = 9'b0;
                c_out = 3'b111; // draw white for now
                end
            default: begin
                x_out = 9'b0;
                y_out = 8'b0;
                c_out = 3'b111;
                end 
        endcase
    end

    always @(posedge clk)
        begin: state_FFs
        if (!resetn | (!start & master_state == 6'd0))
            curr_state <= IDLE;
        else
            curr_state <= next_state;
        end
    
endmodule

module draw(
input clk,
input startdraw,
input [2:0] lane_number,
input [2:0] lane_above,
input [5:0] offset,
output reg [8:0] x_out,
output reg [7:0] y_out,
output reg finish_draw,
output reg c_out
);
reg [7:0] lane_id_offset;
always @(*)
    begin
    lane_id_offset = lane_number * 40;
    end
    
always @(*) begin
    y_out = lane_id_offset + offset;
end

always @(posedge clk) begin
    if (startdraw == 1'b0) begin
        case (lane_above)
            3'b000: begin
                x_out <= 140; 
                finish_draw <= 1'b0;
                c_out <= 1'b0; // black
            end
            3'b001: begin
                x_out <= 120;
                finish_draw <= 1'b0;
                c_out <= 1'b1; // white
            end
            3'b010: begin
                x_out <= 140;
                finish_draw <= 1'b0;
                c_out <= 1'b1; // white
            end
            3'b011: begin
                x_out <= 160;
                finish_draw <= 1'b0;
                c_out <= 1'b1; // white
            end
            3'b100: begin
                x_out <= 180;
                finish_draw <= 1'b0;
                c_out <= 1'b1; // white
            end
            default: begin
                x_out <= 140;
                finish_draw <= 1'b0;
                c_out <= 1'b0; // black
            end
        endcase
    end // if
    else begin
        case (lane_above)
            3'b000: begin//do nothing
                finish_draw <= 1'b1;
                end
            3'b001: begin
                if (x_out == 139)
                    finish_draw <= 1'b1;
                else
                    x_out = x_out + 1;
            end
            3'b010: begin
                if (x_out == 159)
                    finish_draw <= 1'b1;
                else
                    x_out = x_out + 1;
            end
            3'b011: begin
                if (x_out == 179)
                    finish_draw <= 1'b1;
                else
                    x_out = x_out + 1;
            end
            3'b100: begin
                if (x_out == 199)
                    finish_draw <= 1'b1;
                else
                    x_out = x_out + 1;
            end
            default:
                finish_draw <= 1'b1;
        endcase
        end // else
    end // always
endmodule

module erase (
	input clk,
	input start_erase,
	input [3:0] line_id,
	input [2:0] line_below,
	input [5:0] offset,
	output reg [8:0] x_out,
	output reg [7:0] y_out,
	output reg erase_done,
    output c_out
	);
	
	reg [7:0] line_id_offset;
	
	assign c_out = 1'b0; //always draw black
	
	always @(*)
		line_id_offset = line_id * 40;
		
	always @(*)
		y_out = line_id_offset + offset;
		
	always@(posedge clk)
	begin
		if (!start_erase)
			//set up in preparation for signal
			case (line_below)
				3'b000: begin
					x_out <= 140; 
					erase_done <= 1'b0;
				end
				3'b001: begin
					x_out <= 120;
					erase_done <= 1'b0;
				end
				3'b010: begin
					x_out <= 140;
					erase_done <= 1'b0;
				end
				3'b011: begin
					x_out <= 160;
					erase_done <= 1'b0;
				end
				3'b100: begin
					x_out <= 180;
					erase_done <= 1'b0;
				end
				default: begin
					x_out <= 140;
					erase_done <= 1'b0;
				end
			endcase
		else 
			//start incrementing
			case (line_below)
				3'b000: //do nothing
					erase_done <= 1'b1;
				3'b001: begin
					if (x_out == 139)
						erase_done <= 1'b1;
					else
						x_out = x_out + 1;
				end
				3'b010: begin
					if (x_out == 159)
						erase_done <= 1'b1;
					else
						x_out = x_out + 1;
				end
				3'b011: begin
					if (x_out == 179)
						erase_done <= 1'b1;
					else
						x_out = x_out + 1;
				end
				3'b100: begin
					if (x_out == 199)
						erase_done <= 1'b1;
					else
						x_out = x_out + 1;
				end
				default:
					erase_done <= 1'b1;
			endcase
	end //always block
	
endmodule


module counteroffset(
	input resetn, 
	input startn,
	input [5:0] current_state,
	input edge_go,
	input offset_increase,
	input clk,
	
	output reg [5:0] offset);

	always @(posedge clk)
		begin	
			if(!resetn | (!startn & current_state == 5'd0)) 
				offset <= 5'd0; 
			else if(edge_go)
				offset <= 5'd0;
			else if(offset_increase)
				offset <= offset + 1'b1;
		end
endmodule 