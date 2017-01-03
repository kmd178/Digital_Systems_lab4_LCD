`timescale 1ns / 1ps

module tb;

reg reset,clk;

lcd_controller sys0(
	.reset(reset),
	.clk(clk)
);


initial begin
	clk=0;
	reset = 1;				
	#100 reset = 0;
	
	#10000 $finish;	

end
	
always #10 clk = ~ clk;

endmodule
