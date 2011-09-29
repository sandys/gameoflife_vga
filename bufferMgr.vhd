
------------------------------------------------------
--	it's better if you set tab size to 4 spaces!	--
------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use	work.gamePackage.all;

entity bufferMgr is
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
end bufferMgr;

architecture	bufferSignalGenerator of bufferMgr is
	type	verticalStateType is(	waitVState,
									readPenultRow, readPenultRowDelayed, writeFirstRow,
									readSecondRow, readSecondRowDelayed, writeLastRow, 
									initRow0, initRow0Delayed,
									initRow1, initRow1Delayed,
									initRow2, initRow2Delayed,
									endVState
								);
								
	
	type	horizontalStateType is(	waitHState, 
									compute, 
									computeStep00, computeStep01,
									computeStep10, computeStep11,
									computeStep20, computeStep21,
									computeStep30, computeStep31,
									computeStep40, computeStep41,
									computeStep50, computeStep51,
									computeStep60, computeStep61,
									computeStep70, computeStep71,
									computeStep80, computeStep81,
									computeStep90, computeStep91,
									endCompute,
									updateRow0,
									updateRow1,
									updateRow2, updateRow2Delayed,
									writeNewRow, endWriteNewRow,
									endHState
								   );
	
	type	resetStateType is(	startReset,
								initRow0, initRow1, initRow2,
								initRow3, initRow4, initRow5,
								loopEmptyRows, 
								initRow236, initRow237, initRow238,
								initRow239, initRow240, initRow241,
								prefetchRow0, prefetchRow0Delayed,
								prefetchRow1, prefetchRow1Delayed,
								prefetchRow2, prefetchRow2Delayed,
								endReset
							 );
	
	signal	currentHState, nextHState : horizontalStateType;
	signal	currentVState, nextVState : verticalStateType;
	signal	currentResetState, nextResetState : resetStateType;
	
	signal	row0 : borderedRowType;
	signal	row1 : borderedRowType;
	signal	row2 : borderedRowType;
	signal	tempRow : rowType;
	signal	newRow : rowType;
	
--	signal	initIndex : ramAddressType;
	
begin	
	--	generate output value for vga display
	process( clk)
		variable	cellState : std_logic;
	begin
		if( clk'event and clk = '1')
		then
			outputRedForVgaMgr <= '0';
			outputGreenForVgaMgr <= '0';
			outputBlueForVgaMgr <= '0';
			if( currentColumn < NUMBER_OF_CELLS_PER_ROW*2 )
			then
				if( currentRow < NUMBER_OF_CELLS_PER_COLUMN*2 )
				then
					cellState := row1( conv_integer( currentColumn( NUMBER_OF_BITS_PER_COLUMN_INDEX-1 downto 1) + conv_std_logic_vector( 1, NUMBER_OF_BITS_PER_COLUMN_INDEX-1)));
					outputRedForVgaMgr <= cellState;
					outputGreenForVgaMgr <= cellState;
					outputBlueForVgaMgr <= not cellState;
				end if;
			end if;
		end if;
	end process;
	
	--	compute next states for state machine or reset it
	process( clk, reset, verticalSync, horizontalSync)
	begin
		if( clk'event and clk = '1' )
		then
			currentHState <= waitHState;
			currentVState <= waitVState;
			currentResetState <= nextResetState;
			if( reset = '1' )
			then				
				currentResetState <= nextResetState;
				if( horizontalSync = '0')
				then
					if( currentRow < NUMBER_OF_CELLS_PER_COLUMN*2 )
					then
						if( currentRow(0) = '0' )
						then
							currentHState <= nextHState;
						end if;
					end if;
				end if;
				if( verticalSync = '0')
				then
					currentVState <= nextVState;
				end if;
			else
				currentResetState <= startReset;				
			end if;
		end if;
	end process;

	-- state machines inside this process should never overlap each other
	process( clk, currentVState, currentHState, currentResetState, inputRow)
	begin
		if( clk'event and clk='1')
		then
		toWriteEnable <= '0';
		case currentVState is
			when waitVState =>
				nextVState <= readPenultRow;

			when readPenultRow =>
				readAddress <= conv_std_logic_vector( NUMBER_OF_RAM_ROWS-2, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				tempRow <= inputRow;
				nextVState <= readPenultRowDelayed; -- @If you wish to test delayed read use: readPenultRowDelayed;

			when readPenultRowDelayed =>
				tempRow <= inputRow;
				nextVState <= writeFirstRow;

			when writeFirstRow =>
				writeAddress <= conv_std_logic_vector( 0, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				outputRow <= tempRow;
				toWriteEnable <= '1';
				nextVState <= readSecondRow;

			when readSecondRow =>
				readAddress <= conv_std_logic_vector( 1, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				tempRow <= inputRow;
				nextVState <= readSecondRowDelayed; -- @If you wish to test delayed read use: readSecondRowDelayed;

			when readSecondRowDelayed =>
				tempRow <= inputRow;
				nextVState <= writeLastRow;

			when writeLastRow =>
				writeAddress <= conv_std_logic_vector( NUMBER_OF_RAM_ROWS-1, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				outputRow <= tempRow;
				toWriteEnable <= '1';
				nextVState <= initRow0;

			when initRow0 =>
				readAddress <= conv_std_logic_vector( 0, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				row0 <= inputRow( 0) & inputRow & inputRow( NUMBER_OF_CELLS_PER_ROW-1);
				nextVState <= initRow0Delayed; -- @If you wish to test delayed read use: initRow0Delayed;

			when initRow0Delayed =>
				row0 <= inputRow( 0) & inputRow & inputRow( NUMBER_OF_CELLS_PER_ROW-1);
				nextVState <= initRow1;

			when initRow1 =>
				readAddress <= conv_std_logic_vector( 1, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				row1 <= inputRow( 0) & inputRow & inputRow( NUMBER_OF_CELLS_PER_ROW-1);
				nextVState <= initRow1Delayed; -- @If you wish to test delayed read use: initRow1Delayed;

			when initRow1Delayed =>
				row1 <= inputRow( 0) & inputRow & inputRow( NUMBER_OF_CELLS_PER_ROW-1);
				nextVState <= initRow2;

			when initRow2 =>
				readAddress <= conv_std_logic_vector( 2, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				row2 <= inputRow( 0) & inputRow & inputRow( NUMBER_OF_CELLS_PER_ROW-1);
				nextVState <= initRow2Delayed; -- @If you wish to test delayed read use: initRow2Delayed;

			when initRow2Delayed =>
				row2 <= inputRow( 0) & inputRow & inputRow( NUMBER_OF_CELLS_PER_ROW-1);
				nextVState <= endVState;

			when endVState =>
				nextVState <= endVState;

			--	when others =>
			--		nextVState <= endVState;

		end case;

		case currentHState is
			when waitHState =>
				nextHState <= compute;

			when compute =>
				nextHState <= computeStep00;

			--	we impose 10 computation steps since we prefer unrolled loop with constant indexes
			when computeStep00 =>
				outputData0ForCellMgr <= row0( NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL+1 downto 0);
				outputData1ForCellMgr <= row1( NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL+1 downto 0);
				outputData2ForCellMgr <= row2( NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL+1 downto 0);
				nextHState <= computeStep01;
		
			when computeStep01 =>
				newRow( NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL-1 downto 0) <= inputDataFromCellMgr;
				nextHState <= computeStep10;

			when computeStep10 =>
				outputData0ForCellMgr <= row0( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*2)+1) downto NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL);
				outputData1ForCellMgr <= row1( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*2)+1) downto NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL);
				outputData2ForCellMgr <= row2( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*2)+1) downto NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL);
				nextHState <= computeStep11;
		
			when computeStep11 =>
				newRow( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*2)-1) downto NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL) <= inputDataFromCellMgr;
				nextHState <= computeStep20;

			when computeStep20 =>
				outputData0ForCellMgr <= row0( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*3)+1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*2));
				outputData1ForCellMgr <= row1( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*3)+1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*2));
				outputData2ForCellMgr <= row2( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*3)+1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*2));
				nextHState <= computeStep21;
				
			when computeStep21 =>
				newRow( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*3)-1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*2)) <= inputDataFromCellMgr;
				nextHState <= computeStep30;

			when computeStep30 =>
				outputData0ForCellMgr <= row0( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*4)+1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*3));
				outputData1ForCellMgr <= row1( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*4)+1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*3));
				outputData2ForCellMgr <= row2( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*4)+1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*3));
				nextHState <= computeStep31;
				
			when computeStep31 =>
				newRow( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*4)-1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*3)) <= inputDataFromCellMgr;
				nextHState <= computeStep40;

			when computeStep40 =>
				outputData0ForCellMgr <= row0( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*5)+1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*4));
				outputData1ForCellMgr <= row1( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*5)+1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*4));
				outputData2ForCellMgr <= row2( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*5)+1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*4));
				nextHState <= computeStep41;
				
			when computeStep41 =>
				newRow( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*5)-1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*4)) <= inputDataFromCellMgr;
				nextHState <= computeStep50;

			when computeStep50 =>
				outputData0ForCellMgr <= row0( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*6)+1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*5));
				outputData1ForCellMgr <= row1( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*6)+1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*5));
				outputData2ForCellMgr <= row2( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*6)+1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*5));
				nextHState <= computeStep51;
				
			when computeStep51 =>
				newRow( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*6)-1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*5)) <= inputDataFromCellMgr;
				nextHState <= computeStep60;

			when computeStep60 =>
				outputData0ForCellMgr <= row0( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*7)+1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*6));
				outputData1ForCellMgr <= row1( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*7)+1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*6));
				outputData2ForCellMgr <= row2( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*7)+1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*6));
				nextHState <= computeStep61;
				
			when computeStep61 =>
				newRow( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*7)-1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*6)) <= inputDataFromCellMgr;
				nextHState <= computeStep70;

			when computeStep70 =>
				outputData0ForCellMgr <= row0( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*8)+1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*7));
				outputData1ForCellMgr <= row1( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*8)+1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*7));
				outputData2ForCellMgr <= row2( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*8)+1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*7));
				nextHState <= computeStep71;
				
			when computeStep71 =>
				newRow( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*8)-1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*7)) <= inputDataFromCellMgr;
				nextHState <= computeStep80;

			when computeStep80 =>
				outputData0ForCellMgr <= row0( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*9)+1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*8));
				outputData1ForCellMgr <= row1( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*9)+1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*8));
				outputData2ForCellMgr <= row2( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*9)+1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*8));
				nextHState <= computeStep81;
				
			when computeStep81 =>
				newRow( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*9)-1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*8)) <= inputDataFromCellMgr;
				nextHState <= computeStep90;

			when computeStep90 =>
				outputData0ForCellMgr <= row0( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*10)+1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*9));
				outputData1ForCellMgr <= row1( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*10)+1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*9));
				outputData2ForCellMgr <= row2( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*10)+1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*9));
				nextHState <= computeStep91;
				
			when computeStep91 =>
				newRow( ((NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*10)-1) downto (NUMBER_OF_CELLS_COMPUTED_IN_PARALLEL*9)) <= inputDataFromCellMgr;
				nextHState <= endCompute;

			when endCompute =>
				nextHState <= updateRow0;

			when updateRow0 =>
				row0 <= row1;
				nextHState <= updateRow1;

			when updateRow1 =>
				row1 <= row2;
				nextHState <= updateRow2;

			when updateRow2 =>
				readAddress <= currentRow( NUMBER_OF_BITS_PER_RAM_ADDRESS downto 1) + conv_std_logic_vector( 3, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				row2 <= inputRow( 0) & inputRow & inputRow( NUMBER_OF_CELLS_PER_ROW-1);
				nextHState <= updateRow2Delayed; -- @If you wish to test delayed read use: updateRow2Delayed;

			when updateRow2Delayed =>
				row2 <= inputRow( 0) & inputRow & inputRow( NUMBER_OF_CELLS_PER_ROW-1);
				nextHState <= writeNewRow;
				
			when writeNewRow =>
				writeAddress <= currentRow( NUMBER_OF_BITS_PER_RAM_ADDRESS downto 1) + conv_std_logic_vector( 1, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				outputRow <= newRow;
				toWriteEnable <= '1';
				nextHState <= endWriteNewRow;

			when endWriteNewRow =>
				nextHState <= endHState;

			when endHState =>
				nextHState <= endHState;

			--	when others =>
			--		nextHState <= endHState;

		end case;

		case currentResetState is
			when startReset =>
				nextResetState <= initRow0;

			when initRow0 =>
				writeAddress <= conv_std_logic_vector( 0, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				outputRow( 319 downto 0) <= "11011110100000000000000000000000000000000000000000000000111110000000000000000001111111001010101010111010101010111110000110010100100010100101010000000000000000111111100101010101011101010101011111000011001010010001010010101000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111101";
				toWriteEnable <= '1';
				nextResetState <= initRow1;

			when initRow1 =>
				writeAddress <= conv_std_logic_vector( 1, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				outputRow( 319 downto 0) <= "10000000000000000000000001011110110101010101011010101110110110101011110100101011100011111101110010101111111111111111010101011101010101001001111000000000000000111111100101010101011101010101011111000011001010010001010010101000000000000000000000000000000000000000000000000000000000000000000000000111100001111111111111111101";
				toWriteEnable <= '1';
				nextResetState <= initRow2;
			
			when initRow2 =>
				writeAddress <= conv_std_logic_vector( 2, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				outputRow( 319 downto 0) <= "11000000000000000000000000000101111000000001110101011101011010101011110101010000010101001010101110101010110101000000000000000000000000000000000000000111100001111000011111100000000001111111001010101010111010101010111110000110010100100010100101010000000111111111110100000000000000000000000000000000000000000000000000000000";
				toWriteEnable <= '1';
				nextResetState <= initRow3;
			
			when initRow3 =>
				writeAddress <= conv_std_logic_vector( 3, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				outputRow( 319 downto 0) <= "11100000000000000000000000000000001001001100000000000000000000000000000000000001111001110101111010101010110010101111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001101010100101010101010100101011010000000000111111100101010101011101010101011111000011001010010001010010101000000011";
				toWriteEnable <= '1';
				nextResetState <= initRow4;
			
			when initRow4 =>
				writeAddress <= conv_std_logic_vector( 4, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				outputRow( 319 downto 0) <= "11110000000000000000000000000000000111000000000000000000000000000000000000000001110101010110101000101010101111010001000000000000000000000000000000000000000000000000000000000000000000000000000000000011111110010101010101110101010101111100001100101001000101001010100000000000000000000000001010101010100101010101010101110111";
				toWriteEnable <= '1';
				nextResetState <= initRow5;
			
			when initRow5 =>
				writeAddress <= conv_std_logic_vector( 5, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				outputRow( 319 downto 0) <= "11111000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111010101010101011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000011111110010101010101110101010101111100001100101001000101001010100000000000000000000000011111111111111111111111111111110111";
				toWriteEnable <= '1';
				--initIndex <= ( others => '0');
				nextResetState <= loopEmptyRows;
			
			when loopEmptyRows =>
				--writeAddress <= initIndex;
				--outputRow <= ( others => '0');
				toWriteEnable <= '0';
				--if( initIndex = 235 )
				--then
					nextResetState <= initRow236;
				--else
				--	initIndex <= initIndex + conv_std_logic_vector( 1, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				--	nextResetState <= loopEmptyRows;
				--end if;

			when initRow236 =>
				writeAddress <= conv_std_logic_vector( 236, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				outputRow( 319 downto 0) <= "11011101111110000000000000000000000000000000000000000111111110000000000000000001111010010111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111100101010101011101010101011111000011001010010001010010101000000000000000000000000000000000000000000000111110001";
				toWriteEnable <= '1';
				nextResetState <= initRow237;
			
			when initRow237 =>
				writeAddress <= conv_std_logic_vector( 237, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				outputRow( 319 downto 0) <= "11011101111111000000000000000000000000000000000000000111111110000000000000000001110101101011111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111001010101010111010101010111110000110010100100010100101010000000000000000000000001111000000001";
				toWriteEnable <= '1';
				nextResetState <= initRow238;
			
			when initRow238 =>
				writeAddress <= conv_std_logic_vector( 238, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				outputRow( 319 downto 0) <= "10101111111111100000000000000000000000000000000000000111111110000000000000000001111111111111111111100001111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111100101010101011101010101011111000011001010010001010010101000000000000000000000000000000000000001110011100001010";
				toWriteEnable <= '1';
				nextResetState <= initRow239;
			
			when initRow239 =>
				writeAddress <= conv_std_logic_vector( 239, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				outputRow( 319 downto 0) <= "01010000001111111000000000000000000000000000000000000111111110000000000000000001111111111111111110011110011111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111001010101010111010101010111110000110010100100010100101010000000000000000000000000000000000110000001111110101";
				toWriteEnable <= '1';
				nextResetState <= initRow240;
			
			when initRow240 =>
				writeAddress <= conv_std_logic_vector( 240, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				outputRow( 319 downto 0) <= "11011110000000000000000000000000000000000000000000000111111110000000000000000001111111111111111111100001111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000001111111001010101010111010101010111110000110010100100010100101110000000000000000000000000000001";
				toWriteEnable <= '1';
				nextResetState <= initRow241;
			
			when initRow241 =>
				writeAddress <= conv_std_logic_vector( 241, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				outputRow( 319 downto 0) <= "00000000000000000000000000000000000000000000000000001111111111111111111111111111111111111111111111111111111111111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111100000000001111111001010101010111010101010111110000110010100100010100101010111100000000000000000000000111111101";
				toWriteEnable <= '1';
				nextResetState <= prefetchRow0;

			when prefetchRow0 =>
				readAddress <= conv_std_logic_vector( 0, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				row0 <= inputRow( 0) & inputRow & inputRow( NUMBER_OF_CELLS_PER_ROW-1);
				nextResetState <= prefetchRow0Delayed; -- @If you wish to test delayed read use: prefetchRow0Delayed;

			when prefetchRow0Delayed =>
				row0 <= inputRow( 0) & inputRow & inputRow( NUMBER_OF_CELLS_PER_ROW-1);
				nextResetState <= prefetchRow1;

			when prefetchRow1 =>
				readAddress <= conv_std_logic_vector( 1, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				row1 <= inputRow( 0) & inputRow & inputRow( NUMBER_OF_CELLS_PER_ROW-1);
				nextResetState <= prefetchRow1Delayed; -- @If you wish to test delayed read use: prefetchRow1Delayed;

			when prefetchRow1Delayed =>
				row1 <= inputRow( 0) & inputRow & inputRow( NUMBER_OF_CELLS_PER_ROW-1);
				nextResetState <= prefetchRow2;

			when prefetchRow2 =>
				readAddress <= conv_std_logic_vector( 2, NUMBER_OF_BITS_PER_RAM_ADDRESS);
				row2 <= inputRow( 0) & inputRow & inputRow( NUMBER_OF_CELLS_PER_ROW-1);
				nextResetState <= prefetchRow2Delayed; -- @If you wish to test delayed read use: prefetchRow2Delayed;

			when prefetchRow2Delayed =>
				row2 <= inputRow( 0) & inputRow & inputRow( NUMBER_OF_CELLS_PER_ROW-1);
				nextResetState <= endReset;

			when endReset =>
				nextResetState <= endReset;

			--	when others =>
			--		nextResetState <= endReset;

		end case;
		end if;
	end process;

end bufferSignalGenerator;


