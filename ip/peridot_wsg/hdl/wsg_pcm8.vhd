-- ===================================================================
-- TITLE : Loreley-WSG (8bitPCM sound module)
--
--     DESIGN : S.OSAFUNE (J-7SYSTEM WORKS LIMITED)
--     DATE   : 2011/09/12 -> 2011/09/13
--            : 2011/06/13 (FIXED)
--     MODIFY : 2016/10/25 CycloneIV/MAX10�A�b�v�f�[�g 
--
-- ===================================================================
-- *******************************************************************
--    (C) 2011-2016, J-7SYSTEM WORKS LIMITED.  All rights Reserved.
--
-- * This module is a free sourcecode and there is NO WARRANTY.
-- * No restriction on use. You can use, modify and redistribute it
--   for personal, non-profit or commercial products UNDER YOUR
--   RESPONSIBILITY.
-- * Redistributions of source code must retain the above copyright
--   notice.
-- *******************************************************************

--	0	: PCMCH FSDIV���W�X�^(WO)
--	1	: PCMCH FIFO���W�X�^(WO)
--		:       STATUS���W�X�^(RO)  bit1:fifoinput ready, bit0:play
--
--	write�͂P�N���b�N���A�E�F�C�g�E�z�[���h���� 
-- 	���[�h�̓A�h���X�m���1�N���b�N�ȓ� 
--
-- FSDIV���W�X�^ : �Đ����x��ݒ肷��B0:�����A1-255:1/256�`255/256�X���[�Đ� 
--
-- fifo_irq : �Đ�fifo��256���[�h�ȏ�̋󂫂�����Ƃ���'1'�ɂȂ� 
-- start_sync : fs�^�C�~���O�M���islot_clk�h���C���łP�N���b�N���j 


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity wsg_pcm8 is
	port(
		reset			: in  std_logic;		-- async reset
		clk				: in  std_logic;		-- system clock

		address			: in  std_logic_vector(0 downto 0);
		readdata		: out std_logic_vector(7 downto 0);
		writedata		: in  std_logic_vector(7 downto 0);
		write			: in  std_logic;
		fifo_irq		: out std_logic;

		slot_clk		: in  std_logic;		-- slot engine drive clock
		start_sync		: in  std_logic;		-- slot engine fs sync signal (need one-clock width)

		pcm_out			: out std_logic_vector(7 downto 0)
	);
end wsg_pcm8;

architecture RTL of wsg_pcm8 is
	signal pcm_speed_reg		: std_logic_vector(7 downto 0);	-- need cut timing path (to pcm_playstep_reg)
	signal irq_sig				: std_logic;
	signal play_sig				: std_logic;

	signal pcm_playstep_reg		: std_logic_vector(7 downto 0);
	signal pcm_playstep_sig		: std_logic_vector(8 downto 0);
	signal pcm_playcount_reg	: std_logic_vector(8 downto 0);
	signal pcm_playcount_sig	: std_logic_vector(8 downto 0);


	component wsg_pcmfifo
	PORT
	(
		aclr		: IN STD_LOGIC  := '0';
		data		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		rdclk		: IN STD_LOGIC ;
		rdreq		: IN STD_LOGIC ;
		wrclk		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		q			: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		rdempty		: OUT STD_LOGIC ;
		wrusedw		: OUT STD_LOGIC_VECTOR (10 DOWNTO 0)
	);
	end component;
	signal pcm_fiforead_sig		: std_logic;
	signal pcm_fifowrite_sig	: std_logic;
	signal pcm_wrusedw_sig		: std_logic_vector(10 downto 0);
	signal pcm_fifoempty_sig	: std_logic;
	signal pcm_fifoout_sig		: std_logic_vector(7 downto 0);


begin


	-- PCM�����̃��W�X�^���� 

	irq_sig  <= '1' when(pcm_wrusedw_sig < 1024-256) else '0';
	play_sig <= '1' when(pcm_wrusedw_sig /= 0) else '0';

	with address select readdata <=
		pcm_speed_reg	when "0",
		(1=>irq_sig, 0=>play_sig, others=>'X') when "1",
		(others=>'X')	when others;

	fifo_irq <= irq_sig;

	process (clk, reset) begin						-- ���W�X�^���N���b�N�h���C�� 
		if (reset = '1') then
			pcm_speed_reg <= (others=>'0');

		elsif rising_edge(clk) then
			if (write = '1' and address = "0") then
				pcm_speed_reg <= writedata;
			end if;

		end if;
	end process;


	-- FIFO����M���̐��� 

	pcm_playstep_sig  <= (8=>'1',others=>'0') when(pcm_playstep_reg = 0) else ('0' & pcm_playstep_reg);
	pcm_playcount_sig <= ('0' & pcm_playcount_reg(7 downto 0));

	process (slot_clk) begin						-- �X���b�g���N���b�N�h���C�� 
		if rising_edge(slot_clk) then
			pcm_playstep_reg <= pcm_speed_reg;

			if (pcm_fifoempty_sig = '1') then		-- FIFO empty�ōĐ��I���ƌ��Ȃ� 
				pcm_playcount_reg <= (others=>'0');
			elsif (start_sync = '1') then
				pcm_playcount_reg <= pcm_playcount_sig + pcm_playstep_sig;
			end if;
		end if;
	end process;


	-- PCM-FIFO�̃C���X�^���X 

	pcm_fifowrite_sig <= '1' when(address = "1" and write = '1') else '0';
	pcm_fiforead_sig  <= '1' when(start_sync = '1' and pcm_playcount_reg(8) = '1') else '0';

	U_PCMFIFO : wsg_pcmfifo
	PORT MAP (
		aclr		=> '0',
		wrclk		=> clk,
		wrreq		=> pcm_fifowrite_sig,
		data		=> writedata,
		wrusedw		=> pcm_wrusedw_sig,

		rdclk		=> slot_clk,
		rdreq		=> pcm_fiforead_sig,
		q			=> pcm_fifoout_sig,
		rdempty		=> pcm_fifoempty_sig
	);


	-- PCM�f�[�^�o�� 

	pcm_out <= pcm_fifoout_sig when(pcm_fifoempty_sig = '0') else (others=>'0');




end RTL;
