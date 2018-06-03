module mbc5(
	 //GB data and latch pins
	 input [7:0]  gb_data,
	 input        gb_write_n,

	 //GB rst
	 input        rst_n,

	 //ROM chip select
	 input        cs_n,

	 //Upper address bits from GB
	 input        addr_15,
	 input        addr_14,
	 input        addr_13,
   input        addr_12,

	 //ROM Mapped Upper address bits
   output [8:0] rom_addr,

	 //Extended address bits
   output [3:0] ram_addr,

	 //RAM chip select
	 output       ram_cs_n,
    );

   //MBC Logic
   //Ram enable & logic
   reg         RAM_enable;
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
   reg [8:0] ROM_bank;
   //Lower 8 bits
   assign ROM_bank_lower_wr_en = {addr_15, addr_14, addr_13} == 3'b001 & ~gb_write_n;
   always@(negedge ROM_bank_lower_wr_en) begin
      if (~rst_n) begin
         ROM_bank[7:0] <= 8'h00;
      end else begin
         ROM_bank[7:0] <= gb_data[7:0];
      end
   end

   //Upper bit
   assign ROM_bank_upper_wr_en = {addr_15, addr_14, addr_13, addr_12} == 4'b0011 & ~gb_write_n;
   always@(negedge ROM_bank_upper_wr_en) begin
	    if (~rst_n) begin
	       ROM_bank[8] <= 1'b0;
	    end else begin
	       ROM_bank[8] <= gb_data[0];
	    end
   end

   //Ram bank enable & logic
   reg [3:0] RAM_bank;
   assign RAM_bank_wr_en = {addr_15, addr_14} == 2'b01 & ~gb_write_n;
   always@(negedge RAM_bank_wr_en) begin
	    if (~rst_n) begin
	       RAM_bank <= 4'h0;
	    end else begin
	       RAM_bank <= gb_data[3:0];
	    end
   end

   //Mode select (either RAM or ROM mode)
   reg rom_mode;
   assign rom_mode_wr_en = {addr_15, addr_14, addr_13} == 3'b011 & ~gb_write_n;
   always@(negedge rom_mode_wr_en) begin
      if (~rst_n) begin
		     rom_mode <= 1'b0;
	    end else begin
	       rom_mode <= gb_data[0];
	    end
   end

   assign ram_addr[0] = ROM_bank[0] & addr_14;
   assign ram_addr[1] = ROM_bank[1] & addr_14;
   assign ram_addr[2] = ROM_bank[2] & addr_14;
   assign ram_addr[3] = ROM_bank[3] & addr_14;
   assign ram_addr[4] = ROM_bank[4] & addr_14;
   assign ram_addr[5] = ROM_bank[5] & addr_14;
   assign ram_addr[6] = ROM_bank[6] & addr_14;
   assign ram_addr[7] = ROM_bank[7] & addr_14;
   assign ram_addr[8] = ROM_bank[8] & addr_14;

   assign rom_addr[0] = RAM_bank[0];
   assign rom_addr[1] = RAM_bank[1];
	 assign rom_addr[2] = RAM_bank[2];
	 assign rom_addr[3] = RAM_bank[3];

   assign ram_cs_n = ~RAM_enable | cs_n;

endmodule
