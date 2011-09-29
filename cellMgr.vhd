
------------------------------------------------------
--	it's better if you set tab size to 4 spaces!	--
------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use	work.gamePackage.all;

entity cellMgr is
	port (	clk : in std_logic;
			reset : in std_logic;
			topLeft : in std_logic;
			top : in std_logic;
			topRight : in std_logic;
			left : in std_logic;
			middle : in std_logic;
			right : in std_logic;
			bottomLeft : in std_logic;
			bottom : in std_logic;
			bottomRight : in std_logic;
			output : out std_logic
		);
end cellMgr;

architecture	cellMgrSignalGenerator of cellMgr is
begin	
	--	generate output value
	process( clk)
		variable	numberOfAliveNeighbours : integer;
	begin
		if( clk'event and clk = '1')
		then
			numberOfAliveNeighbours := conv_integer( topLeft);
			numberOfAliveNeighbours := numberOfAliveNeighbours + conv_integer( top);
			numberOfAliveNeighbours := numberOfAliveNeighbours + conv_integer( topRight);
			numberOfAliveNeighbours := numberOfAliveNeighbours + conv_integer( left);
			numberOfAliveNeighbours := numberOfAliveNeighbours + conv_integer( right);
			numberOfAliveNeighbours := numberOfAliveNeighbours + conv_integer( bottomLeft);
			numberOfAliveNeighbours := numberOfAliveNeighbours + conv_integer( bottom);
			numberOfAliveNeighbours := numberOfAliveNeighbours + conv_integer( bottomRight);
			if( numberOfAliveNeighbours = 3 )
			then
				output <= '1';
			elsif( numberOfAliveNeighbours = 2 )
			then
				output <= middle;
			else
				output <= '0';
			end if;			
		end if;
	end process;

end cellMgrSignalGenerator;


