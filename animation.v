module PianoTapper(SW,KEY,HEX0, HEX1, HEX2, HEX3, HEX4,HEX5);
input [3:0] KEY;
input [9:0] SW;

// draw the game
drawGame startGame(x1,y1,x2,y2,x3,y3,x4,y4,go,done,clock,plot, RX, RY,colour,ledr, gd,res)

endmodule

module clock(SW, KEY, CLOCK_50, HEX0);
    input [9:0] SW;
    input CLOCK_50;
    
    output [7:0] HEX0;
	 

    wire [3:0] counterout;

    counter myCounter(SW[9], CLOCK_50, SW[1:0], SW[8], counterout);
    hex_display hex0(counterout, HEX0);
	 
endmodule

module counter(enable, clk, freq, clear_b, q);
    input enable, clk, clear_b;
    input [1:0] freq;
    output [3:0] q;

    wire [27:0] w1hzout;drawGame
    wire [27:0] w05hzout;

    wire [27:0] w025hzout;

    ratedivider rd1hz(enable, 28'd49999999, clk, clear_b, w1hzout);
    ratedivider rd05hz(enable, 28'd99999999, clk, clear_b, w05hzout);
    ratedivider rd025hz(enable, 28'd199999999, clk, clear_b, w025hzout);
	 
	 ratedivider rd4hz(enable, 28'd12499999, clk, clear_b, w1hzout);
    reg ratedividerout;
    always @(*)
        begin 
            case(freq)
                2'b00: ratedividerout = enable;
                2'b01: ratedividerout = (w1hzout == 0) ? 1 : 0;
                2'b10: ratedividerout = (w05hzout == 0) ? 1 : 0;
                2'b11: ratedividerout = (w025hzout == 0) ? 1 : 0;
            endcase
        end
    displaycounter myDisplay(ratedividerout, clk, clear_b, q);
endmodule

module ratedivider(enable, load, clk, clear_b, q);
    input enable, clk, clear_b;
    input [27:0] load;
    output reg [27:0] q;

    always @(posedge clk)
         begin
            if (clear_b == 1'b0)
                q <= load;
            else if (q == 0)
                q <= load;
            else if (enable == 1'b1)
                q <= q - 1'b1;
    end
endmodule

module checklane(input [11:0] screenstate,input input currstate, input [7:0] X, input [7:0] Y, output isgood);
	assign good = screenstate[15] || 
	if (currstate == finish)
		X <= 1'b0;
		Y <= 1'b0;
	else if (currstate == draw)
		
		
		
endmodule


module drawGame(x1,y1,x2,y2,x3,y3,x4,y4,go,done,clock,plot, RX, RY,colour,ledr, hex4, hex5, gd,res);
	
	// Declaration of all necessary inputs/outputs including x and y of tiles , 
	//clock, key, different state variables and 
	//outputs such as the hex and leds 
	input [7:0]x1,x2,x3,x4;
	input [7:0]y1,y2,y3,y4;
	input clock;
	input go;
	input res; //key0
	input gd; //gamedone
	output reg done;
	output reg [7:0]RX; // general input of Xs
	output reg [6:0]RY;
	output reg [1:0]colo15 seconds for a touch stimulus.ur;
	output [3:0]ledr;
	output [6:0]hex4;
	output [6:0]hex5;
	output reg plot;
	
	//State parameter that declares the state codes to be used for each state 
	parameter resetS=3'b000,checkS = 3'b111,eraseS= 3'b001,drawS=3'b010,finishS=3'b011, doneS=3'b110;

	//Declaraion of the present and next state variables 
	reg [2:0]present;
	reg [2:0] next;
	
	//TODO: Counter ratedivider rd1hz(enable, 28'd49999999, clk, clear_b, w1hzout);
	
	// used to keep track of which pixel is being drawn of a specfic tile 
	reg [5:0]counterx;
	reg [3:0]countery;
	
	//Counter used to keep track of the erasing of each pixel of a tile 
	reg [5:0] blackx;
	reg [3:0] blacky;

	//Used to search for a specfic tile by gooing through each pixel one by one 
	reg [7:0]sx;
	reg [7:0]sy;
	//State variables used to know which state the FSM is currently on, these varaibles are set in every state 
	reg draw, erase, check, finish, reset, fd, done;
	// Count the number of tiles seen as gone through by Sx and Sy and increments by 1 once one has been found 
	reg [2:0]count;
	//Notifies if a specfic task is done like draw erase and game over 
	reg ed;
	reg dd;
	reg doneover;
	
	always @(*)
	begin gameStates:
		case (present)if (fd)
				next = eraseS;
			else 
			
			resetS:
			if(go)
				next = check;
			else if(gd)
				next = doneS;
			else // general input of Xs
				next = resetS;if (fd)
				next = eraseS;
			else 
			
			checkS:
			if (gd)
				next = finishS;
			else
				next = eraseS;
			
			eraseS:
			if (ed)
				begin
				if ()
					next = drawS;
				else
					next = finishS;
				end
			else 
				next = eraseS;
			
			drawS:
			if (dd)
				next = finishS;
			else 
				next = drawS;
				
			finishS:
			if (gd && res)
				next = resetS;
			else if (gd && !res)
				next = checkS;
			
//			doneS:
//			if (gd)
//				next = doneS;
//			else if (res && gd)
//				next = resetS;
			
			default: next = reset
			
		endcase
		
		// if (check)
			//check other stuff
		
		
		
	
endmodule