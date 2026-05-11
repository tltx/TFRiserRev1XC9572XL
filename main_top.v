
`timescale 1ns / 1ps
/*
    Copyright (C) 2020, Stephen J. Leary & Arek Makarenko
    All rights reserved.
    
    This file is part of CD32 USB Riser

    CD32 USB Riser is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or
    (at your option) any later version.     
    
    You should have received a copy of the GNU General Public License
    along with CD32 USB Riser. If not, see <http://www.gnu.org/licenses/>.
*/





module main_top(
	
	//CPU
    input CLKCPU_A, 
    input AS20, 
    input DS20, 
    input RW, 
    input [23:0] A,
    
    inout [31:24] D,
    output [1:0] DSACK,

    // Punting... 
    input PUNT_IN, 
    output PUNT_OUT,
	 
	 //
	 output INTSIG1, //RTC Interrupt line
	 output INTSIG2, //Buttons Interrupt
	 output INTSIG3, //  A3 line
	 output INTSIG4, //Clockport interrupt
	 output INTSIG5, //A5 line
	 input INTSIG6, //Enable Mouse and Joystick port override
	 input INTSIG7, // STM32 ready - cpu release signal
	 output INTSIG8, // JOY registeres interrupt and Direct Address

    // SPI COMMS Not used - might be reused

    input SPI_CK,   // not used 
    input SPI_MOSI, //not used
    output SPI_MISO //not used

);

wire rtc_decode = A[23:8] == 16'b1101_1100_0000_0000; //RTC registers at $DC0000 - $DC00FF,
wire clockport = A[23:16] ==  16'b1101_1000;  //D80000 to $D8FFFF - clockport addresses
wire JOYDATA = A[23:3] == {20'hDFF00, 1'b1};
wire JOYTEST = A[23:1] == {23'hDFF03, 3'b011};  

wire POTGOR_decode = A[23:1] == {20'hDFF01, 3'b011}; // POTGOR DFF016 
wire POTGO_decode = A[23:1] == {20'hDFF03, 3'b010};  // POTGO DFF034

wire CIAAPRA_decode = A[23:8] == {20'hBFE0}; // CIAAPRA BFE001  
wire CIAADRA_decode = A[23:0] == {24'hBFE201}; // CIAADDRA BFE201

// Direct access window widened from a single byte ($BA0006) to a 64-byte
// region ($BA0000..$BA003F).  The STM32 can only distinguish A[5:0] of the
// triggering address (PC4/PC6/PC7/PA10/PA15/PC9 are the only address bits
// routed to it), so 64 bytes is the maximum useful range. The existing
// $BA0006 mouse-sensitivity register is preserved -- it still falls within
// the new window and the firmware's case 0x06 still handles it.
//
// This makes the firmware's previously-unreachable registers in the $BA-page
// (gamepad map, live USB-button state, per-port device type) actually
// addressable from the Amiga bus.
wire Direct_Access = A[23:6] == 18'h2E800; // $BA0000..$BA003F  (= 0xBA0000 >> 6)

wire enable = INTSIG6 == 1'b1;		//Enable ports override


wire punt_int = clockport | rtc_decode | Direct_Access |( (JOYDATA|JOYTEST|POTGOR_decode|POTGO_decode|CIAAPRA_decode|CIAADRA_decode)&enable );

reg rtc_int;
reg da_int;
reg joy_int;
reg button_int;
reg clockport_int;

reg[1:0] intsig_int;
reg punt_ok;

reg[1:0] ack;
reg actual_acknowledge = 0;



always @(posedge CLKCPU_A) begin 

	punt_ok <= PUNT_IN & punt_int;
		
// Wait for Address Strobe to rise interrupt.
	if (AS20 == 1'b0) begin
		da_int <= PUNT_IN & Direct_Access;
		rtc_int <= PUNT_IN & rtc_decode;
		joy_int <= PUNT_IN & (JOYDATA|CIAADRA_decode);
		button_int <= PUNT_IN & (POTGOR_decode|POTGO_decode|CIAAPRA_decode|JOYTEST);
		clockport_int <= PUNT_IN & clockport;
	end else begin 
		da_int <= 1'b0;
		rtc_int <= 1'b0;
		joy_int <= 1'b0;
		button_int <= 1'b0;
		clockport_int <= 1'b0;
	end
	
	
	//Release CPU only on INTSIG edge change.
	actual_acknowledge <= ack == 2'b01;  
   ack <= {ack[0], INTSIG7};
  
end


// Insert waitstates for punt_int addresses and release it on raising edge of INTSIG7
always @(posedge CLKCPU_A or posedge AS20) begin 
	if (AS20 == 1'b1) begin 
		intsig_int <= 2'b11;
	end else begin 
			if ( actual_acknowledge ) begin
				intsig_int <= 2'b10;
			end else begin
				intsig_int <= 2'b11; 
			end	
	end
end 




// punt works by respecting the accelerator punt over our punt.
assign PUNT_OUT = PUNT_IN ? ( punt_int ? 1'b0 : 1'bz) : 1'b0;


//STM32 Interrupts.
assign INTSIG1 = rtc_int;
assign INTSIG2 = button_int&enable;
assign INTSIG8 = da_int | (joy_int&enable);  
assign INTSIG4 = clockport_int; 


//Waitstates
assign DSACK = punt_ok?intsig_int:2'bzz ;
 
//Missing Address lines on STM32
assign INTSIG3 = A[3];
assign INTSIG5 = A[5];

endmodule