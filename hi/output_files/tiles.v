`timescale 1ns / 1ns
module tiles(
                CLOCK_50,                                               //      On Board 50 MHz
                // Your inputs and outputs here
                KEY,
                SW,
                LEDG,
					 LEDR,
                HEX0,
                HEX1,
					 HEX4,
                // The ports below are for the VGA output.  Do not change.
                VGA_CLK,                                                //      VGA Clock
                VGA_HS,                                                 //      VGA H_SYNC
                VGA_VS,                                                 //      VGA V_SYNC
                VGA_BLANK_N,                                            //      VGA BLANK
                VGA_SYNC_N,                                             //      VGA SYNC
                VGA_R,                                                  //      VGA Red[9:0]
                VGA_G,                                                  //      VGA Green[9:0]
                VGA_B                                                   //      VGA Blue[9:0]
        );

        input   CLOCK_50;                               //      50 MHz
        input   [17:0]   SW;
        input   [3:0]   KEY;
		  output   [6:0]   HEX0, HEX1, HEX4;
		  output  [17:0] 	LEDR;
        output  [3:0]   LEDG;

        // Declare your inputs and outputs here
        // Do not change the following outputs
        output                  VGA_CLK;                                //      VGA Clock
        output                  VGA_HS;                                 //      VGA H_SYNC
        output                  VGA_VS;                                 //      VGA V_SYNC
        output                  VGA_BLANK_N;                            //      VGA BLANK
        output                  VGA_SYNC_N;                             //      VGA SYNC
        output  [9:0]   VGA_R;                                  //      VGA Red[9:0]
        output  [9:0]   VGA_G;                                  //      VGA Green[9:0]
        output  [9:0]   VGA_B;                                  //      VGA Blue[9:0]

        wire resetn;
        assign resetn = SW[16];

        // Create the colour, x, y and writeEn wires that are inputs to the controller.
        wire [2:0] colour;
        wire [7:0] x;
        wire [6:0] y;
        wire [7:0] score;
        wire [1:0] lives;
		  wire [3:0] level;

        // Create an Instance of a VGA controller - there can be only one!
        // Define the number of colours as well as the initial background
        // image file (.MIF) for the controller.
        vga_adapter VGA(
                        .resetn(1'b1),
                        .clock(CLOCK_50),
                        .colour(colour),
                        .x(x),
                        .y(y),
                        .plot(1'b1),
                        // Signals for the DAC to drive the monitor.
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
                
        control(
            .clk(CLOCK_50),
            .resetn(resetn),
            .pause(SW[17]),
            .mode(SW[15]),
            .key0(SW[0]),
            .key1(SW[1]),
            .key2(SW[2]),
            .key3(SW[3]),
            .x(x),
            .y(y),
            .col(colour),
            .score(score),
            .lives(lives),
				.out_lives(LEDG[2:0]),
				.level(level)
        );
        
        // display score on HEX0, HEX1
        hex_decoder h1(
            .hex_digit(score[7:4]),
            .segments(HEX1[6:0])
        );
        
        hex_decoder h0(
            .hex_digit(score[3:0]),
            .segments(HEX0[6:0])
        );
		  
        hex_decoder h4(
            .hex_digit(level[3:0]),
            .segments(HEX4[6:0])
        );

endmodule


module control(
    input clk,
    input resetn,
    input pause,
    input mode,
    input key0, key1, key2, key3,

    output reg [7:0] x, 
    output reg [6:0] y, 
    output reg [2:0] col, 
    output reg [7:0] score,
    output reg [1:0] lives,
	 output [2:0] out_lives,
	 output reg [3:0] level);
    
    reg [4:0] state;
    reg [4:0] prev_state;
    reg [18:0] draw_screen;
    reg [27:0] speed;
    reg [8:0] tile_counter;
    reg [6:0] line_counter;
    reg [7:0] x_d, x_p, p_x; // x position of tiles
    reg [6:0] y_d, y_p, p_y; // y postition of tiles
    reg [2:0] t_c; // colour of tiles
    reg [1:0] c_tile; // which tile is being drawn
    reg start, check_score, check; // boolean for when player started
    wire [4:0] num;
    wire [1:0] tile; // select which tile to draw
    reg [7:0] max_score; // max score for a level
    wire p0, p1, p2, p3; // for pressing correct key
    
    wire en, counter;
    assign tile = num[4:3]; // random tile number
	 
    display_lives d(
				.clk(clk),
            .mode(mode),
            .lives(lives),
            .out(out_lives)
        );
		  
    generator g(
        .clk(clk),
        .resetn(resetn),
        .data(num)
        );
    
    counter c(
        .clk(clk),
        .speed(speed),
        .frame(counter)
        );

    check_tile ct(
        .clk(clk),
        .check(check),
        .tile(c_tile),
        .key0(key0),
        .key1(key1),
        .key2(key2),
        .key3(key3),
        .p0(p0),
        .p1(p1),
        .p2(p2),
        .p3(p3)
        );

    
    localparam START = 5'b00000,
               DRAW_LINE = 5'b00001,
               RESET = 5'b00010,
               PAUSE = 5'b00011,
               DRAW_TILES = 5'b00100,
               INIT_T1 = 5'b00101,
               //INIT_T2 = 5'b00110,
               //INIT_T3 = 5'b00111,
               //INIT_T4 = 5'b01000,
               DRAW_T = 5'b01001,
               ERASE_TILE = 5'b01010,
               FRAME = 5'b01011,
               ADD_TILE = 5'b01100,
               CHECK_TILE = 5'b01101,
               INC_SPEED = 5'b01110,
               CHECK_LEVEL = 5'b01111,
               GAME_OVER = 5'b10000,
               WIN = 5'b10001,
					CLEAR_SCREEN = 5'b10010;
    
    always @(posedge clk)
    begin
        x <= 8'b0;
        y <= 7'b0;
        col <= 3'b0;
		  if (!start) state = START;
        if (resetn) state = RESET;
        if (pause) state = PAUSE;
    case (state)
        START: begin
            start <= 1'b1;
            score <= 8'b0;
            speed <= 28'd999999;
            lives <= 2'b11; // starts with 3 lives
            level <= 4'b0001;
				y <= draw_screen[7:0];
            x <= draw_screen[14:8];
            draw_screen <= draw_screen + 1'b1;
            col <= 3'b111; //draw white
            state = DRAW_LINE;
        end
        DRAW_LINE: begin
            y <= 8'd110;
            if (line_counter < 7'd120) begin
                x <= line_counter[6:0];
					 line_counter <= line_counter + 1'b1;
					 col <= 3'b010;
            end
            else begin
                line_counter <= 7'b0;
                state = DRAW_TILES;
            end
        end
        // clear everything
         RESET: begin
            if (draw_screen < 16'd65535) begin
                y <= draw_screen[7:0];
                x <= draw_screen[14:8];
                draw_screen <= draw_screen + 1'b1;
					 col <= 3'b111;
            end
            else begin
                draw_screen <= 16'b0;
					 tile_counter <= 9'b0;
					 start <= 1'b0;
                /*
					 score <= 8'b0;
                speed <= 28'd199999999;
                lives <= 2'b11; // starts with 3 lives
                level <= 4'b0001;
                state = DRAW_TILES;
					 */
            end
        end
		  CLEAR_SCREEN: begin
            if (draw_screen < 16'd65535) begin
                y <= draw_screen[7:0];
                x <= draw_screen[14:8];
                draw_screen <= draw_screen + 1'b1;
					 col <= 3'b111;
					 
            end
            else begin
                draw_screen <= 16'b0;
					 tile_counter <= 9'b0;
					 state = DRAW_LINE;
				end
		  end
		  
        PAUSE: begin
             if (!pause)
                 state = prev_state;
        end
        DRAW_TILES: begin
        // choose a random tile to draw
            if (tile == 2'b00)
                state = INIT_T1;
//            else if (tile == 2'b01)
//                state = INIT_T2;
//            else if (tile == 2'b10)
//                state = INIT_T3;
//            else
//                state = INIT_T4;
        end
        INIT_T1: begin
        // set where to draw first tile
            p_x <= 8'b0;
            p_y <= 7'd1;
            x_d <= 8'b0;
            y_d <= 7'd1;
            t_c <= 3'b000; // tiles are black
            //c_tile <= 2'b0;
            state = DRAW_T;
        end
//        INIT_T2: begin
//        // set where to draw second tile
//            p_x <= 8'b0;
//            p_y <= 7'd38;
//            x_d <= 8'b0;
//            y_d <= 7'd38;
//            t_c <= 3'b010;
//            c_tile <= 2'b01;
//            state = DRAW_T;
//        end
//        INIT_T3: begin
//        // set where to draw third tile
//            p_x <= 8'b0;
//            p_y <= 7'd65;
//            x_d <= 8'b0;
//            y_d <= 7'd65;
//            t_c <= 3'b001;
//            c_tile <= 2'b10;
//            state = DRAW_T;
//        end
//        INIT_T4: begin
//        // set where to draw fourth tile
//            p_x <= 8'b0;
//            p_y <= 7'd92;
//            x_d <= 8'b0;
//            y_d <= 7'd92;
//            t_c <= 3'b110;
//            c_tile <= 2'b11;
//            state = DRAW_T;
//        end
	
        DRAW_T: begin
            prev_state <= state;
				if (p_y < 8'd120) begin
					if (tile_counter < 9'd256) begin
						 y <= p_y + tile_counter[7:4];
						 x <= p_x + tile_counter[3:0];
						 tile_counter <= tile_counter + 1'b1;
						 
						 col <= 3'b000;
					end
					else begin
						 tile_counter <= 9'b0;
						 p_y <= p_y + 1'b1;
						 state = FRAME;
					end

					if (p_y > 105 && p_y < 119) begin
						check <= 1'b1;
						if (p0 || p1 || p2 || p3) begin
							state = CHECK_TILE;
						end
					end
					else begin
						check <= 1'b0;
					end
				
				end
				else begin
					state = CHECK_TILE;
				end
				


        end
        FRAME: begin
            if (counter)
                state = ERASE_TILE;
			end
        ERASE_TILE: begin
            prev_state <= state;
            if (y_d < 8'd144) begin
                if (tile_counter < 9'd256) begin
                    y <= y_d + tile_counter[7:4];
                    x <= x_d + tile_counter[3:0];
                    tile_counter <= tile_counter + 1'b1;
                    col <= 3'b111;
                end
                else begin
                    tile_counter <= 9'b0;
                    y_d <= y_d + 1'b1;
                    state = DRAW_T;
                end
            end
            else
                state = CHECK_TILE;
					 
			end
        CHECK_TILE: begin
            prev_state <= state;
				state = CHECK_LEVEL;
            if (p0 || p1 || p2 || p3) begin
                score <= score + 1'b1;
                check_score <= 1'b1;
            end
            // at infinite mode, decrease score if tile was not pressed correctly
            else if (mode == 1'b1 && check_score) begin
                if (score > 0)
						score <= score - 1'b1;
					 if (score == 0)
						state = GAME_OVER;
            end
            // normal mode, decrease life
            else if (mode == 1'b0) begin
                lives <= lives - 1'b1;
					 if (lives == 0)
						state = GAME_OVER;
            end
            
			end
        CHECK_LEVEL: begin
            // 15 levels max
            if (level == 4'b1111) begin
                state = WIN;
            end
            else
                state = INC_SPEED;
        end
        INC_SPEED: begin
            max_score <= level * 8'd5;
            if (score == max_score) begin
                speed <= speed/10 * 9;
                level <= level + 1'b1;
            end
            state = CLEAR_SCREEN;
        end
        WIN: begin
            prev_state <= state;
            if (draw_screen < 16'd65535) begin
                y <= draw_screen[7:0];
                x <= draw_screen[14:8];
                draw_screen <= draw_screen + 1'b1;
                col <= 3'b010; //green
            end
            else begin
                draw_screen <= 16'b0;
                if (resetn) state = RESET;
            end
        end
        GAME_OVER: begin
            prev_state <= state;
           if (draw_screen < 16'd65535) begin
                y <= draw_screen[7:0];
                x <= draw_screen[14:8];
                draw_screen <= draw_screen + 1'b1;
                col <= 3'b100; //red
            end
            else begin
                draw_screen <= 16'b0;
                if (resetn) state = RESET;
            end
        end
    endcase
    end
endmodule

//check if player hit the right key
module check_tile(clk, check, tile, key0, key1, key2, key3, p0, p1, p2, p3);
    input clk, check, key0, key1, key2, key3;
    input [1:0] tile;
    output reg p0, p1, p2, p3;
    
    always @(posedge clk)
    begin
        if (check && tile == 2'b00 && key0) begin
            p0 <= 1'b1;
            p1 <= 1'b0;
            p2 <= 1'b0;
            p3 <= 1'b0;
        end
        else if (tile == 2'b01 && key1 && check) begin
            p1 <= 1'b1;
            p0 <= 1'b0;
            p2 <= 1'b0;
            p3 <= 1'b0;
        end
        else if (tile == 2'b10 && key2 && check) begin
            p2 <= 1'b1;
            p0 <= 1'b0;
            p1 <= 1'b0;
            p3 <= 1'b0;
        end
        else if (tile == 2'b11 && key3 && check) begin
            p3 <= 1'b1;
            p0 <= 1'b0;
            p1 <= 1'b0;
            p2 <= 1'b0;
        end
        else begin
            p0 <= 1'b0;
            p1 <= 1'b0;
            p2 <= 1'b0;
            p3 <= 1'b0;
        end
    end
endmodule

// fibonacci random number generator from https://stackoverflow.com/questions/14497877/how-to-implement-a-pseudo-hardware-random-number-generator
module generator(
    input clk,
    input resetn,
    
    output reg [4:0] data);
    
    reg [4:0] data_next;
    
    always @(*)
    begin
        data_next[4] = data[4]^data[1];
        data_next[3] = data[3]^data[0];
        data_next[2] = data[2]^data_next[4];
        data_next[1] = data[1]^data_next[3];
        data_next[0] = data[0]^data_next[2];
    end
    
    always @(posedge clk)
	 begin
        if (resetn)
            data <= 5'h1f;
        else
            data <= data_next;
	end
endmodule

module counter(
    input clk,
    input [27:0] speed,
    output frame);

    reg [27:0] counter;

    always @(posedge clk)
    begin
        if (counter == 0)
            counter <= speed;
        else
            counter <= counter - 1'b1;
    end

    assign frame = (counter == 0) ? 1 : 0;

endmodule

module display_lives(clk, mode, lives, out);
    input clk, mode;
    input [1:0] lives;
    output reg [2:0] out;
    
    always @(posedge clk)
    begin
        if (~mode) begin
            if (lives == 2'b0)
                out <= 3'b0;
            else if (lives == 2'b01)
                out <= 3'b001;
            else if (lives == 2'b10)
                out <= 3'b011;
            else
                out <= 3'b111;
        end
        else
            out <= 3'b0;
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
