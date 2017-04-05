-- ===================================================================
-- TITLE : Loreley-WSG Delta-Sigma DAC output module
--
--     DESIGN : S.OSAFUNE (J-7SYSTEM WORKS LIMITED)
--     DATE   : 2007/02/18 -> 2007/02/18
--            : 2007/02/21 (FIXED)
--     MODIFY : 2016/10/25 CycloneIV/MAX10�A�b�v�f�[�g 
--
-- ===================================================================
-- *******************************************************************
--    (C) 2007-2016, J-7SYSTEM WORKS LIMITED.  All rights Reserved.
--
-- * This module is a free sourcecode and there is NO WARRANTY.
-- * No restriction on use. You can use, modify and redistribute it
--   for personal, non-profit or commercial products UNDER YOUR
--   RESPONSIBILITY.
-- * Redistributions of source code must retain the above copyright
--   notice.
-- *******************************************************************

-- ���W�{���`��ԃX�e�[�W 
--   ���`��Ԃ̂��߁A���M��f(t)�ɑ΂��āA1/(2n-1)^2 * f((2n-1)*t)�� 
--   �����m�C�Y���d�􂷂�B 
--
--    ���M��  �R��  �T��  �V��  �X��  11��  13��  �d�d 
--      0dB  -19dB -27dB -33dB -38dB -41dB -44dB 
--
-- ���o�͇����ϒ��X�e�[�W 
--   �t���X�s�[�h�œ��삷��P�r�b�g�P�������ϒ��u���b�N�B 
--
-- ���|�b�v�m�C�Y 
--   �����ϒ��̍\����A�d���������̃|�b�v�m�C�Y�͉��s�i�ł��Ȃ��� 
--   �Ȃ����A���W�b�N���\�[�X�Ƃ̃g���[�h�I�t�j�B 
--   �|�b�v�m�C�Y���s�s���ɂȂ�ꍇ�AAC�J�b�v�����O�R���f���T�̌�i�� 
--   �~���[�g�g�����W�X�^��z�u���邱�Ƃŉ��P�\�B 


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity wsg_dsdac8 is
	generic(
		PCMBITWIDTH		: integer := 12
	);
	port(
		reset		: in  std_logic;
		clk			: in  std_logic;
		fs_timing	: in  std_logic;
		fs8_timing	: in  std_logic;

		pcmdata_in	: in  std_logic_vector(PCMBITWIDTH-1 downto 0);
		dac_out		: out std_logic
	);
end wsg_dsdac8;

architecture RTL of wsg_dsdac8 is
	signal pcmin_reg	: std_logic_vector(PCMBITWIDTH-1 downto 0);
	signal delta_reg	: std_logic_vector(PCMBITWIDTH downto 0);
	signal osvpcm_reg	: std_logic_vector(PCMBITWIDTH+2 downto 0);

	signal pcm_sig		: std_logic_vector(PCMBITWIDTH-1 downto 0);
	signal add_sig		: std_logic_vector(PCMBITWIDTH downto 0);
	signal dse_reg		: std_logic_vector(PCMBITWIDTH-1 downto 0);
	signal dacout_reg	: std_logic;

begin


-- ���`�W�{�I�[�o�[�T���v�����O�X�e�[�W -----

	process(clk, reset)begin
		if (reset = '1') then
			pcmin_reg  <= (others=>'0');
			delta_reg  <= (others=>'0');
			osvpcm_reg <= (others=>'0');

		elsif rising_edge(clk) then
			if (fs_timing = '1') then
				pcmin_reg  <= pcmdata_in;
				delta_reg  <=(pcmdata_in(pcmdata_in'left)& pcmdata_in) - (pcmin_reg(pcmin_reg'left) & pcmin_reg);
				osvpcm_reg <= pcmin_reg & "000";

			elsif (fs8_timing = '1') then
				osvpcm_reg <= osvpcm_reg + (delta_reg(delta_reg'left) & delta_reg(delta_reg'left) & delta_reg);

			end if;

		end if;
	end process;


-- �����ϒ��X�e�[�W -----

	pcm_sig(pcm_sig'left) <= not osvpcm_reg(osvpcm_reg'left);
	pcm_sig(pcm_sig'left-1 downto 0) <= osvpcm_reg(osvpcm_reg'left-1 downto 3);

	add_sig <= ('0' & pcm_sig) + ('0' & dse_reg);

	process(clk, reset)begin
		if (reset = '1') then
			dse_reg    <= (others=>'0');
			dacout_reg <= '0';

		elsif rising_edge(clk) then
			dse_reg    <= add_sig(add_sig'left-1 downto 0);
			dacout_reg <= add_sig(add_sig'left);

		end if;
	end process;


	-- DAC�o�� 

	dac_out <= dacout_reg;



end RTL;
