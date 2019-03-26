module main(CLOCK_50);
    input CLOCK_50;
endmodule

module lane(clk, yposOut);

endmodule

module score(clk, addscore, score, reset, new_score);
    input clk;
    input addscore;
    input [19:0] score;
    output reg [19:0] new_score;

    always @(posedge addscore)
        if (reset == 1'b0)
            score = 10'd0;
        else if (addscore) begin
            new_score = score + 10'd100;
            end
    end

endmodule


module display_controller(input clk, 
            input resetn, 
            input start, 
            input startdraw,
            input [7:0] draw_lanex1,
            input [7:0] erase_lanex1,
            input [8:0] draw_laney1,
            input [8:0] erase_laney1,
            input [5:0] master_state,
            output reg godraw, goerase,
            output [8:0] x_out,
            output [7:0] y_out,
            output [2:0] c_out,
            output [4:0] currstate,
            output reg all_done
            );

        reg [2:0] next_state;
        localparam  IDLE        = 3'd0,
                    ERASE_1     = 3'd1,
                    DRAW_1      = 3'd2,
                    DONE        = 3'd3;

        initial curr_state = IDLE;
        always@(*)
        begin: state_table
            case(curr_state)
                WAIT: next_state = startdraw ? ERASE_1 : IDLE;
                ERASE_1: next_state = erase1_done ? DRAW_1 : ERASE_1;
                DRAW_1: next_state = draw1done ? DONE : DRAW_1;
                DONE: next_state = startdraw ? DONE : WAIT;
                default : next_state = WAIT;
            endcase
        end //state_table

        always @(*)
        begin: enable_signals
            all_done = 1'b0;
            case(curr_state)
                ERASE_1 : begin
                    goerase = 1'b1; // enables erasing of lane 1
                    x_out = erase_lanex1;
                    y_out = erase_laney1;
                    c_out = 2'b000; // black like the background
                    end
                DRAW_1: begin
                    godraw = 1'b1 //enables drawing of lane 1
                    x_out = draw_lanex1;
                    y_out = draw_laney1;
                    c_out = 2'b111; // white for now, change later
                    end
                DONE: begin
                    all_done = 1'b1;
                    x_out = 9'b0; // reset
                    y_out = 9'b0;
                    colour_out = 3'b111; // draw white for now
                    end
                default: begin
                    x_out = 9'b0;
                    y_out = 8'b0;
                    colour_out = 3'b111;
                    end 
            endcase
        end

        always @(posedge clock)
            begin: state_FFs
            if (!resetn | (!start & master_state == 6'd0))
                current_state <= WAIT;
            else
                current_state <= next_state;
endmodule

module draw(
    input clk,
    input startdraw,
    input [2:0] lane_numer,
    input [2:0] lane_above,
    input [5:0] offset,
    output reg [8:0] x_out,
    output reg [7:0] y_out,
    output reg [2:0] colour_out
    output reg finish_draw
    );


endmodule