module mbc1(
	 //GB data and latch pins
	 input [4:0] gb_data,
	 input       gb_write_n,
	 input       gb_read_n,

	 //GB rst
	 input       rst_n,

	 //ROM chip select
	 input       cs_n,

	 //Upper address bits from GB
	 input       addr_15,
	 input       addr_14,
	 input       addr_13,

	 //ROM Mapped Upper address bits
	 output      m0,
	 output      m1,
	 output      m2,
	 output      m3,
	 output      m4,

	 //Extended address bits
	 output      ea0,
	 output      ea1,

	 //Chip selects
	 output      ram_cs,
	 output      ram_cs_n,
	 output      rom_cs_n
    );

   //MBC Logic
   //Ram enable & logic
   reg    RAM_enable;
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
