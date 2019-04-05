module top(CLOCK_50, KEY, select_signal, play_in, GPIO, LEDR, LEDG, done_playing);
    input CLOCK_50;
    input [3:0] KEY;
	 input [2:0] select_signal;
	 input play_in;
    output [9:0] GPIO;
    output [16:0] LEDR;
    output reg LEDG;
	 output done_playing;

   
    wire divided_clk;
    rate_divider2 my_rate_divider(CLOCK_50, divided_clk);
   
    wire [16:0] ledr_driver;
    assign LEDR[16:0] = ledr_driver[16:0];
   
    player my_player(.clk(CLOCK_50),
                          .tempo(divided_clk),
                          .selector(select_signal[2:0]),
								  .play_input(play_in),
                          .speaker_out(GPIO[0]),
                          .LEDR(ledr_driver[16:0]),
								  .empty_sheet(done_playing));
   
    always @(posedge divided_clk)
    begin
        LEDG <= ~LEDG;
    end
 
endmodule
 
 
 
module player(
  input clk,
  input tempo,
  input [2:0] selector,
  input play_input,
  output reg [16:0] LEDR,
  output speaker_out,
  output empty_sheet
); 
    parameter f_A3 = 50000000/880;
    parameter f_As3 = 50000000/932;
    parameter f_B3 = 50000000/988;
    parameter f_C3 = 50000000/523;
    parameter f_Cs3 =50000000/554;
    parameter f_D3 = 50000000/587;
    parameter f_Ds3 = 50000000/622;
    parameter f_E3 = 50000000/659;
    parameter f_F3 = 50000000/698.5;
    parameter f_Fs3 = 50000000/740;
    parameter f_G3 = 50000000/784;
    parameter f_Gs3 = 50000000/830;
   
    parameter f_A2 = 50000000/440;
    parameter f_As2 = 50000000/466;
    parameter f_B2 = 50000000/494;
    parameter f_C2 = 50000000/261.5;
    parameter f_Cs2 =50000000/277;
    parameter f_D2 = 50000000/293.5;
    parameter f_Ds2 = 50000000/311;
    parameter f_E2 = 50000000/329.5;
    parameter f_F2 = 50000000/349;
    parameter f_Fs2 = 50000000/367;
    parameter f_G2 = 50000000/392;
    parameter f_Gs2 = 50000000/415;
   
    parameter REST = 6'b0;
    parameter A2 = 6'd1;
    parameter As2 = 6'd2;
    parameter B2 = 6'd3;
    parameter C2 = 6'd4;
    parameter Cs2 = 6'd5;
    parameter D2 = 6'd6;
    parameter Ds2 = 6'd7;
    parameter E2 = 6'd8;
    parameter F2 = 6'd9;
    parameter Fs2 = 6'd10;
    parameter G2 = 6'd11;
    parameter Gs2 = 6'd12;
   
    parameter A3 = 6'd13;
    parameter As3 = 6'd14;
    parameter B3 = 6'd15;
    parameter C3 = 6'd16;
    parameter Cs3 = 6'd17;
    parameter D3 = 6'd18;
    parameter Ds3 = 6'd19;
    parameter E3 = 6'd20;
    parameter F3 = 6'd21;
    parameter Fs3 = 6'd22;
    parameter G3 = 6'd23;
    parameter Gs3 = 6'd24;
   
    reg muted = 1'b1;
    reg [21:0] freq;
    reg [200:0] mary = {C3, D3, E3, D3, D3, E3, E3, E3, E3, D3, C3, D3, E3, G3, G3, E3, E3, REST, D3, D3, D3, REST, E3, E3, E3, D3, C3, D3, E3, REST, REST, REST, REST};
    reg [1000:0] mario = {REST, B2, B2, D3, C3, E3, E3, REST, G3, F3, A3, A3, G3, E3, G2, G2, A2, A2, Cs3, B2, B2, A2, A2, REST, E2, E2, REST, G2, G2, REST, C3, C3,
                                        REST, B2, B2, D3, C3, E3, E3, REST, G3, F3, A3, A3, G3, E3, G2, G2, A2, A2, Cs3, B2, B2, A2, A2, REST, E2, E2, REST, G2, G2, REST, C3, C3,
                                        REST, REST, G2, G2, REST, REST, G3, G3, E3, E3, C3, REST, E3, REST, E3, E3, REST, REST, REST, REST};
    reg [1000:0] abc = {C3, C3, REST, D3, REST, D3, REST, E3, REST, E3, REST, F3, REST, F3, REST, REST, G3, G3, REST, A3, REST, A3, REST, G3, REST, G3, REST, C3, REST, C3, REST, REST, D3, D3, REST, E3, REST, E3, REST, F3, REST, F3, REST, G3, REST, G3, REST, REST, D3, D3, REST, E3, REST, E3, REST, F3, REST, F3, REST, G3, REST, G3, REST, REST, C3, C3, REST,D3, REST, D3, REST, E3, REST, E3, REST, F3, REST, F3, REST, REST, G3, G3, REST, A3, REST, A3, REST, G3, REST, G3, REST, C3, REST, C3, REST, REST, REST};
    reg [1000:0] ode = {C3, C3, REST, C3, REST, D3, REST, E3, REST, D3, REST, C3, REST, C3, REST, D3, REST, E3, REST, F3, REST, G3, REST, G3, REST, F3, REST, E3, REST, E3, REST, REST, G2, REST, D3, REST, C3, REST, D3, REST, E3, F3, E3, REST, D3, REST, C3, REST, E3, F3, E3, REST, D3, REST, C3, REST, E3, REST, REST, D3, D3, REST, REST, C3, C3, REST, C3, REST, D3, REST, E3, REST, D3, REST, C3, REST, C3, REST, D3, REST, E3, REST, F3, REST, G3, REST, G3, REST, F3, REST, E3, REST, E3, REST, REST, D3, D3, REST, D3, REST, E3, REST, E3, REST, D3, REST, C3, REST, C3, REST, D3, REST, E3, REST, F3, REST, G3, REST, G3, REST, F3, REST, E3, REST, E3, REST, REST, REST};
    reg [1000:0] hot_cross_buns = {C3, C3, D3, D3, E3, E3, REST, D3, REST, D3, REST, D3, REST, D3, REST, C3, REST, C3, REST, C3, REST, C3, REST, REST, C3, C3, D3, D3, E3, E3, REST, REST, C3, C3, D3, D3, E3, E3};
    reg [1000:0] bingo = {C3, C3, REST, C3, C3, REST, B2, REST, A2, REST, G2, REST, B2, REST, C3, REST, D3, REST, D3, REST, D3, REST, C3, C3, REST, C3, C3, REST, E3, E3,
                                REST, E3, REST, E3, REST, D3, D3, REST, D3, D3, REST, F3, F3, REST, F3, REST, F3, REST, E3, E3, REST, E3, E3, REST, C3, C3, REST, E3, E3, REST, D3,
                                REST, D3, REST, C3, REST, C3, REST, G2, REST, G2, REST, A2, REST, A2, REST, G2, REST, G2, REST, C3, REST, C3, REST, G2, REST, REST, REST};
    reg [1000:0] music_sheet;
	 assign empty_sheet = music_sheet == 1001'd0 ? 1 : 0;
    always @(posedge tempo)
    begin
		if (play_input) begin
        if(selector == 3'd1)
            music_sheet[1000:0] <= hot_cross_buns[1000:0];
        else if(selector == 3'd4)
            music_sheet[1000:0] <= mary[200:0];
        else if(selector == 3'd0)
            music_sheet[1000:0] <= abc[1000:0];
        else if(selector == 3'd5)
            music_sheet[1000:0] <= bingo[1000:0];
        else if (selector == 3'd2)
            music_sheet[1000:0] <= ode[1000:0];
        else if(selector == 3'd3)
            music_sheet[1000:0] <= mario[1000:0];
		end
		else
            music_sheet[1000:0] <= music_sheet[1000:6];
       
        if (music_sheet[5:0] == REST)
            muted <= 1'b1;
        else
        begin
            muted <= 1'b0;
            case(music_sheet[5:0])
                 A2:  freq <= f_A2;
                 As2: freq <= f_As2;
                 B2:  freq <= f_B2;
                 C2:  freq <= f_C2;
                 Cs2: freq <= f_Cs2;
                 D2:  freq <= f_D2;
                 Ds2: freq <= f_Ds2;
                 E2:  freq <= f_E2;
                 F2:  freq <= f_F2;
                 Fs2: freq <= f_Fs2;
                 G2:  freq <= f_G2;
                 Gs2: freq <= f_Gs2;
                 
                 A3:  freq <= f_A3;
                 As3: freq <= f_As3;
                 B3:  freq <= f_B3;
                 C3:  freq <= f_C3;
                 Cs3: freq <= f_Cs3;
                 D3:  freq <= f_D3;
                 Ds3: freq <= f_Ds3;
                 E3:  freq <= f_E3;
                 F3:  freq <= f_F3;
                 Fs3: freq <= f_Fs3;
                 G3:  freq <= f_G3;
                 Gs3: freq <= f_Gs3;                 
                 default: freq <= 22'd0;
            endcase
        end
       
    end
   
    always @(*)
    begin
        LEDR[16:0] <= music_sheet[16:0];
    end
   
    // Frequency Divider
    pitch_maker my_pitch_maker(
      .muted(muted),
      .clk(clk),
      .counter(freq),
      .speaker_out(speaker_out)
    );
 
endmodule
 
module pitch_maker(muted, clk, counter, speaker_out);
    input muted;
    input clk;
    input [21:0] counter;
    output reg speaker_out;
 
    reg [21:0] num;
   
    always@(posedge clk)
    begin
         // end of counter turn off sound
         if(num == counter)
         begin
              speaker_out <= ~speaker_out;
              num <= 22'd0;
         end
         // incredment counter
         else
         begin
              num <= num + 22'b1;
         end
         
         if (muted)
            speaker_out <= ~muted;
    end
 
endmodule
 
 
module rate_divider(clk ,counter_max, out);
    input clk;
    input [31:0] counter_max;
    output out;
    reg [31:0] cd = 0;
   
 
    assign out = (cd == 1) ? 1 : 0;
   
     
    always @ (posedge clk)
    begin
        if (cd == 0)
              cd <= counter_max + 1;
        else
            cd = cd - 1;
    end
 
endmodule
 
module rate_divider2(clkin, clkout);
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
              counter <= 20000000 / 4;
              clkout <= ~clkout;
         end else begin
              counter <= counter -1;
         end
    end
endmodule