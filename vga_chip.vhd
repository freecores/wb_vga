--
--  File: vga_chip.vhd
--
--  (c) Copyright Andras Tantos <andras_tantos@yahoo.com> 2001/03/31
--  This code is distributed under the terms and conditions of the GNU General Public Lince.
--

library IEEE;
use IEEE.std_logic_1164.all;

-- same as VGA_CORE but without generics. Suited for post-layout simulation.
entity vga_chip is
	port (
		clk_i: in std_logic;
		clk_en: in std_logic := '1';
		rst_i: in std_logic := '0';

		-- CPU bus interface
		dat_i: in std_logic_vector (8-1 downto 0);
		dat_oi: in std_logic_vector (8-1 downto 0);
		dat_o: out std_logic_vector (8-1 downto 0);
		cyc_i: in std_logic;
		ack_o: out std_logic;
		ack_oi: in std_logic;
		we_i: in std_logic;
		vmem_stb_i: in std_logic;
		reg_stb_i: in std_logic;
		adr_i: in std_logic_vector (20 downto 0);

		-- video memory SRAM interface
		s_data : inout std_logic_vector((16-1) downto 0);
		s_addr : out std_logic_vector((20-1) downto 0);
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
		video_out: out std_logic_vector (7 downto 0);   -- video output binary signal (unused bits are forced to 0)

        -- TEST SIGNALS
	    T_v_we_o: out std_logic;
	    T_v_stb_o: out std_logic;
	    T_v_ack_i: out std_logic;
	    T_v_adr_o : out std_logic_vector((20-1) downto 0);
	    T_v_sel_o : out std_logic_vector((16/8)-1 downto 0);
	    T_v_dat_o : out std_logic_vector((16-1) downto 0);
	    T_v_dat_i : out std_logic_vector((16-1) downto 0)
	);
end vga_chip;

architecture vga_chip of vga_chip is
	component vga_core
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
	end component;
begin
	Core : vga_core
		port map (
    		clk_i => clk_i,
		    clk_en => clk_en,
		    rst_i => rst_i,
    		dat_i => dat_i,
		    dat_oi => dat_oi,
		    dat_o => dat_o,
    		cyc_i => cyc_i,
		    ack_o => ack_o,
		    ack_oi => ack_oi,
		    we_i => we_i,
		    vmem_stb_i => vmem_stb_i,
		    reg_stb_i => reg_stb_i,
		    adr_i => adr_i,
    		s_data => s_data,
		    s_addr => s_addr,
		    s_oen => s_oen,
		    s_wrhn => s_wrhn,
		    s_wrln => s_wrln,
		    s_cen => s_cen,
    		h_sync => h_sync,
		    h_blank => h_blank,
		    v_sync => v_sync,
		    v_blank => v_blank,
		    h_tc => h_tc,
		    v_tc => v_tc,
		    blank => blank,
    		video_out => video_out,

    	    T_v_we_o  =>  T_v_we_o, 
    	    T_v_stb_o =>  T_v_stb_o,
    	    T_v_ack_i =>  T_v_ack_i,
    	    T_v_adr_o =>  T_v_adr_o,
    	    T_v_sel_o =>  T_v_sel_o,
    	    T_v_dat_o =>  T_v_dat_o,
    	    T_v_dat_i =>  T_v_dat_i
		);
end vga_chip;
