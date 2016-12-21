`timescale 1ns / 1ps

module tb;

reg reset,clk,BTN2;
wire VGA_RED,VGA_GREEN,VGA_BLUE,VGA_HSYNC,VGA_VSYNC;

vga_controller sys0(
	.reset(reset),
	.clk(clk),
	.VGA_RED(VGA_RED),
	.VGA_GREEN(VGA_GREEN),
	.VGA_BLUE(VGA_BLUE),
	.VGA_HSYNC(VGA_HSYNC),
	.VGA_VSYNC(VGA_VSYNC)
);


initial begin
	clk=0;
	reset = 1;				
	#100 reset = 0;
	
	#10000 $finish;	

end
	
always #10 clk = ~ clk;

endmodule
