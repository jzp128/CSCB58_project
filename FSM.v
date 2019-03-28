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
                        input [5:0] offset,
                        input [2:0] last_line,
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
                                    FOUND = 5'd11,
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
                        FIND : next_state = (offset == 40) ? FOUND : DRAW;
                        FOUND: next_state = (last_line == 3'b000) ? WAIT_TO_DRAW : FOUND_FAIL;
                        WAIT_TO_DRAW : next_state = DRAW;
                        DRAW_FAILED : next_state = coloured_line ? START : DRAW_FAILED;
                        DRAW : next_state = draw_finish ? WAIT_NEXT_ROW : DRAW;
                        WAIT_NEXT_ROW : next_state = wait_finish ? NEXT_ROW : WAIT_NEXT_ROW;
                        NEXT_ROW : next_state = CHECK_INPUT;
                        default: next_state = START;
                endcase
	end
                
        always @(posedge clock)
        begin: state_FFs
                if (!reset)
                        current_state <= START;
                else
                        current_state <= next_state;
        end //state FFs
endmodule