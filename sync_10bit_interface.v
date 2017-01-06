`timescale 1ns / 1ps
module sync_10bit_interface(
		input clk,
		input reset,
		input [10:0] UNMODULATED_DATA,
		output reg [3:0] MODULATED_DATA,
		output reg LCD_RS,  
		output reg LCD_RW,
		output reg LCD_E,
		output reg next_command
		);
	
	parameter	DATA_INACTIVE				= 2'b00,
					DATA_INITIALIZATION 		= 2'b01,
					ENABLE_MODULATION_START	= 2'b10;
				//	ENABLE_MODULATION_END	= 2'b11;
		
	always @(reset)
		LCD_RW = 0;				
	 //Display permanently accepts data in write mode. The LCD_RW signal can be tied Low permanently because the FPGA generally has no reason to read information from the display
	reg [1:0] CurrentState;
	reg [1:0] NextState;
	//40ns=0;   		//2clk			//DATA_INITIALIZATION
	//280ns=0;  		//14clk			//ENABLE_MODULATION_START
	//300ns=0;  		//15clk			//ENABLE_MODULATION_END
	//1280ns=0;  		//64clk		 	//DATA_INACTIVE       (transmision of the next 4bits)
	//40280ns=0;		//2014clk 		//DATA_INACTIVE       (transmision of the next command)
	//15000000ns=0;	//750000clk 	//DATA_INACTIVE       (transmision of the next command)
	reg [20:0] 	clock_counter=0;
	reg reset_counter;
	reg [1:0] waitingtime=2;	//0:Waiting time=1us  		(transmision of the next 4bits)
										//1:Waiting time=40us 		(transmision of the next command)
										//2:Waiting time=15000us 	(display activation time)
					

////////////////////////////////////////// FSM
	always @(posedge clk, posedge reset)
			if (reset)
				CurrentState <= DATA_INACTIVE;
			else 
				CurrentState <= NextState;
				
////////////////////////////////////////// clock_counter
	always @(posedge clk, posedge reset)
			if (reset)
				clock_counter<=0;
			else if (reset_counter==1) 
				clock_counter<=0;
			else 
				clock_counter<=clock_counter+1'b1;	
	
////////////////////////////////////////// Signal modulation
	always @(posedge clk,posedge reset)
		begin
			if(reset) 
				begin
								LCD_E<=0;
								LCD_RS<=0;				
								MODULATED_DATA<= 0;		
								reset_counter<=0;								
								NextState<= DATA_INACTIVE;
								next_command<=0;
								waitingtime<=2;//Display activation time of 15000microseconds (waiting time before senting any commands on the interface)
								//Spartan3E Manual recomendation:	//Wait 15 ms or longer, although the display is generally ready when the FPGA finishes configuration. 
																				//The 15 ms interval is 750,000 clock cycles at 50 MHz.
				end
			else
				begin
								case (CurrentState)
									DATA_INACTIVE:
										begin 
												if(UNMODULATED_DATA[10]==0 & waitingtime!=3 & NextState!=DATA_INITIALIZATION)
														waitingtime=3;
												else if(clock_counter+1==82000 & waitingtime==3 & NextState!=DATA_INITIALIZATION)
													begin
														NextState<= DATA_INITIALIZATION;
														reset_counter<=1; 
														waitingtime<=1;
														next_command<=1;
													end	
												else if(clock_counter+1==63 & waitingtime==0 & NextState!=DATA_INITIALIZATION) 
													begin
														NextState<= DATA_INITIALIZATION;	
														reset_counter<=1; 
														waitingtime<=0;
													end
												else if(clock_counter+1==2013 & waitingtime==1 & NextState!=DATA_INITIALIZATION) 
													begin 
														next_command<=1;
														NextState<= DATA_INITIALIZATION;
														reset_counter<=1;
														waitingtime<=1;
													end
												else if(clock_counter+1>=750000 & clock_counter+1<=750000+12 & waitingtime==2)
													begin 
														LCD_E<=1;
														MODULATED_DATA<=3;
													end
												else if(clock_counter+1>=955012 & clock_counter+1<=955012+12 & waitingtime==2)
													begin 
														LCD_E<=1;
														MODULATED_DATA<=3;
													end												
												else if(clock_counter+1>=960024 & clock_counter+1<=960024+12 & waitingtime==2)
													begin 
														LCD_E<=1;
														MODULATED_DATA<=3;
													end												
												else if(clock_counter+1>=962036 & clock_counter+1<=962036+12 & waitingtime==2)
													begin 
														LCD_E<=1;
														MODULATED_DATA<=2;
													end																					
												else if(clock_counter+1==964048 & waitingtime==2)
													begin
														NextState<= DATA_INITIALIZATION;
														reset_counter<=1; 
														waitingtime<=1;
													end
												else
													begin
														next_command<=0;
														LCD_E<=0;
														LCD_RS<=0;
														MODULATED_DATA<= 0;
														reset_counter<=0;
													end

										end
									DATA_INITIALIZATION:
										begin
												LCD_E<=0;
												LCD_RS<=UNMODULATED_DATA[9];
												if(clock_counter+1==1)	
													NextState<= ENABLE_MODULATION_START;
												if (waitingtime==0 & NextState!=ENABLE_MODULATION_START) 
														begin		
																waitingtime<= 1; 
																MODULATED_DATA<=UNMODULATED_DATA[3:0];
														end
												else if (waitingtime==1 & NextState!=ENABLE_MODULATION_START) 
														begin
																waitingtime<= 0;
																MODULATED_DATA<=UNMODULATED_DATA[7:4];
														end
										end
									ENABLE_MODULATION_START:
										begin
													LCD_RS<=UNMODULATED_DATA[9];
													if(clock_counter+1==14) 
														NextState<= DATA_INACTIVE;
													else if(NextState<= DATA_INACTIVE)
															LCD_E<=0;
													else
															LCD_E<=1;
										end
									default:
										begin  //reset state
											next_command<=0;
											LCD_E<=0;
											LCD_RS<=0;				
											MODULATED_DATA<= 0;		
											reset_counter<=0;								
											NextState<= DATA_INACTIVE;
											waitingtime<=2;
										end
									
								endcase
			end
	end
endmodule
