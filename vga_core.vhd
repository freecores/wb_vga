--
--  File: vga_core.vhd
--
--  (c) Copyright Andras Tantos <andras_tantos@yahoo.com> 2001/03/31
--  This code is distributed under the terms and conditions of the GNU General Public Lince.
--

library IEEE;
use IEEE.std_logic_1164.all;

library work;
--use wb_tk.all;
use work.wb_tk.all;

entity vga_core is
	generic (
		-- cannot be overwritten at the moment...
		v_mem_width: positive := 16;
		fifo_size: positive := 256;
		v_addr_width : positive := 20;
		bus_width: positive := 8
	);
	port (
		clk_i: in std_logic;
		clk_en: in std_logic := '1';
		rst_i: in std_logic := '0';

		-- CPU bus interface
		dat_i: in std_logic_vector (bus_width-1 downto 0);
		dat_oi: in std_logic_vector (bus_width-1 downto 0);
		dat_o: out std_logic_vector (bus_width-1 downto 0);
		cyc_i: in std_logic;
		ack_o: out std_logic;
		ack_oi: in std_logic;
		we_i: in std_logic;
		vmem_stb_i: in std_logic;
		reg_stb_i: in std_logic;
		adr_i: in std_logic_vector (v_addr_width downto 0);

		-- video memory SRAM interface
		s_data : inout std_logic_vector((v_mem_width-1) downto 0);
		s_addr : out std_logic_vector((v_addr_width-1) downto 0);
		s_oen : out std_logic;
		s_wrhn : out std_logic;
		s_wrln : out std_logic;
		s_cen : out std_logic;

		-- sync blank and video signal outputs
		h_sync: out std_logic;
		h_blank: out std_logic;
		v_sync: out std_logic;
		v_blank: out std_logic;
		h_tc: out std_logic;
		v_tc: out std_logic;
		blank: out std_logic;
		video_out: out std_logic_vector (7 downto 0);  -- video output binary signal (unused bits are forced to 0)

        -- TEST SIGNALS
	    T_v_we_o: out std_logic;
	    T_v_stb_o: out std_logic;
	    T_v_ack_i: out std_logic;
	    T_v_adr_o : out std_logic_vector((v_addr_width-1) downto 0);
	    T_v_sel_o : out std_logic_vector((v_addr_width/8)-1 downto 0);
	    T_v_dat_o : out std_logic_vector((v_mem_width-1) downto 0);
	    T_v_dat_i : out std_logic_vector((v_mem_width-1) downto 0)
	);
end vga_core;

architecture vga_core of vga_core is
	component video_engine
		generic (
			v_mem_width: positive := 16;
			v_addr_width: positive:= 20;
			fifo_size: positive := 256;
			dual_scan_fifo_size: positive := 256
		);
		port (
			clk: in std_logic;
			clk_en: in std_logic := '1';
			reset: in std_logic := '0';

			total: in std_logic_vector(v_addr_width-1 downto 0);   -- total video memory size in bytes 7..0
			fifo_treshold: in std_logic_vector(7 downto 0);        -- priority change threshold
			bpp: in std_logic_vector(1 downto 0);                  -- number of bits makes up a pixel valid values: 1,2,4,8
			multi_scan: in std_logic_vector(1 downto 0);           -- number of repeated scans

			hbs: in std_logic_vector(7 downto 0);
			hss: in std_logic_vector(7 downto 0);
			hse: in std_logic_vector(7 downto 0);
			htotal: in std_logic_vector(7 downto 0);
			vbs: in std_logic_vector(7 downto 0);
			vss: in std_logic_vector(7 downto 0);
			vse: in std_logic_vector(7 downto 0);
			vtotal: in std_logic_vector(7 downto 0);

			pps: in std_logic_vector(7 downto 0);

			high_prior: out std_logic;                      -- signals to the memory arbitrer to give high
			                                                -- priority to the video engine
			v_mem_rd: out std_logic;                        -- video memory read request
			v_mem_rdy: in std_logic;                        -- video memory data ready
			v_mem_addr: out std_logic_vector (v_addr_width-1 downto 0); -- video memory address
			v_mem_data: in std_logic_vector (v_mem_width-1 downto 0);   -- video memory data

			h_sync: out std_logic;
			h_blank: out std_logic;
			v_sync: out std_logic;
			v_blank: out std_logic;
			h_tc: out std_logic;
			v_tc: out std_logic;
			blank: out std_logic;
			video_out: out std_logic_vector (7 downto 0)    -- video output binary signal (unused bits are forced to 0)
		);
	end component video_engine;

	component wb_async_slave
	generic (
		width: positive := 16;
		addr_width: positive := 20
	);
	port (
		clk_i: in std_logic;
		rst_i: in std_logic := '0';
		
		-- interface for wait-state generator state-machine
		wait_state: in std_logic_vector (3 downto 0);

		-- interface to wishbone master device
		adr_i: in std_logic_vector (addr_width-1 downto 0);
		sel_i: in std_logic_vector ((addr_width/8)-1 downto 0);
		dat_i: in std_logic_vector (width-1 downto 0);
		dat_o: out std_logic_vector (width-1 downto 0);
		dat_oi: in std_logic_vector (width-1 downto 0) := (others => '-');
		we_i: in std_logic;
		stb_i: in std_logic;
		ack_o: out std_logic := '0';
		ack_oi: in std_logic := '-';
	
		-- interface to async slave
		a_data: inout std_logic_vector (width-1 downto 0) := (others => 'Z');
		a_addr: out std_logic_vector (addr_width-1 downto 0) := (others => 'U');
		a_rdn: out std_logic := '1';
		a_wrn: out std_logic := '1';
		a_cen: out std_logic := '1';
		-- byte-enable signals
		a_byen: out std_logic_vector ((addr_width/8)-1 downto 0)
	);
	end component;

	component wb_arbiter
	port (
--		clk: in std_logic;
		rst_i: in std_logic := '0';
		
		-- interface to master device a
		a_we_i: in std_logic;
		a_stb_i: in std_logic;
		a_cyc_i: in std_logic;
		a_ack_o: out std_logic;
		a_ack_oi: in std_logic := '-';
		a_err_o: out std_logic;
		a_err_oi: in std_logic := '-';
		a_rty_o: out std_logic;
		a_rty_oi: in std_logic := '-';
	
		-- interface to master device b
		b_we_i: in std_logic;
		b_stb_i: in std_logic;
		b_cyc_i: in std_logic;
		b_ack_o: out std_logic;
		b_ack_oi: in std_logic := '-';
		b_err_o: out std_logic;
		b_err_oi: in std_logic := '-';
		b_rty_o: out std_logic;
		b_rty_oi: in std_logic := '-';

		-- interface to shared devices
		s_we_o: out std_logic;
		s_stb_o: out std_logic;
		s_cyc_o: out std_logic;
		s_ack_i: in std_logic;
		s_err_i: in std_logic := '-';
		s_rty_i: in std_logic := '-';
		
		mux_signal: out std_logic; -- 0: select A signals, 1: select B signals

		-- misc control lines
		priority: in std_logic -- 0: A have priority over B, 1: B have priority over A
	);
	end component;

	component wb_out_reg
  	generic (
  		width : positive := 8;
  		bus_width: positive := 8;
  		offset: integer := 0
  	);
  	port (
  		clk_i: in std_logic;
  		rst_i: in std_logic;
  		rst_val: std_logic_vector(width-1 downto 0) := (others => '0');

  		dat_i: in std_logic_vector (bus_width-1 downto 0);
  		dat_oi: in std_logic_vector (bus_width-1 downto 0) := (others => '-');
  		dat_o: out std_logic_vector (bus_width-1 downto 0);
  		q: out std_logic_vector (width-1 downto 0);
  		we_i: in std_logic;
  		stb_i: in std_logic;
  		ack_o: out std_logic;
  		ack_oi: in std_logic := '-'
  	);
	end component;

	component wb_bus_upsize
	generic (
		m_bus_width: positive := 8; -- master bus width
		m_addr_width: positive := 21; -- master bus width
		s_bus_width: positive := 16; -- slave bus width
		little_endien: boolean := true -- if set to false, big endien
	);
	port (
--		clk_i: in std_logic;
--		rst_i: in std_logic := '0';

		-- Master bus interface
		m_adr_i: in std_logic_vector (m_addr_width-1 downto 0);
		m_sel_i: in std_logic_vector ((m_bus_width/8)-1 downto 0) := (others => '1');
		m_dat_i: in std_logic_vector (m_bus_width-1 downto 0);
		m_dat_oi: in std_logic_vector (m_bus_width-1 downto 0) := (others => '-');
		m_dat_o: out std_logic_vector (m_bus_width-1 downto 0);
		m_cyc_i: in std_logic;
		m_ack_o: out std_logic;
		m_ack_oi: in std_logic := '-';
		m_err_o: out std_logic;
		m_err_oi: in std_logic := '-';
		m_rty_o: out std_logic;
		m_rty_oi: in std_logic := '-';
		m_we_i: in std_logic;
		m_stb_i: in std_logic;

		-- Slave bus interface
		s_adr_o: out std_logic_vector (m_addr_width-2 downto 0);
		s_sel_o: out std_logic_vector ((s_bus_width/8)-1 downto 0);
		s_dat_i: in std_logic_vector (s_bus_width-1 downto 0);
		s_dat_o: out std_logic_vector (s_bus_width-1 downto 0);
		s_cyc_o: out std_logic;
		s_ack_i: in std_logic;
		s_err_i: in std_logic := '-';
		s_rty_i: in std_logic := '-';
		s_we_o: out std_logic;
		s_stb_o: out std_logic
	);
	end component;

	signal reset_core: std_logic_vector(0 downto 0);
	signal total: std_logic_vector(v_addr_width-1 downto 0);
	signal fifo_treshold: std_logic_vector(7 downto 0);
	signal bpp: std_logic_vector(1 downto 0);
	signal multi_scan: std_logic_vector(1 downto 0);
	signal hbs: std_logic_vector(7 downto 0);
	signal hss: std_logic_vector(7 downto 0);
	signal hse: std_logic_vector(7 downto 0);
	signal htotal: std_logic_vector(7 downto 0);
	signal vbs: std_logic_vector(7 downto 0);
	signal vss: std_logic_vector(7 downto 0);
	signal vse: std_logic_vector(7 downto 0);
	signal vtotal: std_logic_vector(7 downto 0);
	signal pps: std_logic_vector(7 downto 0);
	signal wait_state: std_logic_vector (3 downto 0);
	signal sync_pol: std_logic_vector (3 downto 0);

	signal reset_core_do: std_logic_vector(bus_width-1 downto 0);
	signal total0_do: std_logic_vector(bus_width-1 downto 0);
	signal total1_do: std_logic_vector(bus_width-1 downto 0);
	signal total2_do: std_logic_vector(bus_width-1 downto 0);
	signal fifo_treshold_do: std_logic_vector(bus_width-1 downto 0);
	signal bpp_do: std_logic_vector(bus_width-1 downto 0);
	signal multi_scan_do: std_logic_vector(bus_width-1 downto 0);
	signal hbs_do: std_logic_vector(bus_width-1 downto 0);
	signal hss_do: std_logic_vector(bus_width-1 downto 0);
	signal hse_do: std_logic_vector(bus_width-1 downto 0);
	signal htotal_do: std_logic_vector(bus_width-1 downto 0);
	signal vbs_do: std_logic_vector(bus_width-1 downto 0);
	signal vss_do: std_logic_vector(bus_width-1 downto 0);
	signal vse_do: std_logic_vector(bus_width-1 downto 0);
	signal vtotal_do: std_logic_vector(bus_width-1 downto 0);
	signal pps_do: std_logic_vector(bus_width-1 downto 0);
	signal wait_state_do: std_logic_vector(bus_width-1 downto 0);
	signal vm_do: std_logic_vector(bus_width-1 downto 0);

	signal reset_core_sel: std_logic;
	signal total0_sel: std_logic;
	signal total1_sel: std_logic;
	signal total2_sel: std_logic;
	signal fifo_treshold_sel: std_logic;
	signal bpp_sel: std_logic;
	signal multi_scan_sel: std_logic;
	signal hbs_sel: std_logic;
	signal hss_sel: std_logic;
	signal hse_sel: std_logic;
	signal htotal_sel: std_logic;
	signal vbs_sel: std_logic;
	signal vss_sel: std_logic;
	signal vse_sel: std_logic;
	signal vtotal_sel: std_logic;
	signal pps_sel: std_logic;
	signal wait_state_sel: std_logic;
	signal sync_pol_sel: std_logic;

	signal reset_core_ack: std_logic;
	signal total0_ack: std_logic;
	signal total1_ack: std_logic;
	signal total2_ack: std_logic;
	signal fifo_treshold_ack: std_logic;
	signal bpp_ack: std_logic;
	signal multi_scan_ack: std_logic;
	signal hbs_ack: std_logic;
	signal hss_ack: std_logic;
	signal hse_ack: std_logic;
	signal htotal_ack: std_logic;
	signal vbs_ack: std_logic;
	signal vss_ack: std_logic;
	signal vse_ack: std_logic;
	signal vtotal_ack: std_logic;
	signal pps_ack: std_logic;
	signal wait_state_ack: std_logic;
	signal vm_ack: std_logic;

	signal a_adr_o : std_logic_vector((v_addr_width-1) downto 0);
	signal a_sel_o : std_logic_vector((v_addr_width/8)-1 downto 0);
	signal a_dat_o : std_logic_vector((v_mem_width-1) downto 0);
	signal a_dat_i : std_logic_vector((v_mem_width-1) downto 0);
	signal a_we_o : std_logic;
	signal a_stb_o : std_logic;
	signal a_cyc_o : std_logic;
	signal a_ack_i : std_logic;

	signal b_adr_o : std_logic_vector((v_addr_width-1) downto 0);
	signal b_sel_o : std_logic_vector((v_addr_width/8)-1 downto 0);
--	signal b_dat_o : std_logic_vector((v_mem_width-1) downto 0);
	signal b_dat_i : std_logic_vector((v_mem_width-1) downto 0);
	signal b_stb_o : std_logic;
--	signal b_we_o : std_logic;
--	signal b_cyc_o : std_logic;
	signal b_ack_i : std_logic;

	signal v_we_o: std_logic;
	signal v_stb_o: std_logic;
	signal v_ack_i: std_logic;
	signal v_adr_o : std_logic_vector((v_addr_width-1) downto 0);
	signal v_sel_o : std_logic_vector((v_addr_width/8)-1 downto 0);
	signal v_dat_o : std_logic_vector((v_mem_width-1) downto 0);
	signal v_dat_i : std_logic_vector((v_mem_width-1) downto 0);
	
	signal s_byen : std_logic_vector((v_addr_width/8)-1 downto 0);

	signal mux_signal: std_logic;

	signal high_prior: std_logic;

	signal reset_engine: std_logic;

	signal i_h_sync: std_logic;
	signal i_h_blank: std_logic;
	signal i_v_sync: std_logic;
	signal i_v_blank: std_logic;

	signal s_wrn : std_logic;

begin
	-- map all registers:
	reset_core_reg: wb_out_reg
		generic map( width => 1, bus_width => bus_width , offset => 4 )
		port map(
    		stb_i => reset_core_sel,
    		q => reset_core,
    		rst_val => "1",
    		dat_oi => vm_do,
    		dat_o => reset_core_do,
    		ack_oi => vm_ack,
    		ack_o => reset_core_ack,
    		we_i => we_i, clk_i => clk_i, rst_i => rst_i, dat_i => dat_i );
	total0_reg: wb_out_reg
		generic map( width => 8, bus_width => bus_width , offset => 0 )
		port map(
		    stb_i => total0_sel,
            q => total(7 downto 0),
            rst_val => "00000000",
            dat_oi => reset_core_do,
            dat_o => total0_do,
            ack_oi => reset_core_ack,
            ack_o => total0_ack,
    		we_i => we_i, clk_i => clk_i, rst_i => rst_i, dat_i => dat_i );
	total1_reg: wb_out_reg
		generic map( width => 8, bus_width => bus_width , offset => 0 )
		port map(
            stb_i => total1_sel,
            q => total(15 downto 8),
            rst_val => "00000000",
            dat_oi => total0_do,
            dat_o => total1_do,
            ack_oi => total0_ack,
            ack_o => total1_ack,
    		we_i => we_i, clk_i => clk_i, rst_i => rst_i, dat_i => dat_i );
	total2_reg: wb_out_reg
		generic map( width => 4, bus_width => bus_width , offset => 0 )
		port map(
            stb_i => total2_sel,
            q => total(19 downto 16),
            rst_val => "0000",
            dat_oi => total1_do,
            dat_o => total2_do,
            ack_oi => total1_ack,
            ack_o => total2_ack,
    		we_i => we_i, clk_i => clk_i, rst_i => rst_i, dat_i => dat_i );
	fifo_treshold_reg: wb_out_reg
		generic map( width => 8, bus_width => bus_width , offset => 0 )
		port map(
            stb_i => fifo_treshold_sel,
            q => fifo_treshold,
            rst_val => "00000000",
            dat_oi => total2_do,
            dat_o => fifo_treshold_do,
            ack_oi => total2_ack,
            ack_o => fifo_treshold_ack,
    		we_i => we_i, clk_i => clk_i, rst_i => rst_i, dat_i => dat_i );
	bpp_reg: wb_out_reg
            generic map( width => 2, bus_width => bus_width , offset => 0 )
            port map(
            stb_i => bpp_sel,
            q => bpp,
            rst_val => "00",
            dat_oi => fifo_treshold_do,
            dat_o => bpp_do,
            ack_oi => fifo_treshold_ack,
            ack_o => bpp_ack,
    		we_i => we_i, clk_i => clk_i, rst_i => rst_i, dat_i => dat_i );
	multi_scan_reg: wb_out_reg
		generic map( width => 2, bus_width => bus_width , offset => 2 )
		port map(
            stb_i => multi_scan_sel,
            q => multi_scan,
            rst_val => "00",
            dat_oi => bpp_do,
            dat_o => multi_scan_do,
            ack_oi => bpp_ack,
            ack_o => multi_scan_ack,
    		we_i => we_i, clk_i => clk_i, rst_i => rst_i, dat_i => dat_i );
	hbs_reg: wb_out_reg
		generic map( width => 8, bus_width => bus_width , offset => 0 )
		port map(
            stb_i => hbs_sel, 
            q => hbs,
            rst_val => "00000000",
            dat_oi => multi_scan_do,
            dat_o => hbs_do,
            ack_oi => multi_scan_ack,
            ack_o => hbs_ack,
    		we_i => we_i, clk_i => clk_i, rst_i => rst_i, dat_i => dat_i );
	hss_reg: wb_out_reg
		generic map( width => 8, bus_width => bus_width , offset => 0 )
		port map(      		
            stb_i => hss_sel,
            q => hss,
            rst_val => "00000000",
            dat_oi => hbs_do,
            dat_o => hss_do,
            ack_oi => hbs_ack,
            ack_o => hss_ack,
    		we_i => we_i, clk_i => clk_i, rst_i => rst_i, dat_i => dat_i );
	hse_reg: wb_out_reg
		generic map( width => 8, bus_width => bus_width , offset => 0 )
		port map(
            stb_i => hse_sel,
            q => hse,
            rst_val => "00000000",
            dat_oi => hss_do,
            dat_o => hse_do,
            ack_oi => hss_ack,
            ack_o => hse_ack,
    		we_i => we_i, clk_i => clk_i, rst_i => rst_i, dat_i => dat_i );
	htotal_reg: wb_out_reg
		generic map( width => 8, bus_width => bus_width , offset => 0 )
		port map(
            stb_i => htotal_sel,
            q => htotal,
            rst_val => "00000000",
            dat_oi => hse_do,
            dat_o => htotal_do,
            ack_oi => hse_ack,
            ack_o => htotal_ack,
    		we_i => we_i, clk_i => clk_i, rst_i => rst_i, dat_i => dat_i );
	vbs_reg: wb_out_reg
		generic map( width => 8, bus_width => bus_width , offset => 0 )
		port map(
            stb_i => vbs_sel,
            q => vbs,
            rst_val => "00000000",
            dat_oi => htotal_do,
            dat_o => vbs_do,
            ack_oi => htotal_ack,
            ack_o => vbs_ack,
    		we_i => we_i, clk_i => clk_i, rst_i => rst_i, dat_i => dat_i );
	vss_reg: wb_out_reg
		generic map( width => 8, bus_width => bus_width , offset => 0 )
		port map(
            stb_i => vss_sel,
            q => vss,
            rst_val => "00000000",
            dat_oi => vbs_do,
            dat_o => vss_do,
            ack_oi => vbs_ack,
            ack_o => vss_ack,
    		we_i => we_i, clk_i => clk_i, rst_i => rst_i, dat_i => dat_i );
	vse_reg: wb_out_reg
		generic map( width => 8, bus_width => bus_width , offset => 0 )
		port map(
            stb_i => vse_sel,
            q => vse,
            rst_val => "00000000",
            dat_oi => vss_do,
            dat_o => vse_do,
            ack_oi => vss_ack,
            ack_o => vse_ack,
    		we_i => we_i, clk_i => clk_i, rst_i => rst_i, dat_i => dat_i );
	vtotal_reg: wb_out_reg
		generic map( width => 8, bus_width => bus_width , offset => 0 )
		port map(
            stb_i => vtotal_sel,
            q => vtotal,
            rst_val => "00000000",
            dat_oi => vse_do,
            dat_o => vtotal_do,
            ack_oi => vse_ack,
            ack_o => vtotal_ack,
    		we_i => we_i, clk_i => clk_i, rst_i => rst_i, dat_i => dat_i );
	pps_reg: wb_out_reg
		generic map( width => 8, bus_width => bus_width , offset => 0 )
		port map(
            stb_i => pps_sel,
            q => pps,
            rst_val => "00000000",
            dat_oi => vtotal_do,
            dat_o => pps_do,
            ack_oi => vtotal_ack,
            ack_o => pps_ack,
    		we_i => we_i, clk_i => clk_i, rst_i => rst_i, dat_i => dat_i );
	wait_state_reg: wb_out_reg
		generic map( width => 4, bus_width => bus_width , offset => 0 )
		port map(
            stb_i => wait_state_sel,
            q => wait_state,
            rst_val => "0000",
            dat_oi => pps_do,
            dat_o => wait_state_do,
            ack_oi => pps_ack,
            ack_o => wait_state_ack,
    		we_i => we_i, clk_i => clk_i, rst_i => rst_i, dat_i => dat_i );
	sync_pol_reg: wb_out_reg
		generic map( width => 4, bus_width => bus_width , offset => 4 )
		port map(
            stb_i => sync_pol_sel,
            q => sync_pol,
            rst_val => "0000",
            dat_oi => wait_state_do,
            dat_o => dat_o, -- END OF THE CHAIN
            ack_oi => wait_state_ack,
            ack_o => ack_o, -- END OF THE CHAIN
    		we_i => we_i, clk_i => clk_i, rst_i => rst_i, dat_i => dat_i );

	reset_engine <= rst_i or reset_core(0);

	v_e: video_engine
		generic map ( v_mem_width => v_mem_width, v_addr_width => v_addr_width, fifo_size => fifo_size, dual_scan_fifo_size => fifo_size )
		port map (
			clk => clk_i,
			clk_en => clk_en,
			reset => reset_engine,
			total => total,
			fifo_treshold => fifo_treshold,
			bpp => bpp,
			multi_scan => multi_scan,
			hbs => hbs,
			hss => hss,
			hse => hse,
			htotal => htotal,
			vbs => vbs,
			vss => vss,
			vse => vse,
			vtotal => vtotal,
			pps => pps,

			high_prior => high_prior,

			v_mem_rd => b_stb_o,
			v_mem_rdy => b_ack_i,
			v_mem_addr => b_adr_o,
			v_mem_data => b_dat_i,

			h_sync => i_h_sync,
			h_blank => i_h_blank,
			v_sync => i_v_sync,
			v_blank => i_v_blank,
			h_tc => h_tc,
			v_tc => v_tc,
			blank => blank,
			video_out => video_out
		);

	h_sync <= i_h_sync xor sync_pol(0);
	v_sync <= i_v_sync xor sync_pol(1);
	h_blank <= i_h_blank;-- xor sync_pol(2);
	v_blank <= i_v_blank;-- xor sync_pol(3);

	resize: wb_bus_upsize
		generic map (
			m_bus_width => bus_width, s_bus_width => v_mem_width, m_addr_width => v_addr_width+1
		)
		port map (
			m_adr_i => adr_i,
--			m_sel_i => (others => '1'),
			m_dat_i => dat_i,
			m_dat_oi => dat_oi, -- Beginning of the chain
			m_cyc_i => cyc_i,
			m_dat_o => vm_do,
			m_ack_o => vm_ack,
			m_ack_oi => ack_oi, -- Beginning of the chain
			m_we_i => we_i,
			m_stb_i => vmem_stb_i,
	
			s_adr_o => a_adr_o,
			s_sel_o => a_sel_o,
			s_dat_i => a_dat_i,
			s_dat_o => a_dat_o,
    		s_cyc_o => a_cyc_o,
			s_ack_i => a_ack_i,
			s_we_o => a_we_o,
			s_stb_o => a_stb_o
		);


	arbiter: wb_arbiter
    	port map (
    		rst_i => reset_engine,

    		a_we_i => a_we_o,
    		a_cyc_i => a_cyc_o,
    		a_stb_i => a_stb_o,
    		a_ack_o => a_ack_i,
    		a_ack_oi => '-',

    		b_we_i => '0',
    		b_cyc_i => b_stb_o,
    		b_stb_i => b_stb_o,
    		b_ack_o => b_ack_i,
    		b_ack_oi => '0', -- maybe not needed at all

    		s_we_o => v_we_o,
    		s_stb_o => v_stb_o,
    		s_ack_i => v_ack_i,

	    	mux_signal => mux_signal,
    
    		priority => high_prior
    	);

    b_sel_o <= (others => '1');
    
	bus_mux: process is
	begin
		wait on mux_signal, v_dat_i, a_adr_o, a_dat_o, b_adr_o, a_sel_o, b_sel_o;
		if (mux_signal = '0') then
			v_adr_o <= a_adr_o;
			v_sel_o <= a_sel_o;
			v_dat_o <= a_dat_o;
			a_dat_i <= v_dat_i;
			b_dat_i <= (others => '-');
		else
			v_adr_o <= b_adr_o;
			v_sel_o <= b_sel_o;
			v_dat_o <= (others => '-');
			b_dat_i <= v_dat_i;
			a_dat_i <= (others => '-');
		end if;
	end process;

	mem_driver: wb_async_slave
	    generic map (width => v_mem_width, addr_width => v_addr_width)
	    port map (
    		clk_i => clk_i,
		    rst_i => reset_engine,

    		wait_state => wait_state,
    		
    		adr_i => v_adr_o,
			sel_i => v_sel_o,
    		dat_o => v_dat_i,
    		dat_i => v_dat_o,
--    		dat_oi => (others => '0'), -- may not be needed
    		we_i => v_we_o,
    		stb_i => v_stb_o,
    		ack_o => v_ack_i,
    		ack_oi => '0', -- may not be needed

    		a_data => s_data,
    		a_addr => s_addr,
    		a_rdn => s_oen,
    		a_wrn => s_wrn,
    		a_cen => s_cen,
    		a_byen => s_byen
	    );

	s_wrln <= s_wrn or s_byen(0);
	s_wrhn <= s_wrn or s_byen(1);

	addr_decoder: process is
	begin
		wait on reg_stb_i, adr_i;

		reset_core_sel <= '0';
		total0_sel <= '0';
		total1_sel <= '0';
		total2_sel <= '0';
		fifo_treshold_sel <= '0';
		bpp_sel <= '0';
		multi_scan_sel <= '0';
		hbs_sel <= '0';
		hss_sel <= '0';
		hse_sel <= '0';
		htotal_sel <= '0';
		vbs_sel <= '0';
		vss_sel <= '0';
		vse_sel <= '0';
		vtotal_sel <= '0';
		pps_sel <= '0';
		wait_state_sel <= '0';
		sync_pol_sel <= '0';

		if (reg_stb_i = '1') then
			case (adr_i(4 downto 0)) is
				when "00000" => total0_sel <= '1';
				when "00001" => total1_sel <= '1';
				when "00010" => total2_sel <= '1';
				when "00011" => fifo_treshold_sel <= '1';

				when "00100" => hbs_sel <= '1';
				when "00101" => hss_sel <= '1';
				when "00110" => hse_sel <= '1';
				when "00111" => htotal_sel <= '1';

				when "01000" => vbs_sel <= '1';
				when "01001" => vss_sel <= '1';
				when "01010" => vse_sel <= '1';
				when "01011" => vtotal_sel <= '1';

				when "01100" => pps_sel <= '1';
				when "01101" => wait_state_sel <= '1'; sync_pol_sel <= '1';
				when "01110" => bpp_sel <= '1'; multi_scan_sel <= '1'; reset_core_sel <= '1';
				when others =>
			end case;
		end if;
	end process;

    -- TEST SIGNALS
    T_v_we_o  <=   v_we_o;
    T_v_stb_o <=   v_stb_o;
    T_v_ack_i <=   v_ack_i;
    T_v_adr_o <=   v_adr_o;
    T_v_sel_o <=   v_sel_o;
    T_v_dat_o <=   v_dat_o;
    T_v_dat_i <=  v_dat_i;
    
end vga_core;

