`timescale 1ns / 1ps

module tb;

reg reset,clk;

lcd_controller sys0(
	.clk(clk),
	.reset(reset),
	.SF_D_8(SF_D_8),
	.SF_D_9(SF_D_9),
	.SF_D_10(SF_D_10),
	.SF_D_11(SF_D_11),
	.LCD_E(LCD_E),
	.LCD_RS(LCD_RS),
	.LCD_RW(LCD_RW)
);


initial begin
	clk=0;
	reset = 1;				
	#100 reset = 0;
	
	//#10000 $finish;	

end
	
always #10 clk = ~ clk;

endmodule
