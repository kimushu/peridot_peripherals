// ===================================================================
// TITLE : PERIDOT-NG / Host bridge including SPI master
//
//   DEGISN : S.OSAFUNE (J-7SYSTEM Works)
//   DATE   : 2015/05/17 -> 2015/05/18
//   UPDATE : 2017/01/29
//
// ===================================================================
// *******************************************************************
//    (C)2015-2017, J-7SYSTEM WORKS LIMITED.  All rights Reserved.
//
// * This module is a free sourcecode and there is NO WARRANTY.
// * No restriction on use. You can use, modify and redistribute it
//   for personal, non-profit or commercial products UNDER YOUR
//   RESPONSIBILITY.
// * Redistributions of source code must retain the above copyright
//   notice.
// *******************************************************************

// reg00(+0)  bit15:irqena(RW), bit9:start(W)/ready(R), bit8:select(RW), bit7-0:txdata(W)/rxdata(R)
// reg01(+4)  bit15:bitrvs(RW), bit13-12:mode(RW), bit7-0:clkdiv(RW)

module peridot_csr_spi #(
	parameter DEFAULT_REG_BITRVS = 0,			// init bitrvs value 0 or 1
	parameter DEFAULT_REG_MODE   = 0,			// init mode value 0-3
	parameter DEFAULT_REG_CLKDIV = 255			// init clkdiv value 0-255 (BitRate[bps] = <csi_clk>[Hz] / ((clkdiv + 1)*2) )
) (
	// Interface: clk
	input			csi_clk,
	input			rsi_reset,

	// Interface: Avalon-MM slave
	input  [0:0]	avs_address,
	input			avs_read,			// read  0-setup,1-wait,0-hold
	output [31:0]	avs_readdata,
	input			avs_write,			// write 0-setup,0-wait,0-hold
	input  [31:0]	avs_writedata,

	// Interface: Avalon-MM Interrupt sender
	output			ins_irq,

	// External Interface
	output			spi_ss_n,
	output			spi_sclk,
	output			spi_mosi,
	input			spi_miso
);


/* ===== 外部変更可能パラメータ ========== */



/* ----- 内部パラメータ ------------------ */

	localparam	STATE_IDLE		= 5'd0,
				STATE_ENTRY		= 5'd1,
				STATE_SDI		= 5'd2,
				STATE_SDO		= 5'd3,
				STATE_DONE		= 5'd31;


/* ※以降のパラメータ宣言は禁止※ */

/* ===== ノード宣言 ====================== */
				/* 内部は全て正論理リセットとする。ここで定義していないノードの使用は禁止 */
	wire			reset_sig = rsi_reset;			// モジュール内部駆動非同期リセット 

				/* 内部は全て正エッジ駆動とする。ここで定義していないクロックノードの使用は禁止 */
	wire			clock_sig = csi_clk;			// モジュール内部駆動クロック 

	reg  [4:0]		state_reg;
	reg  [7:0]		divcount;
	reg  [2:0]		bitcount;
	reg				sclk_reg;
	reg  [7:0]		txbyte_reg, rxbyte_reg;
	wire			sdi_sig;

	reg				bitrvs_reg;
	reg  [1:0]		mode_reg;
	reg  [7:0]		divref_reg;
	reg				irqena_reg;
	reg				ready_reg;
	reg				sso_reg;
	wire [7:0]		txdata_sig, rxdata_sig;


/* ※以降のwire、reg宣言は禁止※ */

/* ===== テスト記述 ============== */



/* ===== モジュール構造記述 ============== */

	///// Avalon-MMインターフェース /////

	assign ins_irq = (irqena_reg)? ready_reg : 1'b0;

	assign avs_readdata =
			(avs_address == 1'd0)? {16'b0, irqena_reg, 5'b0, ready_reg, sso_reg, rxdata_sig} :
			(avs_address == 1'd1)? {16'b0, bitrvs_reg, 1'b0, mode_reg, 4'b0, divref_reg} :
			{32{1'bx}};

	assign txdata_sig = (bitrvs_reg)? {avs_writedata[0], avs_writedata[1], avs_writedata[2], avs_writedata[3], avs_writedata[4], avs_writedata[5], avs_writedata[6], avs_writedata[7]} : avs_writedata[7:0];
	assign rxdata_sig = (bitrvs_reg)? {rxbyte_reg[0], rxbyte_reg[1], rxbyte_reg[2], rxbyte_reg[3], rxbyte_reg[4], rxbyte_reg[5], rxbyte_reg[6], rxbyte_reg[7]} : rxbyte_reg;

	assign spi_ss_n = ~sso_reg;
	assign spi_sclk = sclk_reg;
	assign spi_mosi = txbyte_reg[7];
	assign sdi_sig  = spi_miso;

	always @(posedge clock_sig or posedge reset_sig) begin
		if (reset_sig) begin
			state_reg  <= STATE_IDLE;
			ready_reg  <= 1'b1;
			bitrvs_reg <= DEFAULT_REG_BITRVS[0];
			mode_reg   <= DEFAULT_REG_MODE[1:0];
			divref_reg <= DEFAULT_REG_CLKDIV[7:0];
			irqena_reg <= 1'b0;		// irq disable
			sso_reg    <= 1'b0;		// select disable
		end
		else begin
			case (state_reg)
			STATE_IDLE : begin
				if (avs_write) begin
					case (avs_address)
					1'd0 : begin
						if (avs_writedata[9]) begin
							if (mode_reg[0] == 1'b0) begin	// MODE=0 or 2
								state_reg <= STATE_SDI;
							end
							else begin						// MODE=1 or 3
								state_reg <= STATE_ENTRY;
							end

							ready_reg <= 1'b0;
							bitcount  <= 3'd0;
							divcount  <= divref_reg;
						end

						irqena_reg <= avs_writedata[15];
						sso_reg    <= avs_writedata[8];
						sclk_reg   <= mode_reg[1];
						txbyte_reg <= txdata_sig;
					end

					1'd1 : begin
						bitrvs_reg <= avs_writedata[15];
						mode_reg   <= avs_writedata[13:12];
						divref_reg <= avs_writedata[7:0];
					end

					endcase
				end
			end

			STATE_ENTRY : begin
				if (divcount == 0) begin
					state_reg <= STATE_SDI;
					divcount  <= divref_reg;
					sclk_reg  <= ~sclk_reg;
				end
				else begin
					divcount <= divcount - 1'd1;
				end
			end

			STATE_SDI : begin
				if (divcount == 0) begin
					if (mode_reg[0] != 1'b0 && bitcount == 7) begin
						state_reg <= STATE_DONE;
					end
					else begin
						state_reg <= STATE_SDO;
					end

					if (mode_reg[0] != 1'b0) begin
						bitcount <= bitcount + 1'd1;
					end

					divcount   <= divref_reg;
					sclk_reg   <= ~sclk_reg;
					rxbyte_reg <= {rxbyte_reg[6:0], sdi_sig};
				end
				else begin
					divcount <= divcount - 1'd1;
				end
			end

			STATE_SDO : begin
				if (divcount == 0) begin
					if (mode_reg[0] == 1'b0 && bitcount == 7) begin
						state_reg <= STATE_DONE;
					end
					else begin
						state_reg <= STATE_SDI;
					end

					if (mode_reg[0] == 1'b0) begin
						bitcount <= bitcount + 1'd1;
					end

					divcount   <= divref_reg;
					sclk_reg   <= ~sclk_reg;
					txbyte_reg <= {txbyte_reg[6:0], 1'b0};
				end
				else begin
					divcount <= divcount - 1'd1;
				end
			end

			STATE_DONE : begin
				if (divcount == 0) begin
					state_reg <= STATE_IDLE;
					ready_reg <= 1'b1;
				end
				else begin
					divcount <= divcount - 1'd1;
				end
			end

			endcase
		end
	end



endmodule
