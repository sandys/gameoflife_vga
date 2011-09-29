
------------------------------------------------------
--	it's better if you set tab size to 4 spaces!	--
------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use	work.gamePackage.all;

entity game is
	port(	clk : in std_logic;
			reset : in std_logic;
			r : out std_logic;
			g : out std_logic;
			b : out std_logic;
			hsync : out std_logic;
			vsync : out std_logic
		);
end game;

architecture gameInstance of game is
	--	some internal signals are needed to connect instances of our entities
	signal	horizontalSyncInternal : std_logic;
	signal	verticalSyncInternal: std_logic;
	signal	bufferMgrRedToVgaMgr : std_logic;
	signal	bufferMgrGreenToVgaMgr : std_logic;
	signal	bufferMgrBlueToVgaMgr : std_logic;
	signal	currentRow : rowIndexType;
	signal	currentColumn : columnIndexType;
	signal	ramWriteEnable : std_logic;
	signal	ramWriteAddress : ramAddressType;
	signal	ramReadAddress : ramAddressType;
	signal	ramToBufferMgr : rowType;
	signal	bufferMgrToRam : rowType;
	signal	bufferMgr0ToCellMgr : borderedParallelWordType;
	signal	bufferMgr1ToCellMgr : borderedParallelWordType;
	signal	bufferMgr2ToCellMgr : borderedParallelWordType;
	signal	cellMgrToBufferMgr : parallelWordType;
	--signal	i : integer;

begin

	--	connect output RGB synchronization signals
	hsync <= horizontalSyncInternal;
	vsync <= verticalSyncInternal;
	
	--	instantiate and connect vgaMgr			
	vgaMgrInstance : vgaMgr
		port map(	clk => clk,
					reset => reset,
					red => bufferMgrRedToVgaMgr,
					green => bufferMgrGreenToVgaMgr,
					blue => bufferMgrBlueToVgaMgr,
					r => r,
					g => g,
					b => b,
					hsync => horizontalSyncInternal,
					vsync => verticalSyncInternal,
					row => currentRow,
					column => currentColumn
				);

	--	instantiate and connect bufferMgr
	bufferMgrInstance : bufferMgr 
		port map(	clk => clk,
					reset => reset,
					horizontalSync => horizontalSyncInternal,
					verticalSync => verticalSyncInternal,
					currentColumn => currentColumn,
					currentRow => currentRow,
					inputRow => ramToBufferMgr,
					toWriteEnable => ramWriteEnable,
					writeAddress => ramWriteAddress,
					readAddress => ramReadAddress,
					outputRow => bufferMgrToRam,
					outputRedForVgaMgr => bufferMgrRedToVgaMgr,
					outputGreenForVgaMgr => bufferMgrGreenToVgaMgr,
					outputBlueForVgaMgr => bufferMgrBlueToVgaMgr,
					outputData0ForCellMgr => bufferMgr0ToCellMgr,
					outputData1ForCellMgr => bufferMgr1ToCellMgr, 
					outputData2ForCellMgr => bufferMgr2ToCellMgr,
					inputDataFromCellMgr => cellMgrToBufferMgr 
				);

	--	instantiate and connect cell state computers
	cells : for i in 0 to NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL-1
	generate
		cell : cellMgr	
			port map(	clk => clk,
						reset => reset,
						topLeft => bufferMgr0ToCellMgr( i),
						top => bufferMgr0ToCellMgr( i+1),
						topRight => bufferMgr0ToCellMgr( i+2),
						left => bufferMgr1ToCellMgr( i),
						middle => bufferMgr1ToCellMgr( i+1),
						right => bufferMgr1ToCellMgr( i+2),
						bottomLeft => bufferMgr2ToCellMgr( i),
						bottom => bufferMgr2ToCellMgr( i+1),
						bottomRight => bufferMgr2ToCellMgr( i+2),
						output => cellMgrToBufferMgr( i)
					);
	end generate;

	--	instantiate and connect ram banks
	ramBanks : for i in 0 to NUMBER_OF_RAM_BANKS-1
	generate
		ramBank : ramBankMgr
			port map(	clk => clk,
						reset => reset,
						writeEnable => ramWriteEnable,
						writeAddress => ramWriteAddress,
						readAddress => ramReadAddress,
						inputData => bufferMgrToRam( ((i+1)*NUMBER_OF_BITS_PER_RAM_BANK_WORD)-1 downto i*NUMBER_OF_BITS_PER_RAM_BANK_WORD),
						outputData => ramToBufferMgr( ((i+1)*NUMBER_OF_BITS_PER_RAM_BANK_WORD)-1 downto i*NUMBER_OF_BITS_PER_RAM_BANK_WORD)
					);	
	end generate;
	
end gameInstance;
	
