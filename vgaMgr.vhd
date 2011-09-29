
------------------------------------------------------
--	it's better if you set tab size to 4 spaces!	--
------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use	work.gamePackage.all;

entity vgaMgr is
	port(	clk : in std_logic;
			reset : in std_logic;
			red : in std_logic;
			green : in std_logic;
			blue : in std_logic;
			r : out std_logic;
			g : out std_logic;
			b : out std_logic;
			hsync : out std_logic;
			vsync : out std_logic;
			row : out rowIndexType;
			column : out columnIndexType
		);
end vgaMgr;

architecture vgaSignalGenerator of vgaMgr is
	signal	vertCounterSignal : rowIndexType;
	signal	horizCounterSignal : columnIndexType;

begin
	--	manage either reset ( init signals) or clk raising edge (	increase counters)
	process( clk, reset)
		variable	vertCounter : rowIndexType;
		variable	horizCounter : columnIndexType;
 	begin
		if( reset = '0' ) 
		then
			vertCounter := ( others => '0');
			horizCounter := ( others => '0');
			horizCounterSignal <= ( others => '0');
			vertCounterSignal <= ( others => '0');
		else
			if( clk'event and clk = '1' )
			then
				-- assign values to "global" signals --
				horizCounterSignal <= horizCounter;
				vertCounterSignal <= vertCounter;
				--	simply increment counters	--
				horizCounter := horizCounter + 1;
				if( horizCounter = VGA_H_D )
				then
					horizCounter := ( others => '0');
					vertCounter := vertCounter + 1;
					if( vertCounter = VGA_V_D )
					then
						vertCounter := ( others => '0');
					end if;
				end if;
			end if;
		end if;
	end process;

	--	test counters to generate output rgb values and row and column indexes	--
	process( vertCounterSignal, horizCounterSignal, reset)
	begin
		r <= '0';
		g <= '0';
		b <= '0';
		row <= ( others => '0');
		column <= ( others => '0');
		if( reset = '1' )
		then
			row <= vertCounterSignal;
			column <= horizCounterSignal;
			if( vertCounterSignal < VGA_V_A )
			then
				if( horizCounterSignal < VGA_H_A )
				then
					r <= red;
					g <= green;
					b <= blue;
				end if;
			end if;
		end if;
	end process;

	--	test counters to generate horizontal and vertical synchronization signals	--
	process( horizCounterSignal, vertCounterSignal, reset)
	begin
		hsync <= not HSYNC_ACTIVE_VALUE;
		vsync <= not VSYNC_ACTIVE_VALUE;
		if( reset = '1' )
		then
			if( (horizCounterSignal >= VGA_H_B) and (horizCounterSignal < VGA_H_C) )
			then
				hsync <= HSYNC_ACTIVE_VALUE;
			end if;
			
			if( (vertCounterSignal >= VGA_V_B) and (vertCounterSignal < VGA_V_C) )
			then
				vsync <= VSYNC_ACTIVE_VALUE;
			end if;
--			if( (vertCounterSignal = 492) and (horizCounterSignal >= 700) )
--			then
--				vsync <= '0';
--			end if;
--			if( (vertCounterSignal = 493) and (horizCounterSignal < 700) )
--			then
--				vsync <= '0';
--			end if;
		end if;
	end process;
end vgaSignalGenerator;
