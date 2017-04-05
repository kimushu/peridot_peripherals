-- ===================================================================
-- TITLE : Loreley-WSG BUS Interface
--
--     DESIGN : S.OSAFUNE (J-7SYSTEM WORKS LIMITED)
--     DATE   : 2009/01/01 -> 2009/01/09
--            : 2009/01/15 (FIXED)
--
--     MODIFY : 2009/06/12 �O�������|�[�g��ǉ� 
--            : 2009/06/25 �^�C�}B�̕���\��ύX(2ms��1ms) 
--            : 2009/06/27 �g�������|�[�g�̃o�C�g�A�N�Z�X�s����C�� 
--            : 2011/09/13 �}�X�^�[�{�����[�����W�X�^��ǉ� 
--
--     MODIFY : 2016/10/25 CycloneIV/MAX10�p�A�b�v�f�[�g 
--
-- ===================================================================
-- *******************************************************************
--    (C) 2009-2016, J-7SYSTEM WORKS LIMITED.  All rights Reserved.
--
-- * This module is a free sourcecode and there is NO WARRANTY.
-- * No restriction on use. You can use, modify and redistribute it
--   for personal, non-profit or commercial products UNDER YOUR
--   RESPONSIBILITY.
-- * Redistributions of source code must retain the above copyright
--   notice.
-- *******************************************************************

-- ���[�h�͂R�N���b�N���i�A�h���X�m���Q�N���b�Nwait�j�ȏ� 
-- ���C�g�͂P�N���b�N�� 
-- �E�F�C�g�E�z�[���h�Ȃ� 
-- �g���������W���[�������l�̃A�N�Z�X�ōs���邱�� 


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity wsg_businterface is
	port(
		clk				: in  std_logic;	-- system clock
		reset			: in  std_logic;	-- async reset

		async_fs_in		: in  std_logic;	-- Async fs signal input
		mute_out		: out std_logic;
		mastervol_l		: out std_logic_vector(14 downto 0);
		mastervol_r		: out std_logic_vector(14 downto 0);

	--==== AvalonBUS I/F signal ======================================

		address			: in  std_logic_vector(9 downto 0);
		readdata		: out std_logic_vector(15 downto 0);
		read			: in  std_logic;
		writedata		: in  std_logic_vector(15 downto 0);
		write			: in  std_logic;
		byteenable		: in  std_logic_vector(1 downto 0);
		irq				: out std_logic;

	--==== External module I/F signal ================================

		ext_address		: out std_logic_vector(5 downto 0);		-- External address space
		ext_readdata	: in  std_logic_vector(7 downto 0);
		ext_writedata	: out std_logic_vector(7 downto 0);
		ext_write		: out std_logic;
		ext_irq			: in  std_logic := '0';					-- External interrupt input

	--==== Slotengine I/F signal =====================================

		slot_start		: out std_logic;	-- engine process start ('clk' domain)
		slot_done		: in  std_logic;	-- Async slot done signal (need rise edge detect)
		keysync_out		: out std_logic;

		slot_clk		: in  std_logic;	-- slot engine drive clock

		reg_address		: in  std_logic_vector(8 downto 1);
		reg_readdata	: out std_logic_vector(17 downto 0);
		reg_writedata	: in  std_logic_vector(17 downto 0);
		reg_write		: in  std_logic;

		wav_address		: in  std_logic_vector(8 downto 0);
		wav_readdata	: out std_logic_vector(7 downto 0)
	);
end wsg_businterface;

architecture RTL of wsg_businterface is
	signal extfs0_reg		: std_logic;
	signal extfs1_reg		: std_logic;
	signal extfs_in_reg		: std_logic;
	signal fssync_sig		: std_logic;

	signal start_reg		: std_logic;
	signal done_in_reg		: std_logic;
	signal done0_reg		: std_logic;
	signal done1_reg		: std_logic;
	signal slotack_sig		: std_logic;

	signal sys_rddata_sig	: std_logic_vector(15 downto 0);
	signal sys_setup_sig	: std_logic_vector(15 downto 0);
	signal sys_timer_sig	: std_logic_vector(15 downto 0);
	signal sys_wrena_sig	: std_logic;

	signal mute_reg			: std_logic;
	signal keysync_reg		: std_logic;
	signal keysync_fs_reg	: std_logic;
	signal timairq_reg		: std_logic;
	signal timaovf_reg		: std_logic;
	signal timastart_reg	: std_logic;
	signal timaref_reg		: std_logic_vector(7 downto 0);
	signal timacount_reg	: std_logic_vector(7 downto 0);
	signal timatimeup_sig	: std_logic;
	signal timbirq_reg		: std_logic;
	signal timbovf_reg		: std_logic;
	signal timbstart_reg	: std_logic;
	signal timbref_reg		: std_logic_vector(7 downto 0);
	signal timbref_sig		: std_logic_vector(12 downto 0);
	signal timbcount_reg	: std_logic_vector(12 downto 0);
	signal timbtimeup_sig	: std_logic;

	signal mvol_l_reg		: std_logic_vector(14 downto 0);
	signal mvol_r_reg		: std_logic_vector(14 downto 0);

	signal readdata_reg		: std_logic_vector(15 downto 0);

	component wsg_slotregister
	PORT
	(
		address_a	: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		address_b	: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		byteena_a	: IN STD_LOGIC_VECTOR (1 DOWNTO 0) :=  (OTHERS => '1');
		clock_a		: IN STD_LOGIC ;
		clock_b		: IN STD_LOGIC ;
		data_a		: IN STD_LOGIC_VECTOR (17 DOWNTO 0);
		data_b		: IN STD_LOGIC_VECTOR (17 DOWNTO 0);
		wren_a		: IN STD_LOGIC  := '1';
		wren_b		: IN STD_LOGIC  := '1';
		q_a			: OUT STD_LOGIC_VECTOR (17 DOWNTO 0);
		q_b			: OUT STD_LOGIC_VECTOR (17 DOWNTO 0)
	);
	end component;
	signal reg_rddata_sig	: std_logic_vector(17 downto 0);
	signal reg_wrdata_sig	: std_logic_vector(17 downto 0);
	signal reg_wrena_sig	: std_logic;

	component wsg_wavetable
	PORT
	(
		address_a	: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		address_b	: IN STD_LOGIC_VECTOR (8 DOWNTO 0);
		byteena_a	: IN STD_LOGIC_VECTOR (1 DOWNTO 0) :=  (OTHERS => '1');
		clock_a		: IN STD_LOGIC ;
		clock_b		: IN STD_LOGIC ;
		data_a		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		data_b		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		wren_a		: IN STD_LOGIC  := '1';
		wren_b		: IN STD_LOGIC  := '1';
		q_a			: OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
		q_b			: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
	end component;
	signal wav_rddata_sig	: std_logic_vector(15 downto 0);
	signal wav_wrena_sig	: std_logic;

begin


--==== AvalonBUS ���o�� ==============================================

	-- �ǂݏo�����W�X�^�I�� 
		--	00_0XXX_XXXX : �V�X�e�����W�X�^(128�o�C�g) 
		--	00_1XXX_XXXX : �g���������W�X�^(128�o�C�g�A������������8bit�݂̂̃}�b�s���O) 
		--	01_XXXX_XXXX : �X���b�g���W�X�^(256�o�C�g)
		--	1X_XXXX_XXXX : �g�`�e�[�u��������(512�o�C�g)

	readdata <= ("00000000" & ext_readdata) when (address(9 downto 7)="001") else readdata_reg;

	process (clk) begin
		if rising_edge(clk) then

			if (address(9) = '1') then
				readdata_reg <= wav_rddata_sig;
			else
				if (address(8 downto 3) = "000000") then
					readdata_reg <= sys_rddata_sig;
				else
					readdata_reg( 7 downto 0) <= reg_rddata_sig( 7 downto 0);
					readdata_reg(15 downto 8) <= reg_rddata_sig(16 downto 9);
				end if;
			end if;

		end if;
	end process;


	-- ���荞�ݐM���o�� 

	irq <= (timaovf_reg and timairq_reg) or (timbovf_reg and timbirq_reg) or ext_irq;


	-- �������݃��W�X�^�I�� 

	sys_wrena_sig <= write when (address(9 downto 3)="0000000") else '0';
	reg_wrena_sig <= write when (address(9 downto 8)="01") else '0';
	wav_wrena_sig <= write when (address(9)='1') else '0';


	-- �g�������o�X�o��

	ext_address   <= address(6 downto 1);
	ext_writedata <= writedata(7 downto 0);
	ext_write     <= write when (address(9 downto 7)="001" and byteenable(0)='1') else '0';


	-- �X���b�g���W�X�^�̃C���X�^���X 

	reg_wrdata_sig( 8 downto 0) <= '0' & writedata( 7 downto 0);
	reg_wrdata_sig(17 downto 9) <= '0' & writedata(15 downto 8);

	wsg_slotregister_inst : wsg_slotregister
	PORT MAP (
		clock_a		 => clk,
		address_a	 => address(8 downto 1),
		q_a			 => reg_rddata_sig,
		data_a		 => reg_wrdata_sig,
		wren_a		 => reg_wrena_sig,
		byteena_a	 => byteenable,

		clock_b		 => slot_clk,
		address_b	 => reg_address,
		q_b			 => reg_readdata,
		data_b		 => reg_writedata,
		wren_b		 => reg_write
	);


	-- �g�`�e�[�u���̃C���X�^���X 

	wsg_wavetable_inst : wsg_wavetable
	PORT MAP (
		clock_a		 => clk,
		address_a	 => address(8 downto 1),
		q_a			 => wav_rddata_sig,
		data_a		 => writedata,
		wren_a		 => wav_wrena_sig,
		byteena_a	 => byteenable,

		clock_b		 => slot_clk,
		address_b	 => wav_address,
		q_b			 => wav_readdata,
		data_b		 => (others=>'0'),
		wren_b		 => '0'
	);


	-- �V�X�e�����W�X�^�ǂݏo���I�� 

	with address(2 downto 1) select sys_rddata_sig <=
		sys_setup_sig		when "00",
		sys_timer_sig		when "01",
		'0' & mvol_l_reg	when "10",
		'0' & mvol_r_reg	when "11",
		(others=>'X')		when others;

	sys_setup_sig(15) <= keysync_reg;
	sys_setup_sig(14 downto 8) <= (others=>'0');
	sys_setup_sig(7)  <= timbirq_reg;
	sys_setup_sig(6)  <= timbovf_reg;
	sys_setup_sig(5)  <= timbstart_reg;
	sys_setup_sig(4)  <= timairq_reg;
	sys_setup_sig(3)  <= timaovf_reg;
	sys_setup_sig(2)  <= timastart_reg;
	sys_setup_sig(1)  <= '0';
	sys_setup_sig(0)  <= mute_reg;

	sys_timer_sig <= timbref_reg & timaref_reg;


	-- �V�X�e�����W�X�^�������� 

	process (clk, reset) begin
		if (reset = '1') then
			keysync_reg    <= '0';
			keysync_fs_reg <= '0';
			mute_reg       <= '1';
			timairq_reg    <= '0';
			timaovf_reg    <= '0';
			timastart_reg  <= '0';
			timaref_reg    <= (others=>'0');
			timbirq_reg    <= '0';
			timbovf_reg    <= '0';
			timbstart_reg  <= '0';
			timbref_reg    <= (others=>'0');
			mvol_l_reg     <= (others=>'0');
			mvol_r_reg     <= (others=>'0');

		elsif rising_edge(clk) then

			-- keysync�r�b�g�̏��� 
			if (fssync_sig = '1') then
				keysync_fs_reg <= keysync_reg;
			end if;

			if (slotack_sig = '1' and keysync_fs_reg = keysync_reg) then
				keysync_reg <= '0';
			elsif (sys_wrena_sig = '1' and address(1) = '0' and byteenable(1) = '1') then
				keysync_reg <= keysync_reg or writedata(15);
			end if;

			-- fs�C���^�[�o���^�C�}�ƃI�[�o�[�t���[�r�b�g�̏��� 
			if (fssync_sig = '1' and timacount_reg = timaref_reg) then
				timaovf_reg <= '1';
			elsif (sys_wrena_sig = '1' and address(1) = '0' and byteenable(0) = '1') then
				timaovf_reg <= timaovf_reg and writedata(6);
			end if;

			if (fssync_sig = '1' and timbcount_reg = timbref_sig) then
				timbovf_reg <= '1';
			elsif (sys_wrena_sig = '1' and address(1) = '0' and byteenable(0) = '1') then
				timbovf_reg <= timbovf_reg and writedata(3);
			end if;

			-- ����ȊO�̃��W�X�^�̏��� 
			if (sys_wrena_sig = '1') then
				case address(2 downto 1) is
				when "00" =>
					if (byteenable(0) = '1') then
						timbirq_reg   <= writedata(7);
						timbstart_reg <= writedata(5);
						timairq_reg   <= writedata(4);
						timastart_reg <= writedata(2);
						mute_reg      <= writedata(0);
					end if;

				when "01" =>
					if (byteenable(1) = '1') then
						timbref_reg <= writedata(15 downto 8);
					end if;
					if (byteenable(0) = '1') then
						timaref_reg <= writedata(7 downto 0);
					end if;

				when "10" =>
					if (byteenable(1) = '1') then
						mvol_l_reg(14 downto 8) <= writedata(14 downto 8);
					end if;
					if (byteenable(0) = '1') then
						mvol_l_reg(7 downto 0)  <= writedata(7 downto 0);
					end if;

				when "11" =>
					if (byteenable(1) = '1') then
						mvol_r_reg(14 downto 8) <= writedata(14 downto 8);
					end if;
					if (byteenable(0) = '1') then
						mvol_r_reg(7 downto 0)  <= writedata(7 downto 0);
					end if;

				when others =>
				end case;
			end if;

		end if;
	end process;


	-- �V�X�e�����W�X�^�o�� 

	mute_out    <= mute_reg;
	keysync_out <= keysync_reg;
	mastervol_l <= mvol_l_reg;
	mastervol_r <= mvol_r_reg;



--==== fs�����M�������u���b�N ========================================

	-- �X���b�g�G���W���L�b�N�M���𐶐� 

	slot_start <= start_reg;

	process (clk, reset) begin
		if (reset = '1') then
			start_reg <= '0';

		elsif rising_edge(clk) then
			if (fssync_sig = '1') then
				start_reg <= '1';
			elsif (done0_reg = '0' and done1_reg = '1') then	-- slot_done�̗������start������ 
				start_reg <= '0';
			end if;

		end if;
	end process;


	-- �X���b�g�G���W���I���M���̓����� (slot_done�̗����オ��G�b�W�����o)

	slotack_sig <= '1' when(done0_reg = '1' and done1_reg = '0') else '0';

	process (clk, reset) begin
		if (reset = '1') then
			done0_reg   <= '0';
			done1_reg   <= '0';
			done_in_reg <= '0';

		elsif rising_edge(clk) then
			done1_reg   <= done0_reg;
			done0_reg   <= done_in_reg;
			done_in_reg <= slot_done;

		end if;
	end process;


	-- fs�M���̓����� (async_fs�̗����オ��G�b�W�����o)

	fssync_sig <= '1' when(extfs0_reg = '1' and extfs1_reg = '0') else '0';

	process (clk, reset) begin
		if (reset = '1') then
			extfs0_reg   <= '0';
			extfs1_reg   <= '0';
			extfs_in_reg <= '0';

		elsif rising_edge(clk) then
			extfs1_reg   <= extfs0_reg;
			extfs0_reg   <= extfs_in_reg;
			extfs_in_reg <= async_fs_in;

		end if;
	end process;


	-- fs�C���^�[�o���^�C�} 

	timbref_sig <= timbref_reg & "00000";	-- �^�C�}B��fs/32�ŃJ�E���g���� 

	process (clk, reset) begin
		if (reset = '1') then
			timacount_reg <= (others=>'0');
			timbcount_reg <= (others=>'0');

		elsif rising_edge(clk) then

			-- �^�C�}�`�̃J�E���g���� 
			if (timastart_reg = '1') then
				if (fssync_sig = '1') then
					if (timacount_reg = timaref_reg) then
						timacount_reg <= (others=>'0');
					else
						timacount_reg <= timacount_reg + '1';
					end if;
				end if;
			else
				timacount_reg <= (others=>'0');
			end if;

			-- �^�C�}�a�̃J�E���g���� 
			if (timbstart_reg = '1') then
				if (fssync_sig = '1') then
					if (timbcount_reg = timbref_sig) then
						timbcount_reg <= (others=>'0');
					else
						timbcount_reg <= timbcount_reg + '1';
					end if;
				end if;
			else
				timbcount_reg <= (others=>'0');
			end if;

		end if;
	end process;



end RTL;
