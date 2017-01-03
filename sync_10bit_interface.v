`timescale 1ns / 1ps
module sync_10bit_interface(
		input clk,
		input reset,
		input [9:0] UNMODULATED_DATA,
		output reg MODULATED_DATA,
		output reg LCD_RS,  
		output reg LCD_RW,
		output reg LCD_E,
		output reg counter_40240ns
		);
	
	parameter	DATA_INACTIVE				= 2'b00,
					ENABLE_MODULATION_START	= 2'b01,
					ENABLE_MODULATION_END	= 2'b10,
					DATA_INITIALIZATION 		= 2'b11;
					
	assign LCD_RW=0; //Display permanently accepts data in write mode. The LCD_RW signal can be tied Low permanently because the FPGA generally has no reason to read information from the display
	reg [1:0] CurrentState;
	reg [1:0] NextState;

	reg counter_40ns=0;   		//2clk			//DATA_INITIALIZATION
	reg counter_280ns=0;  		//14clk			//ENABLE_MODULATION_START
	reg counter_300ns=0;  		//15clk			//ENABLE_MODULATION_END
	reg counter_1280ns=0;  		//64clk		 	//DATA_INACTIVE       (transmision of the next 4bits)
	reg counter_40280ns=0;		//2014clk 		//DATA_INACTIVE       (transmision of the next command)
	reg counter_15000000ns=0;	//750000clk 	//DATA_INACTIVE       (transmision of the next command)
	reg [20:0] 	count_clocks=0;
	reg reset_counter;
	reg [1:0] waitingtime=2;	 	//0:Waiting time=1us  (transmision of the next 4bits)
										//1:Waiting time=40us (transmision of the next command)
										//2:Waiting time=15000us (transmision of the next command)
					

	always @(posedge clk, posedge reset)
			if (reset)
				CurrentState <= DATA_INACTIVE;
			else 
				CurrentState <= NextState;
	
	always @(posedge clk,posedge reset)
		begin
			if(reset) 
				begin
							LCD_E<=0;
							LCD_RS<=0;				
							MODULATED_DATA<= 0;				
							NextState<= DATA_INACTIVE;
							reset_counter<=0;
							waitingtime=2; //In the current implementation a display activation time of 15000microseconds before senting any commands on the interface of the display is tested .
							//Spartan3E Manual recomendation:	//Wait 15 ms or longer, although the display is generally ready when the FPGA finishes configuration. 
																			//The 15 ms interval is 750,000 clock cycles at 50 MHz.
				end
			else
				begin
					NextState<=CurrentState; //if i remain in the same state
					case (CurrentState)
					
						DATA_INACTIVE:
							begin 
									LCD_E<=0;
									LCD_RS<=0;
									MODULATED_DATA<= 0;
									if(counter_1280ns & waitingtime==0) 
										begin
											NextState<= DATA_INITIALIZATION;	
											reset_counter<=1; 
										end
									else if(counter_40240ns & waitingtime==1) 
										begin 
											NextState<= DATA_INITIALIZATION;
											reset_counter<=1;
										end
									else if(counter_15000000ns)
										begin
											NextState<= DATA_INITIALIZATION;
											reset_counter<=1; 
										end
							end
						DATA_INITIALIZATION:
							begin
									reset_counter<=0;
									LCD_E<=0;
									LCD_RS<=1;
									if (waitingtime==0)
										begin
											MODULATED_DATA=UNMODULATED_DATA[3:0];
											waitingtime=1;
										end
									if (waitingtime==1)
										begin
											MODULATED_DATA=UNMODULATED_DATA[7:4];
											waitingtime<=0;
										end
									if(counter_40ns) 
										NextState<= ENABLE_MODULATION_START;
							end
						ENABLE_MODULATION_START:
							begin
									LCD_E<=1;
									LCD_RS<=1;
									if(counter_280ns) 
										NextState<= ENABLE_MODULATION_END;
							end	
						ENABLE_MODULATION_END:
							begin
									LCD_E<=0;
									LCD_RS<=1;
									if(counter_300ns) 
										NextState<= DATA_INACTIVE;
							end
					endcase
				end
	end

		
////////////////////////////////////////////////////////////////////////////////////////////
		always @(posedge clk, posedge reset)
			if (reset)
				count_clocks<=0;
			else if (reset_counter==1) 
				count_clocks<=0;
			else 
				count_clocks<=count_clocks+1'b1;	
				
		always @(posedge clk)
			case (count_clocks)
			2:
			begin
				counter_40ns<=1;
				counter_280ns<=0;
				counter_300ns<=0;
				counter_1280ns<=0;  
				counter_40240ns<=0;
				counter_15000000ns<=0;
				end
			14:
			begin
				counter_40ns<=0;
				counter_280ns<=1;
				counter_300ns<=0;
				counter_1280ns<=0;  
				counter_40240ns<=0;
				counter_15000000ns<=0;
				end
			15:
			begin
				counter_40ns<=0;
				counter_280ns<=0;
				counter_300ns<=1;
				counter_1280ns<=0;  
				counter_40240ns<=0;
				counter_15000000ns<=0;
				end
			64:
			begin
				counter_40ns<=0;
				counter_280ns<=0;
				counter_300ns<=0;
				counter_1280ns<=1;  
				counter_40240ns<=0;
				counter_15000000ns<=0;	
				end				
			2014:
			begin
				counter_40ns<=0;
				counter_280ns<=0;
				counter_300ns<=0;
				counter_1280ns<=0;  
				counter_40240ns<=1;
				counter_15000000ns<=0;
				end
			750000:
			begin
				counter_40ns<=0;
				counter_280ns<=0;
				counter_300ns<=0;
				counter_1280ns<=0;  
				counter_40240ns<=0;
				counter_15000000ns<=1;
				end
			default:
			begin
				counter_40ns<=0;
				counter_280ns<=0;
				counter_300ns<=0;
				counter_1280ns<=0;  
				counter_40240ns<=0;
				counter_15000000ns<=0;
				end
			endcase
			
endmodule
