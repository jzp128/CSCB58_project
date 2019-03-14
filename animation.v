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
	output reg [1:0]colour;
	output [3:0]ledr;
	output [6:0]hex4;
	output [6:0]hex5;
	output reg plot;
	
	//State parameter that declares the state codes to be used for each state 
	parameter resetS=3'b000,checkS = 3'b111,eraseS= 3'b001,drawS=3'b010,finishS=3'b011, doneS=3'b110;

	//Declaraion of the present and next state variables 
	reg [2:0]present;
	reg [2:0] next;
	
	//TODO: Counter 
	
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
		case (present)
			
			resetS:
			if(go)
				next = check;
			else if(gd)
				next = doneS;
			else
				next = resetS;
			
			checkS:
			if (fd)
				next = eraseS;
			else if (gd)
				next = doneS;
			
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
			
			doneS:
			if (gd)
				next = doneS;
			else if (res && gd)
				next = resetS;
			
			default: next = reset
			
		endcase
		
		
		
	
endmodule