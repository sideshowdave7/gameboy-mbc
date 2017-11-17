module mbc1(
    // 50MHz clock input
    input clk,
    // Input from reset button (active low)
    input rst_n,
    // cclk input from AVR, high when AVR is ready
    input cclk,
    // Outputs to the 8 onboard LEDs
    output[7:0]led,
    // AVR SPI connections
    output spi_miso,
    input spi_ss,
    input spi_mosi,
    input spi_sck,
    // AVR ADC channel select
    output [3:0] spi_channel,
    // Serial connections
    input avr_tx, // AVR Tx => FPGA Rx
    output avr_rx, // AVR Rx => FPGA Tx
    input avr_rx_busy, // AVR Rx buffer full
	 
	 //GB data and latch pins
	 input [4:0] gb_data,
	 input gb_write_n,
	 input gb_read_n,
	 
	 //GB rst
	 input gb_rst_n,
	 
	 //ROM chip select
	 input cs_n,
	 
	 //Upper address bits from GB
	 input addr_15,
	 input addr_14,
	 input addr_13,
	 
	 //ROM Mapped Upper address bits
	 output m0,
	 output m1,
	 output m2,
	 output m3,
	 output m4,
	 
	 //Extended address bits
	 output ea0,
	 output ea1,
	 
	 //Chip selects
	 output ram_cs,
	 output ram_cs_n,
	 output rom_cs_n
    );

wire rst = ~rst_n; // make reset active high

// these signals should be high-z when not used
assign spi_miso = 1'bz;
assign avr_rx = 1'bz;
assign spi_channel = 4'bzzzz;

assign led = 8'b0;

//MBC Logic
//Ram enable & logic
reg RAM_enable;
assign RAM_enable_wr_en = {addr_15, addr_14, addr_13} == 3'b000 & ~gb_write_n;
always@(posedge RAM_enable_wr_en) begin
  if (~rst_n) begin
		RAM_enable <= 1'b0;
  end else begin
		if (gb_data[3:0] == 4'hA) begin
			RAM_enable <= 1'b1;
		end else begin
			RAM_enable <= 1'b0;
		end
	end
end

//Rom bank write enable & logic
reg [4:0] ROM_bank;
assign ROM_bank_wr_en = {addr_15, addr_14, addr_13} == 3'b001 & ~gb_write_n;
always@(posedge ROM_bank_wr_en) begin
	if (~rst_n) begin
	    ROM_bank <= 5'h00;
	end else begin
	    ROM_bank <= gb_data[4:0];
	end
end

//Ram bank enable & logic
reg [1:0] RAM_bank;
assign RAM_bank_wr_en = {addr_15, addr_14, addr_13} == 3'b010 & ~gb_write_n;
always@(posedge RAM_bank_wr_en) begin
	if (~rst_n) begin
	    RAM_bank <= 2'h0;
	end else begin
	    RAM_bank <= gb_data[1:0];
	end
end

//Mode select (either RAM or ROM mode)
reg rom_mode;
assign rom_mode_wr_en = {addr_15, addr_14, addr_13} == 3'b011 & ~gb_write_n;
always@(posedge rom_mode_wr_en) begin
    if (~rst_n) begin
		  rom_mode <= 1'b0;
	 end else begin
	     rom_mode <= gb_data[0];
	 end
end

assign m0 = (ROM_bank == 5'h00) | (RAM_bank[0] & ROM_bank == 5'h00) | (RAM_bank[1] & ~RAM_bank[0] & ROM_bank == 5'h00) | ROM_bank[0];
assign m1 = ROM_bank[1];
assign m2 = ROM_bank[2];
assign m3 = ROM_bank[3];
assign m4 = ROM_bank[4];

assign ea0 = (~rom_mode & ~addr_14) ? 1'b0: RAM_bank[0];
assign ea1 = (~rom_mode & ~addr_14) ? 1'b0: RAM_bank[1];

assign ram_cs_n = ~ram_cs;
assign ram_cs = ~cs_n & ~addr_14 & RAM_enable;
assign rom_cs_n = ~((~addr_15 & ~gb_read_n) | ~rst_n);

endmodule