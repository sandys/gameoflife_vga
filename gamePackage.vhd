
------------------------------------------------------
--	it's better if you set tab size to 4 spaces!	--
------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

package gamePackage is

--	high frequencies are not achieved by our board!

--	800x600 @72Hz [+hsync +vsync]
--	clk must be 50MHz
--	constant	HSYNC_ACTIVE_VALUE : std_logic := '1';
--	constant	VSYNC_ACTIVE_VALUE : std_logic := '1';
--	constant	VGA_H_RES : integer := 800;
--	constant	VGA_V_RES : integer := 600;
--	constant	VGA_H_A : integer := 800;
--	constant	VGA_H_B : integer := 856;
--	constant	VGA_H_C : integer := 976;
--	constant	VGA_H_D : integer := 1040;
--	constant	VGA_V_A : integer := 600;
--	constant	VGA_V_B : integer := 637;
--	constant	VGA_V_C : integer := 643;
--	constant	VGA_V_D : integer := 666;

--	800x600 @60Hz [+hsync +vsync]
--	clk must be 40MHz
--	constant	HSYNC_ACTIVE_VALUE : std_logic := '1';
--	constant	VSYNC_ACTIVE_VALUE : std_logic := '1';
--	constant	VGA_H_RES : integer := 800;
--	constant	VGA_V_RES : integer := 600;
--	constant	VGA_H_A : integer := 800;
--	constant	VGA_H_B : integer := 840;
--	constant	VGA_H_C : integer := 968;
--	constant	VGA_H_D : integer := 1056;
--	constant	VGA_V_A : integer := 600;
--	constant	VGA_V_B : integer := 601;
--	constant	VGA_V_C : integer := 605;
--	constant	VGA_V_D : integer := 628;

--	800x600 @56Hz [-hsync -vsync]
--	clk must be 36MHz, but we only have 33Mhz max, anyway it seems to run...
--	constant	HSYNC_ACTIVE_VALUE : std_logic := '0';
--	constant	VSYNC_ACTIVE_VALUE : std_logic := '0';
--	constant	VGA_H_RES : integer := 800;
--	constant	VGA_V_RES : integer := 600;
--	constant	VGA_H_A : integer := 800;
--	constant	VGA_H_B : integer := 824;
--	constant	VGA_H_C : integer := 896;
--	constant	VGA_H_D : integer := 1024;
--	constant	VGA_V_A : integer := 600;
--	constant	VGA_V_B : integer := 601;
--	constant	VGA_V_C : integer := 603;
--	constant	VGA_V_D : integer := 625;



--	640x480 @60Hz [-hsync -vsync]
--	clk must be 25MHz
	constant	HSYNC_ACTIVE_VALUE : std_logic := '0';
	constant	VSYNC_ACTIVE_VALUE : std_logic := '0';
	constant	VGA_H_RES : integer := 640;
	constant	VGA_V_RES : integer := 480;
	constant	VGA_H_A : integer := 640;
	constant	VGA_H_B : integer := 660;
	constant	VGA_H_C : integer := 756;
	constant	VGA_H_D : integer := 800;
	constant	VGA_V_A : integer := 480;
	constant	VGA_V_B : integer := 491;
	constant	VGA_V_C : integer := 493;
	constant	VGA_V_D : integer := 525;
	
	--	PAY ATTENTION: 
	--	1)	NUMBER_OF_CELLS_PER_ROW == 10 * NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL
	--		because we IMPOSE 10 computations per row ( @todo: fix this by using a variable in the computation)
	--
	--	2)	CELLS are displayed by 2x2 pixel rectangles and cell board must be all visible

	--	800x600	
--	constant	NUMBER_OF_CELLS_PER_ROW : integer := 400;
--	constant	NUMBER_OF_CELLS_PER_COLUMN : integer := 254;	--	+2 => 102400 ram cells are needed
--	constant	NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL : integer := 40;
	
	--	640x480
	constant	NUMBER_OF_CELLS_PER_ROW : integer := 320;
	constant	NUMBER_OF_CELLS_PER_COLUMN : integer := 240;	--	+2 => 77400 ram cells are needed
	constant	NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL : integer := 32;

	constant	NUMBER_OF_COMPUTATIONS_PER_ROW : integer := 10;

	constant	NUMBER_OF_CELLS_PER_BORDERED_ROW : integer := NUMBER_OF_CELLS_PER_ROW+2;	
	constant	NUMBER_OF_RAM_ROWS : integer := NUMBER_OF_CELLS_PER_COLUMN+2;
	constant	NUMBER_OF_BITS_PER_RAM_BANK_WORD : integer := 16;
	constant	NUMBER_OF_BITS_PER_RAM_ADDRESS : integer := 8;	--	we won't go beyond 254+2 lines
	constant	NUMBER_OF_BITS_PER_ROW_INDEX : integer := 12;
	constant	NUMBER_OF_BITS_PER_COLUMN_INDEX : integer := 12;
	constant	NUMBER_OF_RAM_BANKS : integer := NUMBER_OF_CELLS_PER_ROW/NUMBER_OF_BITS_PER_RAM_BANK_WORD;
	
	subtype	ramBankWordType is std_logic_vector( NUMBER_OF_BITS_PER_RAM_BANK_WORD-1 downto 0);
	subtype	parallelWordType is std_logic_vector( NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL-1 downto 0);
	subtype	borderedParallelWordType is std_logic_vector( NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL+1 downto 0);
	
	subtype	rowType is std_logic_vector( NUMBER_OF_CELLS_PER_ROW-1 downto 0);
	subtype	borderedRowType is std_logic_vector( NUMBER_OF_CELLS_PER_BORDERED_ROW-1 downto 0);
	
	subtype	ramAddressType is std_logic_vector( NUMBER_OF_BITS_PER_RAM_ADDRESS-1 downto 0);
	subtype	rowIndexType is std_logic_vector( NUMBER_OF_BITS_PER_ROW_INDEX-1 downto 0);
	subtype	columnIndexType is std_logic_vector( NUMBER_OF_BITS_PER_ROW_INDEX-1 downto 0);	
	
	type	ramBankType is array( 0 to NUMBER_OF_RAM_ROWS-1) of ramBankWordType;
		
	--	vgaMgr generates vga signal and gives information about reached position
	component vgaMgr
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
	end component;

	component ramBankMgr
		port(	clk : in std_logic;
				reset : in std_logic;
				writeEnable : in std_logic;
				writeAddress : in ramAddressType;
				readAddress : in ramAddressType;
				inputData : in ramBankWordType;
				outputData : out ramBankWordType
			);
	end component;

	--	bufferMgr retrieves rows and computes new states that are given back to ram
	component	bufferMgr
		port(	clk : in std_logic;
				reset : in std_logic;
				horizontalSync : in std_logic;
				verticalSync : in std_logic;
				currentColumn : in columnIndexType;
				currentRow : in rowIndexType;
				inputRow : in rowType;
				toWriteEnable : out std_logic;
				writeAddress : out ramAddressType;
				readAddress : out ramAddressType;
				outputRow : out rowType;
				outputRedForVgaMgr : out std_logic;
				outputGreenForVgaMgr : out std_logic;
				outputBlueForVgaMgr : out std_logic;
				outputData0ForCellMgr : out borderedParallelWordType;
				outputData1ForCellMgr : out borderedParallelWordType;
				outputData2ForCellMgr : out borderedParallelWordType;
				inputDataFromCellMgr : in parallelWordType
			);
	end component;

	--	cellMgr computes one new state
	component	cellMgr
		port(	clk : in std_logic;
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
	end component;

end gamePackage;
