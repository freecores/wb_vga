--
--  Wishbone bus toolkit.
--
--  (c) Copyright Andras Tantos <andras_tantos@yahoo.com> 2001/03/31
--  This code is distributed under the terms and conditions of the GNU General Public Lince.
--
--
-- ELEMENTS:
--   wb_bus_upsize: bus upsizer. Currently only 8->16 bit bus resize is supported
--   wb_async_slave: Wishbone bus to async (SRAM-like) bus slave bridge.
--   wb_arbiter: two-way bus arbiter. Asyncronous logic ensures 0-ws operation on shared bus
--   wb_out_reg: Wishbone bus compatible output register.

library IEEE;
use IEEE.std_logic_1164.all;

package wb_tk is
	component wb_bus_upsize is
		generic (
			m_bus_width: positive := 8; -- master bus width
			m_addr_width: positive := 21; -- master bus width
			s_bus_width: positive := 16; -- slave bus width
			s_addr_width: positive := 20; -- master bus width
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
			s_adr_o: out std_logic_vector (s_addr_width-1 downto 0);
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
	
	component wb_async_master is
		generic (
			width: positive := 16;
			addr_width: positive := 20
		);
		port (
			clk_i: in std_logic;
			rst_i: in std_logic := '0';
			
			-- interface to wb slave devices
			s_adr_o: out std_logic_vector (addr_width-1 downto 0);
			s_sel_o: out std_logic_vector ((width/8)-1 downto 0);
			s_dat_i: in std_logic_vector (width-1 downto 0);
			s_dat_o: out std_logic_vector (width-1 downto 0);
			s_cyc_o: out std_logic;
			s_ack_i: in std_logic;
			s_err_i: in std_logic := '-';
			s_rty_i: in std_logic := '-';
			s_we_o: out std_logic;
			s_stb_o: out std_logic;

			-- interface to asyncron master device
			a_data: inout std_logic_vector (width-1 downto 0) := (others => 'Z');
			a_addr: in std_logic_vector (addr_width-1 downto 0) := (others => 'U');
			a_rdn: in std_logic := '1';
			a_wrn: in std_logic := '1';
			a_cen: in std_logic := '1';
			a_byen: in std_logic_vector ((width/8)-1 downto 0);
			a_waitn: out std_logic
		);
	end component;
	
	component wb_async_slave is
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
	
	component wb_arbiter is
		port (
	--		clk_i: in std_logic;
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
	
	component wb_out_reg is
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
end wb_tk;

-------------------------------------------------------------------------------
--
--  wb_bus_upsize
--
-------------------------------------------------------------------------------

library IEEE;
library synopsys;
use IEEE.std_logic_1164.all;
use synopsys.std_logic_arith.all;

library work;
use work.technology.all;

entity wb_bus_upsize is
	generic (
		m_bus_width: positive := 8; -- master bus width
		m_addr_width: positive := 21; -- master bus width
		s_bus_width: positive := 16; -- slave bus width
		s_addr_width: positive := 20; -- master bus width
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
		s_adr_o: out std_logic_vector (s_addr_width-1 downto 0);
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
end wb_bus_upsize;

architecture wb_bus_upsize of wb_bus_upsize is
	function log2(inp : integer) return integer is
	begin
		if (inp < 1) then return 0; end if;
		if (inp < 2) then return 0; end if;
		if (inp < 4) then return 1; end if;
		if (inp < 8) then return 2; end if;
		if (inp < 16) then return 3; end if;
		if (inp < 32) then return 4; end if;
		if (inp < 64) then return 5; end if;
		if (inp < 128) then return 6; end if;
		if (inp < 256) then return 7; end if;
		if (inp < 512) then return 8; end if;
		if (inp < 1024) then return 9; end if;
		if (inp < 2048) then return 10; end if;
		if (inp < 4096) then return 11; end if;
		if (inp < 8192) then return 12; end if;
		if (inp < 16384) then return 13; end if;
		if (inp < 32768) then return 14; end if;
		if (inp < 65538) then return 15; end if;
		return 16;
	end;
	function equ(a : std_logic_vector; b : integer) return boolean is
		variable b_s : std_logic_vector(a'RANGE);
	begin
		b_s := CONV_STD_LOGIC_VECTOR(b,a'HIGH+1);
		return (a = b_s);
	end;
	constant addr_diff: integer := log2(s_bus_width/m_bus_width);
	signal i_m_dat_o: std_logic_vector(m_bus_width-1 downto 0);
begin
	assert (m_addr_width = s_addr_width+addr_diff) report "Address widths are not consistent" severity FAILURE;
	s_adr_o <= m_adr_i(m_addr_width-addr_diff downto addr_diff);
	s_we_o <= m_we_i;
	m_ack_o <= (m_stb_i and s_ack_i) or (not m_stb_i and m_ack_oi);
	m_err_o <= (m_stb_i and s_err_i) or (not m_stb_i and m_err_oi);
	m_rty_o <= (m_stb_i and s_rty_i) or (not m_stb_i and m_rty_oi);
	s_stb_o <= m_stb_i;
	s_cyc_o <= m_cyc_i;
	

	sel_dat_mux: process is
	begin
		wait on s_dat_i, m_adr_i;
		if (little_endien) then
			for i in s_sel_o'RANGE loop
				if (equ(m_adr_i(addr_diff-1 downto 0),i)) then
					s_sel_o(i) <= '1';
					i_m_dat_o <= s_dat_i(8*i+7 downto 8*i+0);
				else
					s_sel_o(i) <= '0';
				end if;
			end loop;
		else
			for i in s_sel_o'RANGE loop
				if (equ(m_adr_i(addr_diff-1 downto 0),i)) then
					s_sel_o(s_sel_o'HIGH-i) <= '1';
					i_m_dat_o <= s_dat_i(s_dat_i'HIGH-8*i downto s_dat_i'HIGH-8*i-7);
				else
					s_sel_o(s_sel_o'HIGH-i) <= '0';
				end if;
			end loop;
		end if;
	end process;

	d_i_for: for i in m_dat_o'RANGE generate
    	m_dat_o(i) <= (m_stb_i and i_m_dat_o(i)) or (not m_stb_i and m_dat_oi(i));
	end generate;

	d_o_for: for i in s_sel_o'RANGE generate
		s_dat_o(8*i+7 downto 8*i+0) <= m_dat_i;
	end generate;
end wb_bus_upsize;

-------------------------------------------------------------------------------
--
--  wb_async_master
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.technology.all;

entity wb_async_master is
	generic (
		width: positive := 16;
		addr_width: positive := 20
	);
	port (
		clk_i: in std_logic;
		rst_i: in std_logic := '0';
		
		-- interface to wb slave devices
		s_adr_o: out std_logic_vector (addr_width-1 downto 0);
		s_sel_o: out std_logic_vector ((width/8)-1 downto 0);
		s_dat_i: in std_logic_vector (width-1 downto 0);
		s_dat_o: out std_logic_vector (width-1 downto 0);
		s_cyc_o: out std_logic;
		s_ack_i: in std_logic;
		s_err_i: in std_logic := '-';
		s_rty_i: in std_logic := '-';
		s_we_o: out std_logic;
		s_stb_o: out std_logic;

		-- interface to asyncron master device
		a_data: inout std_logic_vector (width-1 downto 0) := (others => 'Z');
		a_addr: in std_logic_vector (addr_width-1 downto 0) := (others => 'U');
		a_rdn: in std_logic := '1';
		a_wrn: in std_logic := '1';
		a_cen: in std_logic := '1';
		a_byen: in std_logic_vector ((width/8)-1 downto 0);
		a_waitn: out std_logic
	);
end wb_async_master;

architecture wb_async_master of wb_async_master is
	component d_ff
		port (  d  :  in STD_LOGIC;
				clk:  in STD_LOGIC;
		        ena:  in STD_LOGIC := '1';
		        clr:  in STD_LOGIC := '0';
		        pre:  in STD_LOGIC := '0';
				q  :  out STD_LOGIC
		);
	end component;
	signal wg_clk, wg_pre, wg_q: std_logic;
	signal i_cyc_o, i_stb_o, i_we_o: std_logic;
	signal i_waitn: std_logic;
begin
	ctrl: process is
	begin
		wait until clk_i'EVENT and clk_i = '1';
		if (rst_i = '1') then
			i_cyc_o <= '0';
			i_stb_o <= '0';
			i_we_o <= '0';
		else
			if (a_cen = '0') then
			 	i_stb_o <= not (a_rdn and a_wrn);
				i_we_o <= not a_wrn;
				i_cyc_o <= '1';
			else
				i_cyc_o <= '0';
				i_stb_o <= '0';
				i_we_o <= '0';
			end if;
		end if;
	end process;
	s_cyc_o <= i_cyc_o and not i_waitn;
	s_stb_o <= i_stb_o and not i_waitn;
	s_we_o <= i_we_o and not i_waitn;

	w_ff1: d_ff port map (
		d => s_ack_i,
		clk => clk_i,
		ena => '1',
		clr => rst_i,
		pre => '0',
		q => wg_q
	);
	
	wg_clk <= not a_cen;
	wg_pre <= wg_q or rst_i;
	w_ff2: d_ff port map (
		d => '0',
		clk => wg_clk,
		ena => '1',
		clr => '0',
		pre => wg_pre,
		q => i_waitn
	);
	a_waitn <= i_waitn;

	s_adr_o <= a_addr;
	negate: for i in s_sel_o'RANGE generate s_sel_o(i) <= not a_byen(i); end generate;
	s_dat_o <= a_data;

	a_data_out: process is
	begin
		wait on s_dat_i, a_rdn, a_cen;
		if (a_rdn = '0' and a_cen = '0') then
			a_data <= s_dat_i;
		else
			a_data <= (others => 'Z');
		end if;
	end process;
end wb_async_master;

-------------------------------------------------------------------------------
--
--  wb_async_slave
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.technology.all;

entity wb_async_slave is
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
end wb_async_slave;

architecture wb_async_slave of wb_async_slave is
	-- multiplexed access signals to memory
	signal i_ack: std_logic;
	signal sm_ack: std_logic;

	type states is (sm_idle, sm_wait, sm_deact);
	signal state: states;
	signal cnt: std_logic_vector(3 downto 0);
begin
	ack_o <= (stb_i and i_ack) or (not stb_i and ack_oi);
	dat_o_gen: for i in dat_o'RANGE generate
	    dat_o(i) <= (stb_i and a_data(i)) or (not stb_i and dat_oi(i));
	end generate;
	
	-- For 0WS operation i_ack is an async signal otherwise it's a sync one.
	i_ack_gen: process is
	begin
		wait on sm_ack, stb_i, wait_state, state;
		if (wait_state = "0000") then
			case (state) is
				when sm_deact => i_ack <= '0';
				when others => i_ack <= stb_i;
			end case;
		else
			i_ack <= sm_ack;
		end if;
	end process;
	
	-- SRAM signal-handler process
	sram_signals: process is
	begin
		wait on state,we_i,a_data,adr_i,rst_i, stb_i, sel_i, dat_i;
		if (rst_i = '1') then
			a_wrn <= '1';
			a_rdn <= '1';
			a_cen <= '1';
			a_addr <= (others => '-');
			a_data <= (others => 'Z');
    		a_byen <= (others => '1');
		else
			case (state) is
				when sm_deact =>
					a_wrn <= '1';
					a_rdn <= '1';
					a_cen <= '1';
					a_addr <= (others => '-');
					a_data <= (others => 'Z');
            		a_byen <= (others => '1');
				when others =>
					a_addr <= adr_i;
					a_rdn <= not (not we_i and stb_i);
					a_wrn <= not (we_i and stb_i);
					a_cen <= not stb_i;
            		a_byen <= not sel_i;
					if (we_i = '1') then 
						a_data <= dat_i; 
					else
						a_data <= (others => 'Z');
					end if;
			end case;
		end if;
	end process;

	-- Aysnc access state-machine.
	async_sm: process is
--		variable cnt: std_logic_vector(3 downto 0) := "0000";
--		variable state: states := init;
	begin
		wait until clk_i'EVENT and clk_i = '1';
		if (rst_i = '1') then
			state <= sm_idle;
			cnt <= ((0) => '1', others => '0');
			sm_ack <= '0';
		else
			case (state) is
				when sm_idle =>
					-- Check if anyone needs access to the memory.
					-- it's rdy signal will already be pulled low, so we only have to start the access
					if (stb_i = '1') then
						case wait_state is
							when "0000" =>
								sm_ack <= '1';
								state <= sm_deact;
							when "0001" =>
								sm_ack <= '1';
								cnt <= "0001";
								state <= sm_wait;
							when others =>
								sm_ack <= '0';
								cnt <= "0001";
								state <= sm_wait;
						end case;
					end if;
				when sm_wait =>
					if (cnt = wait_state) then
						-- wait cycle completed.
						state <= sm_deact;
						sm_ack <= '0';
						cnt <= "0000";
					else
						if (add_one(cnt) = wait_state) then
							sm_ack <= '1';
						else
							sm_ack <= '0';
						end if;
						cnt <= add_one(cnt);
					end if;
				when sm_deact =>
					if (stb_i = '1') then
						case wait_state is
							when "0000" =>
								cnt <= "0000";
								sm_ack <= '0';
								state <= sm_wait;
							when others =>
								sm_ack <= '0';
								cnt <= "0000";
								state <= sm_wait;
						end case;
					else
						sm_ack <= '0';
						state <= sm_idle;
					end if;
			end case;
		end if;
	end process;
end wb_async_slave;

-------------------------------------------------------------------------------
--
--  wb_arbiter
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.technology.all;

entity wb_arbiter is
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
end wb_arbiter;

-- This acthitecture is a clean asyncron state-machine. However it cannot be mapped to FPGA architecture
architecture behaviour of wb_arbiter is
	type states is (idle,aa,ba);
	signal i_mux_signal: std_logic;
	
	signal e_state: states;
begin
	mux_signal <= i_mux_signal;
	
	sm: process is
		variable state: states;
	begin
		wait on a_cyc_i, b_cyc_i, priority, rst_i;
		if (rst_i = '1') then 
			state := idle;
			i_mux_signal <= priority;
		else
			case (state) is
				when idle =>
					if (a_cyc_i = '1' and (priority = '0' or b_cyc_i = '0')) then
						state := aa;
						i_mux_signal <= '0';
					elsif (b_cyc_i = '1' and (priority = '1' or a_cyc_i = '0')) then
						state := ba;
						i_mux_signal <= '1';
					else
						i_mux_signal <= priority;
					end if;
				when aa =>
					if (a_cyc_i = '0') then
						if (b_cyc_i = '1') then
							state := ba;
							i_mux_signal <= '1';
						else
							state := idle;
							i_mux_signal <= priority;
						end if;
					else
						i_mux_signal <= '0';
					end if;
				when ba =>
					if (b_cyc_i = '0') then
						if (a_cyc_i = '1') then
							state := aa;
							i_mux_signal <= '0';
						else
							state := idle;
							i_mux_signal <= priority;
						end if;
					else
						i_mux_signal <= '1';
					end if;
			end case;
		end if;
		e_state <= state;
	end process;
	
	signal_mux: process is
	begin
		wait on a_we_i, a_stb_i, a_ack_oi, a_err_oi, a_rty_oi, a_cyc_i,
				b_we_i, b_stb_i, b_ack_oi, b_err_oi, b_rty_oi, b_cyc_i,
				s_ack_i, s_err_i, s_rty_i, i_mux_signal;
		if (i_mux_signal = '0') then
			s_we_o <= a_we_i;
			s_stb_o <= a_stb_i;
			s_cyc_o <= a_cyc_i;
			a_ack_o <= (a_stb_i and s_ack_i) or (not a_stb_i and a_ack_oi);
			a_err_o <= (a_stb_i and s_err_i) or (not a_stb_i and a_err_oi);
			a_rty_o <= (a_stb_i and s_rty_i) or (not a_stb_i and a_rty_oi);
			b_ack_o <= (b_stb_i and '0') or (not b_stb_i and b_ack_oi);
			b_err_o <= (b_stb_i and '0') or (not b_stb_i and b_err_oi);
			b_rty_o <= (b_stb_i and '0') or (not b_stb_i and b_rty_oi);
		else
			s_we_o <= b_we_i;
			s_stb_o <= b_stb_i;
			s_cyc_o <= b_cyc_i;
			b_ack_o <= (b_stb_i and s_ack_i) or (not b_stb_i and b_ack_oi);
			b_err_o <= (b_stb_i and s_err_i) or (not b_stb_i and b_err_oi);
			b_rty_o <= (b_stb_i and s_rty_i) or (not b_stb_i and b_rty_oi);
			a_ack_o <= (a_stb_i and '0') or (not a_stb_i and a_ack_oi);
			a_err_o <= (a_stb_i and '0') or (not a_stb_i and a_err_oi);
			a_rty_o <= (a_stb_i and '0') or (not a_stb_i and a_rty_oi);
		end if;
	end process;
end behaviour;

-- This acthitecture is a more-or-less structural implementation. Fits for FPGA realization.
architecture FPGA of wb_arbiter is
	component d_ff
		port (  d  :  in STD_LOGIC;
				clk:  in STD_LOGIC;
		        ena:  in STD_LOGIC := '1';
		        clr:  in STD_LOGIC := '0';
		        pre:  in STD_LOGIC := '0';
				q  :  out STD_LOGIC
		);
	end component;
	
	signal i_mux_signal: std_logic;
	
	type states is (idle,aa,ba,XX);
	signal e_state: states;

	-- signals for a DFF in FPGA
	signal idle_s, aa_s, ba_s: std_logic;
	
	signal aa_clk, aa_ena, aa_clr, aa_pre: std_logic;
	signal ba_clk, ba_ena, ba_clr, ba_pre: std_logic;

begin
	mux_signal <= i_mux_signal;
	
	idle_s <= not (a_cyc_i or b_cyc_i);
	
	aa_clr <= rst_i or not a_cyc_i;
	aa_clk <= a_cyc_i;
	aa_ena <= not b_cyc_i and priority;
	aa_pre <= (a_cyc_i and not priority and not ba_s) or (a_cyc_i and not b_cyc_i);
	aa_ff: d_ff port map (
		d => '1',
		clk => aa_clk,
		ena => aa_ena,
		clr => aa_clr,
		pre => aa_pre,
		q => aa_s
	);
	
	ba_clr <= rst_i or not b_cyc_i;
	ba_clk <= b_cyc_i;
	ba_ena <= not a_cyc_i and not priority;
	ba_pre <= (b_cyc_i and priority and not aa_s) or (b_cyc_i and not a_cyc_i);
	ba_ff: d_ff port map (
		d => '1',
		clk => ba_clk,
		ena => ba_ena,
		clr => ba_clr,
		pre => ba_pre,
		q => ba_s
	);
	
	i_mux_signal <= (priority and idle_s) or ba_s;
	
	signal_mux: process is
	begin
		wait on a_we_i, a_stb_i, a_ack_oi, a_err_oi, a_rty_oi, a_cyc_i,
				b_we_i, b_stb_i, b_ack_oi, b_err_oi, b_rty_oi, b_cyc_i,
				s_ack_i, s_err_i, s_rty_i, i_mux_signal;
		if (i_mux_signal = '0') then
			s_we_o <= a_we_i;
			s_stb_o <= a_stb_i;
			s_cyc_o <= a_cyc_i;
			a_ack_o <= (a_stb_i and s_ack_i) or (not a_stb_i and a_ack_oi);
			a_err_o <= (a_stb_i and s_err_i) or (not a_stb_i and a_err_oi);
			a_rty_o <= (a_stb_i and s_rty_i) or (not a_stb_i and a_rty_oi);
			b_ack_o <= (b_stb_i and '0') or (not b_stb_i and b_ack_oi);
			b_err_o <= (b_stb_i and '0') or (not b_stb_i and b_err_oi);
			b_rty_o <= (b_stb_i and '0') or (not b_stb_i and b_rty_oi);
		else
			s_we_o <= b_we_i;
			s_stb_o <= b_stb_i;
			s_cyc_o <= b_cyc_i;
			b_ack_o <= (b_stb_i and s_ack_i) or (not b_stb_i and b_ack_oi);
			b_err_o <= (b_stb_i and s_err_i) or (not b_stb_i and b_err_oi);
			b_rty_o <= (b_stb_i and s_rty_i) or (not b_stb_i and b_rty_oi);
			a_ack_o <= (a_stb_i and '0') or (not a_stb_i and a_ack_oi);
			a_err_o <= (a_stb_i and '0') or (not a_stb_i and a_err_oi);
			a_rty_o <= (a_stb_i and '0') or (not a_stb_i and a_rty_oi);
		end if;
	end process;
	
	gen_e_state: process is
	begin
		wait on idle_s,aa_s,ba_s;
		   if (idle_s = '1' and ba_s = '0' and aa_s = '0') then e_state <= idle;
		elsif (idle_s = '0' and ba_s = '1' and aa_s = '0') then e_state <= aa;
		elsif (idle_s = '0' and ba_s = '0' and aa_s = '1') then e_state <= ba;
		else                                                    e_state <= XX;
		end if;
	end process;
end FPGA;

-------------------------------------------------------------------------------
--
--  wb_out_reg
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

library work;
use work.technology.all;

entity wb_out_reg is
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
end wb_out_reg;

architecture wb_out_reg of wb_out_reg is
	signal content : std_logic_vector (width-1 downto 0);
begin
	-- output bus handling with logic
	gen_dat_o: process is
		variable rd_sel: std_logic;
	begin
		wait on dat_oi, we_i, stb_i, content;
		rd_sel := stb_i and not we_i;
		for i in bus_width-1 downto 0 loop
			if (i >= offset and i < offset+width) then
				dat_o(i) <= (dat_oi(i) and not rd_sel) or (content(i-offset) and rd_sel);
			else
				dat_o(i) <= dat_oi(i);
			end if;
		end loop;
	end process;

  -- this item never generates any wait-states	
	ack_o <= stb_i or ack_oi;
	
	reg: process is
	begin
		wait until clk_i'EVENT and clk_i='1';
		if (rst_i = '1') then
			content <= rst_val;
		else 
			if (stb_i = '1' and we_i = '1') then
				content <=  dat_i(width+offset-1 downto offset);
			end if;
		end if;
	end process;
	q <= content;
end wb_out_reg;
