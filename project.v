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


