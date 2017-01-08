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
	
	 reg LCD_E_on=1;				  //LCD_E
	 reg LCD_RS_on=1;				  //LCD_RS
	 //reg LCD_RW_on=0;			  //Not necessary. Only write mode is used. LCD_RW=0;
	 wire [7:0] BRAM_OUTPUT; // DB7 , DB6 , DB5 , DB4 , DB3 , DB2 , DB1 , DB0
	
	
	 reg [5:0] command_counter=0;
	 reg [1:0] refresh_counter=0;
	
	 sync_10bit_interface kmd(clk, reset, {LCD_E_on , LCD_RS_on, 1'b0 , BRAM_OUTPUT} ,{SF_D_8,SF_D_9,SF_D_10,SF_D_11}, LCD_RS, LCD_RW, LCD_E, next_command_signal);
	  
	 BRAM_instructions bram(clk, {5'b00000,command_counter} , 1'b1 , BRAM_OUTPUT); //BRAM instances:  Utilizing the bulk memory necessary for storing the commands.
																					//----- out of the 16383 bits provided by a  the 2Kx8bit preconfigured BRAM blocks
	 	 

	 always @(posedge next_command_signal, posedge reset)
		if (reset)
			command_counter=0;
		else if(command_counter==53)
			command_counter=command_counter+1+refresh_counter;
		else if(command_counter==54 | command_counter==55 | command_counter==56)
			command_counter=58;
		else if(command_counter==58)
			command_counter=21; //last command-1
		else
			command_counter=command_counter+1;
			

	 always @(posedge next_command_signal, posedge reset)
		if (reset)
			begin  
			   refresh_counter=0;	
				LCD_E_on=1;			
				LCD_RS_on=0;			
					
			end
		else	
				begin
					case (command_counter)
						4: begin  //Clear Display function
							LCD_E_on=0;   //large waiting time ->  1.64ms. sync_10bit_interface module is designed to implement the waiting time of the Clear Display function in its FSM
							end
						6: LCD_RS_on=1;
						7: LCD_RS_on=0;
						8: LCD_RS_on=1;
						13: LCD_RS_on=0;
						14: LCD_RS_on=1;
						15: LCD_RS_on=0;
						16: LCD_RS_on=1;
						21: begin
								LCD_RS_on=0;
								LCD_E_on=1;
							 end
						22: LCD_RS_on=1;
						38: LCD_RS_on=0;
						39: LCD_RS_on=1;
						58: begin 
								refresh_counter=refresh_counter+1;
								LCD_RS_on=1; //invalid instruction input to sync_10bit_interface {signals the 1second interval of the LED's refresh}
								LCD_E_on=0;  //invalid instruction input to sync_10bit_interface {signals the 1second interval of the LED's refresh}
							end
						//////// repeating the display commands only. Commands 1-4 are used for initialization of the display that only needs to be accessed upon reactivation of the device
						default:  LCD_E_on=1;
														
					endcase

					  ///IT IS NOT ACCESED IF ITS ASSIGNED INSIDE THE CASE STATEMENT
				end
endmodule 
//0:Function Set    		0000101000 		0x28
//1:Entry Mode Set  		0000000110 		0x06
//2:Display On/Off  		0000001100 		0x0C
//3:Clear Display   		0000000001 		0x01
//4: -Blank-        		0000000000 		0x00		Wait 1,64ms 

//5: CGRAM SET  ADRESS  0001 000 001  	0x41	{rs,rw,7,6,5,4,3,2,1,0} //Implemented on the hypothesys that every WRITE CHAR will iterate CGRAM Memory address by 1 (meaning next row on the 5x8bitmap)    
//6: INSERT " ^ " 	   1000011111		0x1F

//7: CGRAM SET  ADRESS  0001 001 001  0x49    
//8: INSERT  "  |"  		1000010000		0x10
//9: INSERT  "  |"  		1000010000		0x10
//10: INSERT "  |"  		1000010000		0x10
//11: INSERT "  |"  		1000010000		0x10
//12: INSERT "  |"  		1000010000		0x10

//13: CGRAM SET  ADRESS 0001 010 110  0x56     
//14: INSERT " _ " 		1000011111		0x1F

//15: CGRAM SET  ADRESS 0001 011 001  0x59
//16: INSERT "|  "  		1000000001		0x01
//17: INSERT "|  "  		1000000001		0x01
//18: INSERT "|  "  		1000000001		0x01
//19: INSERT "|  "  		1000000001		0x01
//20: INSERT "|  "  		1000000001		0x01

//21: DDRAM SET  ADRESS 001 0000000 {rs,rw,7,6,5,4,3,2,1,0} rs=0 0x80
//...
//22-37: WRITE CHAR ON THE SPECIFIED ADRESS (+ITERATION)   	rs=1 0x41 until 0x50
//...
//38: DDRAM SET  ADRESS 001 011111 {rs,rw,7,6,5,4,3,2,1,0}  rs=0 0xC0
//...
//39-53: WRITE CHAR ON THE SPECIFIED ADRESS (+ITERATION)    rs=1 0x61 until 0x6F
//...
//54-57: WRITE CHAR  (rotationally every 1 second loop)   rs=1 0x00 or 0x01 or 0x02 or 0x03 
//58: -Blank-     00000000  Wait 1 second and repeat from 10th command



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
//		Execution Time: 82탎 - 1.64 ms = 82.000 cycles  //0000000001  //0x01..  and wait 82.000cycles\
//

