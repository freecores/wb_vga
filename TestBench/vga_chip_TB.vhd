library ieee,exemplar;
use ieee.std_logic_1164.all;
use exemplar.exemplar_1164.all;

entity vga_chip_tb is
	-- Generic declarations of the tested unit
	generic(
		v_mem_width : POSITIVE := 16;
		fifo_size : POSITIVE := 256;
		v_addr_width : POSITIVE := 20 );
end vga_chip_tb;

architecture TB of vga_chip_tb is
	-- Component declaration of the tested unit
	component vga_chip
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
    		video_out: out std_logic_vector (7 downto 0)   -- video output binary signal (unused bits are forced to 0)
    	);
	end component;

	-- Stimulus signals - signals mapped to the input and inout ports of tested entity
	signal clk_i : std_logic;
	signal clk_en : std_logic;
	signal rst_i : std_logic;
	signal dat_i : std_logic_vector(7 downto 0);
	signal dat_oi : std_logic_vector(7 downto 0);
	signal cyc_i : std_logic;
	signal ack_oi : std_logic;
	signal we_i : std_logic;
	signal vmem_stb_i : std_logic;
	signal reg_stb_i : std_logic;
	signal adr_i : std_logic_vector(v_addr_width downto 0);
	signal s_data : std_logic_vector((v_mem_width-1) downto 0);
	-- Observed signals - signals mapped to the output ports of tested entity
	signal dat_o : std_logic_vector(7 downto 0);
	signal ack_o : std_logic;
	signal s_addr : std_logic_vector((v_addr_width-1) downto 0);
	signal s_oen : std_logic;
	signal s_wrhn : std_logic;
	signal s_wrln : std_logic;
	signal s_cen : std_logic;
	signal h_sync : std_logic;
	signal h_blank : std_logic;
	signal v_sync : std_logic;
	signal v_blank : std_logic;
	signal h_tc : std_logic;
	signal v_tc : std_logic;
	signal blank : std_logic;
	signal video_out : std_logic_vector(7 downto 0);

	constant reg_total0        : std_logic_vector(v_addr_width downto 0) :=  "000000000000000000000";
	constant reg_total1        : std_logic_vector(v_addr_width downto 0) :=  "000000000000000000001";
	constant reg_total2        : std_logic_vector(v_addr_width downto 0) :=  "000000000000000000010";
	constant reg_fifo_treshold : std_logic_vector(v_addr_width downto 0) :=  "000000000000000000011";
	constant reg_hbs           : std_logic_vector(v_addr_width downto 0) :=  "000000000000000000100";
	constant reg_hss           : std_logic_vector(v_addr_width downto 0) :=  "000000000000000000101";
	constant reg_hse           : std_logic_vector(v_addr_width downto 0) :=  "000000000000000000110";
	constant reg_htotal        : std_logic_vector(v_addr_width downto 0) :=  "000000000000000000111";
	constant reg_vbs           : std_logic_vector(v_addr_width downto 0) :=  "000000000000000001000";
	constant reg_vss           : std_logic_vector(v_addr_width downto 0) :=  "000000000000000001001";
	constant reg_vse           : std_logic_vector(v_addr_width downto 0) :=  "000000000000000001010";
	constant reg_vtotal        : std_logic_vector(v_addr_width downto 0) :=  "000000000000000001011";
	constant reg_pps           : std_logic_vector(v_addr_width downto 0) :=  "000000000000000001100";
	constant reg_ws            : std_logic_vector(v_addr_width downto 0) :=  "000000000000000001101";
	constant reg_bpp           : std_logic_vector(v_addr_width downto 0) :=  "000000000000000001110";
	
	constant val_total0        : std_logic_vector(7 downto 0) :=  "00001111";
	constant val_total1        : std_logic_vector(7 downto 0) :=  "00000000";
	constant val_total2        : std_logic_vector(7 downto 0) :=  "00000000";
	constant val_fifo_treshold : std_logic_vector(7 downto 0) :=  "00000011";
	constant val_hbs           : std_logic_vector(7 downto 0) :=  "00000111";
	constant val_hss           : std_logic_vector(7 downto 0) :=  "00001000";
	constant val_hse           : std_logic_vector(7 downto 0) :=  "00001001";
	constant val_htotal        : std_logic_vector(7 downto 0) :=  "00001010";
	constant val_vbs           : std_logic_vector(7 downto 0) :=  "00000001";
	constant val_vss           : std_logic_vector(7 downto 0) :=  "00000010";
	constant val_vse           : std_logic_vector(7 downto 0) :=  "00000011";
	constant val_vtotal        : std_logic_vector(7 downto 0) :=  "00000100";
	constant val_pps           : std_logic_vector(7 downto 0) :=  "00000001";
	constant val_ws            : std_logic_vector(7 downto 0) :=  "00010010";
--	constant val_bpp           : std_logic_vector(7 downto 0) :=  "00000001";
	constant val_bpp           : std_logic_vector(7 downto 0) :=  "00000011";
	
	-- Add your code here ...
	
	procedure chk_val(
		signal clk_i: in STD_LOGIC;
		signal adr_i: out STD_LOGIC_VECTOR(v_addr_width downto 0);
		signal dat_o: in STD_LOGIC_VECTOR(7 downto 0);
		signal dat_i: out STD_LOGIC_VECTOR(7 downto 0);
		signal we_i: out STD_LOGIC;
		signal cyc_i: out std_logic;
		signal stb_i: out STD_LOGIC;
		signal ack_o: in STD_LOGIC;
		constant addr: in STD_LOGIC_VECTOR(v_addr_width downto 0);
		constant data: in STD_LOGIC_VECTOR(7 downto 0)
	) is
	begin
		wait until clk_i'EVENT and clk_i = '1';
		wait until clk_i'EVENT and clk_i = '1';
		wait until clk_i'EVENT and clk_i = '1';
		adr_i <= addr;
		dat_i <= (others => '0');
		cyc_i <= '1';
		stb_i <= '1';
		we_i <= '0';
		wait until clk_i'EVENT and clk_i = '1' and ack_o = '1';
		assert dat_o = data report "Value does not match!" severity ERROR;
		adr_i <= (others => '0');
		stb_i <= '0';
		cyc_i <= '0';
	end procedure;
	
	procedure write_val(
		signal clk_i: in STD_LOGIC;
		signal adr_i: out STD_LOGIC_VECTOR(v_addr_width downto 0);
		signal dat_o: in STD_LOGIC_VECTOR(7 downto 0);
		signal dat_i: out STD_LOGIC_VECTOR(7 downto 0);
		signal we_i: out STD_LOGIC;
		signal cyc_i: out std_logic;
		signal stb_i: out STD_LOGIC;
		signal ack_o: in STD_LOGIC;
		constant addr: in STD_LOGIC_VECTOR(v_addr_width downto 0);
		constant data: in STD_LOGIC_VECTOR(7 downto 0)
	) is
	begin
		adr_i <= (others => '0');
		dat_i <= (others => '0');
		stb_i <= '0';
		we_i <= '0';
		wait until clk_i'EVENT and clk_i = '1';
		wait until clk_i'EVENT and clk_i = '1';
		wait until clk_i'EVENT and clk_i = '1';
		adr_i <= addr;
		dat_i <= data;
		cyc_i <= '1';
		stb_i <= '1';
		we_i <= '1';
		wait until clk_i'EVENT and clk_i = '1' and ack_o = '1';
		adr_i <= (others => '0');
		dat_i <= (others => '0');
		cyc_i <= '0';
		stb_i <= '0';
		we_i <= '0';
	end procedure;
begin

	-- Unit Under Test port map
	UUT : vga_chip
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
			video_out => video_out
		);

	-- Add your stimulus here ...

	clk_en <= '1';
	-- Add your stimulus here ...
	clock: process is
	begin
		wait for 25 ns;
		clk_i <= '1';
		wait for 25 ns;
		clk_i <= '0';
	end process;
	
	ack_oi <= '0';
	dat_oi <= (others => '0');
	
	setup: process is
	begin
		we_i <= '0';
		reg_stb_i <= '0';
		vmem_stb_i <= '0';
		rst_i <= '1';
		wait until clk_i'EVENT and clk_i = '1';
		wait until clk_i'EVENT and clk_i = '1';
		rst_i <= '0';
		wait until clk_i'EVENT and clk_i = '1';
		wait until clk_i'EVENT and clk_i = '1';
		wait until clk_i'EVENT and clk_i = '1';
		wait until clk_i'EVENT and clk_i = '1';
		
		write_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_total0            ,val_total0);
		write_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_total1            ,val_total1);
		write_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_total2            ,val_total2);
		write_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_fifo_treshold     ,val_fifo_treshold);
		write_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_hbs               ,val_hbs);
		write_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_hss               ,val_hss);
		write_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_hse               ,val_hse);
		write_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_htotal            ,val_htotal);
		write_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_vbs               ,val_vbs);
		write_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_vss               ,val_vss);
		write_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_vse               ,val_vse);
		write_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_vtotal            ,val_vtotal);
		write_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_pps               ,val_pps);
		write_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_ws                ,val_ws);
		write_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_bpp               ,val_bpp);

		wait until clk_i'EVENT and clk_i = '1';
		wait until clk_i'EVENT and clk_i = '1';
		wait until clk_i'EVENT and clk_i = '1';
		wait until clk_i'EVENT and clk_i = '1';
		wait until clk_i'EVENT and clk_i = '1';
		wait until clk_i'EVENT and clk_i = '1';
		wait until clk_i'EVENT and clk_i = '1';

		chk_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_total0            ,val_total0);
		chk_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_total1            ,val_total1);
		chk_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_total2            ,val_total2);
		chk_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_fifo_treshold     ,val_fifo_treshold);
		chk_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_hbs               ,val_hbs);
		chk_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_hss               ,val_hss);
		chk_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_hse               ,val_hse);
		chk_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_htotal            ,val_htotal);
		chk_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_vbs               ,val_vbs);
		chk_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_vss               ,val_vss);
		chk_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_vse               ,val_vse);
		chk_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_vtotal            ,val_vtotal);
		chk_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_pps               ,val_pps);
		chk_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_ws                ,val_ws);
		chk_val(clk_i, adr_i,dat_o,dat_i,we_i,cyc_i,reg_stb_i,ack_o,reg_bpp               ,val_bpp);
		
		wait;
	end process;

	s_ram: process is
	begin
		wait on s_data,s_addr,s_oen,s_wrhn,s_wrln,s_cen;
		if (s_cen = '0') then
			if (s_oen = '0') then
				s_data <= s_addr(v_mem_width-1 downto 0);
			elsif (s_wrhn = '0' or s_wrln = '0') then
				if (s_wrhn = '0') then
				else
				end if;
			else
				s_data <= (others => 'Z');
			end if;
		end if;
	end process;
	
end TB;

configuration TB_vga_chip of vga_chip_tb is
	for TB
		for UUT : vga_chip
			use entity work.vga_chip(vga_chip);
		end for;
	end for;
end TB_vga_chip;

