--
--  File: vga_chip.vhd
--
--  (c) Copyright Andras Tantos <andras_tantos@yahoo.com> 2001/03/31
--  This code is distributed under the terms and conditions of the GNU General Public Lince.
--

library IEEE;
use IEEE.std_logic_1164.all;

package constants is
    constant v_dat_width: positive := 16;
    constant v_adr_width : positive := 20;
    constant cpu_dat_width: positive := 8;
    constant cpu_adr_width: positive := 21;
    constant fifo_size: positive := 256;
--	constant addr_diff: integer := log2(cpu_dat_width/v_dat_width);
end constants;

library IEEE;
use IEEE.std_logic_1164.all;

library wb_vga;
use wb_vga.all;
use wb_vga.constants.all;

library wb_tk;
use wb_tk.all;
use wb_tk.technology.all;


-- same as VGA_CORE but without generics. Suited for post-layout simulation.
entity vga_chip is
	port (
		clk_i: in std_logic;
		clk_en: in std_logic := '1';
		rst_i: in std_logic := '0';

		-- CPU bus interface
		dat_i: in std_logic_vector (cpu_dat_width-1 downto 0);
		dat_oi: in std_logic_vector (cpu_dat_width-1 downto 0);
		dat_o: out std_logic_vector (cpu_dat_width-1 downto 0);
		cyc_i: in std_logic;
		ack_o: out std_logic;
		ack_oi: in std_logic;
		we_i: in std_logic;
		vmem_stb_i: in std_logic;
		reg_stb_i: in std_logic;
		adr_i: in std_logic_vector (cpu_adr_width-1 downto 0);
        sel_i: in std_logic_vector ((cpu_dat_width/8)-1 downto 0) := (others => '1');

		-- video memory SRAM interface
		s_data : inout std_logic_vector(v_dat_width-1 downto 0);
		s_addr : out std_logic_vector(v_adr_width-1 downto 0);
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
		video_out: out std_logic_vector (7 downto 0)   -- video output binary signal (unused bits are forced to 0)
	);
end vga_chip;

architecture vga_chip of vga_chip is
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
		a_byen: out std_logic_vector ((width/8)-1 downto 0)
	);
	end component;

	component vga_core
    	generic (
    		-- cannot be overwritten at the moment...
    		v_dat_width: positive := 16;
    		v_adr_width : positive := 20;
    		cpu_dat_width: positive := 8;
    		cpu_adr_width: positive := 21;
    		fifo_size: positive := 256
    	);
    	port (
    		clk_i: in std_logic;
    		clk_en: in std_logic := '1';
    		rst_i: in std_logic := '0';

    		-- CPU bus interface
    		cyc_i: in std_logic;
    		we_i: in std_logic;
    		vmem_stb_i: in std_logic;   -- selects video memory
        	total_stb_i: in std_logic;    -- selects total register
        	ofs_stb_i: in std_logic;      -- selects offset register
        	reg_bank_stb_i: in std_logic; -- selects all other registers (in a single bank)
    		ack_o: out std_logic;
    		ack_oi: in std_logic;
    		adr_i: in std_logic_vector (v_adr_width downto 0);
            sel_i: in std_logic_vector ((cpu_dat_width/8)-1 downto 0) := (others => '1');
    		dat_i: in std_logic_vector (cpu_dat_width-1 downto 0);
    		dat_oi: in std_logic_vector (cpu_dat_width-1 downto 0);
    		dat_o: out std_logic_vector (cpu_dat_width-1 downto 0);

    		-- video memory interface
    		v_adr_o: out std_logic_vector (v_adr_width-1 downto 0);
    		v_sel_o: out std_logic_vector ((v_dat_width/8)-1 downto 0);
    		v_dat_i: in std_logic_vector (v_dat_width-1 downto 0);
    		v_dat_o: out std_logic_vector (v_dat_width-1 downto 0);
    		v_cyc_o: out std_logic;
    		v_ack_i: in std_logic;
    		v_we_o: out std_logic;
    		v_stb_o: out std_logic;

    		-- sync blank and video signal outputs
    		h_sync: out std_logic;
    		h_blank: out std_logic;
    		v_sync: out std_logic;
    		v_blank: out std_logic;
    		h_tc: out std_logic;
    		v_tc: out std_logic;
    		blank: out std_logic;
    		video_out: out std_logic_vector (7 downto 0)  -- video output binary signal (unused bits are forced to 0)
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

        cyc_i: in std_logic := '1';
		stb_i: in std_logic;
        sel_i: in std_logic_vector ((bus_width/8)-1 downto 0) := (others => '1');
		we_i: in std_logic;
		ack_o: out std_logic;
		ack_oi: in std_logic := '-';
		adr_i: in std_logic_vector (size2bits((width+offset+bus_width-1)/bus_width)-1 downto 0) := (others => '0');
		dat_i: in std_logic_vector (bus_width-1 downto 0);
		dat_oi: in std_logic_vector (bus_width-1 downto 0) := (others => '-');
		dat_o: out std_logic_vector (bus_width-1 downto 0);
		q: out std_logic_vector (width-1 downto 0)
	);
	end component;

    signal total_stb: std_logic;
    signal ofs_stb: std_logic;
    signal reg_bank_stb: std_logic;
    signal ws_stb: std_logic;
    signal wait_state: std_logic_vector(3 downto 0);

	signal v_adr_o: std_logic_vector (v_adr_width-1 downto 0);
	signal v_sel_o: std_logic_vector ((v_dat_width/8)-1 downto 0);
	signal v_dat_i: std_logic_vector (v_dat_width-1 downto 0);
	signal v_dat_o: std_logic_vector (v_dat_width-1 downto 0);
	signal v_cyc_o: std_logic;
	signal v_ack_i: std_logic;
	signal v_we_o: std_logic;
	signal v_stb_o: std_logic;

	signal s_byen : std_logic_vector((v_dat_width/8)-1 downto 0);
	
	signal ws_dat_o: std_logic_vector(cpu_dat_width-1 downto 0);
	signal ws_ack_o: std_logic;
	
	signal s_wrn: std_logic;
begin
	ws_reg: wb_out_reg
		generic map( width => 4, bus_width => cpu_dat_width , offset => 0 )
		port map(
    		stb_i => ws_stb,
    		q => wait_state,
    		rst_val => "1111",
    		dat_oi => dat_oi,
    		dat_o => ws_dat_o,
    		ack_oi => ack_oi,
    		ack_o => ws_ack_o,
    		adr_i => adr_i(0 downto 0), -- range should be calculated !!!
    		sel_i => sel_i, cyc_i => cyc_i, we_i => we_i, clk_i => clk_i, rst_i => rst_i, dat_i => dat_i );

	core : vga_core
    	generic map (
    		v_dat_width => v_dat_width,
    		v_adr_width => v_adr_width,
    		cpu_dat_width => cpu_dat_width,
    		cpu_adr_width => cpu_adr_width,
    		fifo_size => fifo_size
    	)
		port map (
    		clk_i => clk_i,
		    clk_en => clk_en,
		    rst_i => rst_i,
    		-- CPU bus interface
    		cyc_i => cyc_i,
		    we_i => we_i,
		    vmem_stb_i => vmem_stb_i,
		    total_stb_i => total_stb,
		    ofs_stb_i => ofs_stb,
		    reg_bank_stb_i => reg_bank_stb,
		    ack_o => ack_o,
		    ack_oi => ws_ack_o,
		    adr_i => adr_i,
		    sel_i => sel_i,
    		dat_i => dat_i,
		    dat_oi => ws_dat_o,
		    dat_o => dat_o,
    		-- video memory interface
    		v_adr_o => v_adr_o,
    		v_sel_o => v_sel_o,
    		v_dat_i => v_dat_i,
    		v_dat_o => v_dat_o,
    		v_cyc_o => v_cyc_o,
    		v_ack_i => v_ack_i,
    		v_we_o => v_we_o,
    		v_stb_o => v_stb_o,

    		h_sync => h_sync,
		    h_blank => h_blank,
		    v_sync => v_sync,
		    v_blank => v_blank,
		    h_tc => h_tc,
		    v_tc => v_tc,
		    blank => blank,
    		video_out => video_out
		);

	mem_driver: wb_async_slave
	    generic map (width => v_dat_width, addr_width => v_adr_width)
	    port map (
    		clk_i => clk_i,
		    rst_i => rst_i,

    		wait_state => wait_state,

    		adr_i => v_adr_o,
			sel_i => v_sel_o,
    		dat_o => v_dat_i,
    		dat_i => v_dat_o,
--    		dat_oi => (others => '0'),
    		we_i => v_we_o,
    		stb_i => v_stb_o,
    		ack_o => v_ack_i,
    		ack_oi => '0',

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

        total_stb <= '0';
        ofs_stb <= '0';
        reg_bank_stb <= '0';
        ws_stb <= '0';

		if (reg_stb_i = '1') then
			case (adr_i(4)) is
				when '0' => 
        			case (adr_i(3 downto 2)) is
        				when "00" => total_stb <= '1';
        				when "01" => ofs_stb <= '1';
        				when "10" => ws_stb <= '1';
        				when others => 
        			end case;
				when '1' => reg_bank_stb <= '1';
				when others => 
			end case;
		end if;
	end process;

end vga_chip;
