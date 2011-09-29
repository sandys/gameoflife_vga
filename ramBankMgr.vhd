
------------------------------------------------------
--	it's better if you set tab size to 4 spaces!	--
------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use	work.gamePackage.all;

entity ramBankMgr is
	port(	clk : in std_logic;
			reset : in std_logic;
			writeEnable : in std_logic;
			writeAddress : in ramAddressType;
			readAddress : in ramAddressType;
			inputData : in ramBankWordType;
			outputData : out ramBankWordType
		);
end rambankMgr;

--	in this architecture, we give the address we want to read from, but if we also give
--	the writeEnable signal, then the register is written to and new value is read.
--	addressToRead is an internal signal that changes only every clock cycle, 
--	so that the parallel read process knows what address to read from.
architecture ramBankMgrSignalGenerator of ramBankMgr is
	signal	ramMemory : ramBankType;
	signal	addressToRead : ramAddressType;

begin  
	--	one process is dedicated to fill ram words
	process( clk)
	begin
		if( clk'event and clk = '1') 
		then
			addressToRead <= readAddress;
			if( writeEnable = '1' )
			then  
				ramMemory( conv_integer( writeAddress)) <= inputData;
			end if;
		end if;
	end process;
	
	--	another process continuously generates output data
	outputData <= ramMemory( conv_integer( addressToRead));
	
end ramBankMgrSignalGenerator;
