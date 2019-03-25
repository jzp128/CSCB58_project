module checkInput(
input check_go, clk, key0, key1, key2, key3, 
input [2:0]row_4, 
output reg check_done, hit_or_miss);

always @(posedge clock)
begin
if (!check_go)
begin
	hit <= 1'b0;
	miss <= 1'b0;
	check_done <= 1'b0;
end
else begin
	case(row_4)
		3'b000: begin
			hit <= 1'b0;
			miss <= 1'b0;
			check_done <= 1'b1;
		end
		3'b001: begin
			if (key3 == 1b0) begin
				hit <= 1'b1;
				miss <= 1'b0;
				check_done <= 1'b1;
				end
			else if (key2 == 1'b0 | key1 == 1'b0 | key0 == 1'b0) begin
				hit <= 1'b0;
				miss <= 1'b1;
				check_done <= 1'b1;
				end
			else
				check_done <= 1'b1;
		end
		3'b010: begin
			if (key2 == 1b0) begin
				hit <= 1'b1;
				miss <= 1'b0;
				check_done <= 1'b1;
				end
			else if (key3 == 1'b0 | key1 == 1'b0 | key0 == 1'b0) begin
				hit <= 1'b0;
				miss <= 1'b1;
				check_done <= 1'b1;
				end
			else
				check_done <= 1'b1;
		end
		3'b011: begin
			if (key1 == 1b0) begin
				hit <= 1'b1;
				miss <= 1'b0;
				check_done <= 1'b1;
				end
			else if (key3 == 1'b0 | key2 == 1'b0 | key0 == 1'b0) begin
				hit <= 1'b0;
				miss <= 1'b1;
				check_done <= 1'b1;
				end
			else
				check_done <= 1'b1;
		end
		3'b100: begin
			if (key0 == 1b0) begin
				hit <= 1'b1;
				miss <= 1'b0;
				check_done <= 1'b1;
				end				hit_or_miss <= 1'b0;
			else if (key3 == 1'b0 | key2 == 1'b0 | key1 == 1'b0) begin
				hit <= 1'b0;
				miss <= 1'b1;
				check_done <= 1'b1;
				end
			else
				check_done <= 1'b1;
		end
		default: begin
				hit <= 1'b0;
				miss <= 1'b0;
				check_done <= 1'b1;
		end
	endcase
end

endmodule
