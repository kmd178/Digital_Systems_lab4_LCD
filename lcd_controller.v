`timescale 1ns / 1ps
module lcd_controller(
		input clk,
		input reset,
		output SF_D_8, //Although the LCD supports an 8-bit data interface, the Starter Kit board uses a 
		output SF_D_9,	//4-bit data interface to remain compatible with other Xilinx development boards and to minimize total pin count.
		output SF_D_10,	
		output SF_D_11,
			
		output LCD_E, //Read&Write Enable Pulse 0: Disabled  
						//                          1: Read/Write operation enabled
		output LCD_RS, //Register Select         0: Instruction register during write operations. Busy Flash during read operations  
						//							       1: Data for read or write operations.  In current immplementation only used when writing special characters to CGRAM
		output LCD_RW //Read/Write Control      0: WRITE, LCD accepts data
						//									 1: READ, LCD presents data
    );
					//first executed command
	 reg [9:0] command_10bit=10'b1111111111; //LCDRS, LCDRW , DB7 , DB6 , DB5 , DB4 , DB3 , DB2 , DB1 , DB0
	 //assign {SF_D_8,SF_D_9,SF_D_10,SF_D_11}=bus_4bits;
	 reg [5:0] command_counter=0;
	 
	 sync_10bit_interface kmd(clk, reset, command_10bit ,{SF_D_8,SF_D_9,SF_D_10,SF_D_11}, LCD_RS, LCD_RW, LCD_E, next_command_signal);
	 
	 always @(posedge next_command_signal)
		begin
			case (command_counter)
				0: command_10bit=10'b1110000111;  //second executed command
				1:	command_10bit=10'b0000000001;
				2: command_10bit=10'b0000000010;
				3: command_10bit=10'b0000000100;
				4: command_10bit=10'b0000001000;
				5: command_10bit=10'b0000010000;
				6: command_10bit=10'b0000100000;
				7: command_10bit=10'b0001000000;
				8: command_10bit=10'b0010000000;
				9: command_10bit=10'b0100000000;
				10:command_10bit=10'b1000000000;
				//////// repeating the display commands only. Commands 0-5 are used for initialization of the display that only needs to be accessed upon reactivation of the device
				11: command_counter=1;
			endcase
			command_counter=command_counter+1;
		end
endmodule 
//Power-On Initialization
//	The initialization sequence first establishes that the FPGA application wishes to use the 
//	four-bit data interface to the LCD as follows:
//		WAIT 750.000 CLOCKS,  EVERYTHING ZERO OR DOESNT MATTER
//	//	DATA=0x03 for 15clocks &  LCD_E=1; FOR 12CLOCKS THEN LOW
//		WAIT 205.000 CLOCKS,  EVERYTHING ZERO OR DOESNT MATTER  955.000
//	//	DATA=0x03 for 15clocks &  LCD_E=1; FOR 12CLOCKS THEN LOW
//		WAIT   5.000 CLOCKS,  EVERYTHING ZERO OR DOESNT MATTER  960.000
//	//	DATA=0x03 for 15clocks &  LCD_E=1; FOR 12CLOCKS THEN LOW
//		WAIT   2.000 CLOCKS,  EVERYTHING ZERO OR DOESNT MATTER  962.000
//	//	DATA=0x02 for 15clocks &  LCD_E=1; FOR 12CLOCKS THEN LOW
//		WAIT   2.000 CLOCKS,  EVERYTHING ZERO OR DOESNT MATTER  964.000
//	 
//Function Set
//	Sets interface data length, number of display lines, and character font. 
//	The Starter Kit board supports a single function set with value 0x28.
//	Execution Time: 40탎 	//00001010--  -> 0000101000   //0x28 
//
//Entry Mode Set 
//	Sets the cursor move direction and specifies whether or not to shift the display. 
//	These operations are performed during data reads and writes.
//	Execution Time: 40탎  	//00000001--  -> 0000000110   //0x06 prosdiorizonas oti o elekths afksanei aftomata thn diefthinsh
//		Bit DB1: (I/D) Increment/Decrement
//			0 Auto-decrement address counter. Cursor/blink moves to left.
//			1 Auto-increment address counter. Cursor/blink moves to right.
//				This bit either auto-increments or auto-decrements the DD RAM and CG RAM address 
//				counter by one location after each 
//				Write Data to CG RAM or DD RAM or Read Data from CG RAM or DD RAM  command. The cursor or blink position moves accordingly.
//		Bit DB0: (S) Shift
//			0 Shifting disable
//			1	During a DD RAM write operation, shift th	e entire display value in the direction 
//			controlled by Bit DB1 (I/D). Appears as though the cursor position remains constant and the display moves.
//			
//			
//Display On/Off
//	Display is turned on or off, controlling all characters, cursor and cursor position character 
//	(underscore) blink.
//	Execution Time: 40탎 	//0000001---  -> 0000001100  //0x0C energopoiontas thn endiksh kai svinontas ton aftomato dromea
//		Bit DB2: (D) Display On/Off
//			0No characters displayed. However, data stored in DD RAM is retained
//			1Display characters stored in DD RAM	
//		Bit DB1: (C) Cursor On/Off
//			0No cursor
//			1Display curs
//			The cursor uses the five dots on the bottom line of the character. The cursor appears as a 
//			line under the displayed character.
//		Bit DB0: (B) Cursor Blink On/Off
//			0No cursor blinking
//			1Cursor blinks on and off approximately every half second
//			
//
//Clear Display
//		Clear the display and return the cursor to the home position, the top-left corner.
//		This command writes a blank space (ASCII/ANSI character code 0x20) into all DD RAM 
//		addresses. The address counter is reset to 0, location 0x00 in DD RAM. Clears all option 
//		settings. The I/D control bit is set to 1 (increment address counter mode) in the Entry Mode Set command.
//		Execution Time: 82탎 - 1.64 ms = 82.000 cycles  //0000000001  //0x01..  and wait 82.000cycles
			