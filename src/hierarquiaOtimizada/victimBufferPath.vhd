-- PCS3422 - Organização e Arquitetura de Computadores II
-- ARM		 
--
-- Description:
--     Implementação de Exclusion Policy - Victim Buffer



--https://surf-vhdl.com/vhdl-for-loop-statement/    "como fazer loops for"
								     
	
library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto

use types.all; -- 1 word, 32 bits							 

entity victimBuffer is
    generic (
		accessTime	   : in time := 5 ns;
		bufferLength   : natural := 5	  						-- Tamanho do Buffer
    );
    port (	
	   	queueBlockData			   : in  bit;
		queueBlockInst       	   : in  bit;
		readyRead			       : in  bit;
		evictedBlockData		   : in  word_vector_type(1 downto 0);		-- Um bloco, 2 words
		evictedBlockDataAddress	   : in  bit_vector(9 downto 0);		   
		evictedBlockDataDirty	   : in  bit;
		evictedBlockInst		   : in  word_vector_type(1 downto 0);		-- Um bloco, 2 words
		evictedBlockInstAddress	   : in  bit_vector(9 downto 0); 
		evictedBlockInstDirty	   : in bit := '0';						    -- Instrução não tem write!
		blockOut  	  			   : out word_vector_type(1 downto 0);     -- Saída do buffer: um bloco
		blockOutAddress			   : out bit_vector(9 downto 0);
		blockOutIsDirty			   : out bit
    );																	 	
end victimBuffer;
		
		
architecture archi of victimBuffer is	 	  

	constant palavrasPorBloco: positive := 2;
	constant blocoSize:        positive := palavrasPorBloco * 4; --- 2 * 4 = 8Bytes  1 word = 4 bytes
	
	type RowType is record
        valid    : bit;
		address	 : bit_vector(9 downto 0);
        data     : word_vector_type(palavrasPorBloco - 1 downto 0);
		isDirty  : bit;
    end record RowType;
	
	type bufferType is array (bufferLength-1 downto 0) of RowType;       
	
	signal victimBufferData : bufferType;  	
	
	signal isEmpty : bit;
	   
	constant buffer_row_cleared : RowType := (valid => '0',
											  address  => (others => '0'),
											  data     => (others => word_vector_init),
											  isDirty  => '0');
	
begin														  
	
	isEmpty      <= '1' when victimBufferData(0) = buffer_row_cleared else '0';
	
	-----------------------------------------------------------------------------------------------------
	process(queueBlockData, queueBlockInst, readyRead)
		variable dequeueFetchingStop : natural := 0; 	
		variable stopQueuing : natural := 0;
	
	begin	
		-------------------------------------------------------------------------------------------------------
		--L2 Ready Request
		if(readyRead'event and readyRead = '1') then
			
			blockOut 		 <= victimBufferData(0).data;	
			blockOutAddress  <= victimBufferData(0).address;
			blockOutIsDirty  <= victimBufferdata(0).isDirty;
			
			dequeueLoop : for i in 0 to bufferLength-2 loop
				victimBufferData(i) <= victimBufferData(i+1);	
			end loop dequeueLoop;								 
			
			victimBufferData(bufferLength-1) <= buffer_row_cleared;
		end if;
		
		-------------------------------------------------------------------------------------------------------
		--Queue by Data cache
		if(queueBlockData'event and queueBlockData = '1' and queueBlockInst = '0') then 
			stopQueuing := 0;
			queueLoop : for i in 0 to bufferLength-1 loop	
				if(victimBufferData(i) = buffer_row_cleared and stopQueuing = 0) then
					victimBufferData(i).data     <= evictedBlockData;
					victimBufferData(i).valid    <= '1';
					victimBufferData(i).address  <= evictedBlockDataAddress;
					victimBufferData(i).isDirty  <= evictedBlockDataDirty;
					stopQueuing := 1;
				end if;
			end loop queueLoop;
		end if;												   
		-------------------------------------------------------------------------------------------------------
		--Queue by Instruction cache
		if(queueBlockInst'event and queueBlockInst = '1' and queueBlockData = '0') then 
			stopQueuing := 0;
			queueLoop2 : for i in 0 to bufferLength-1 loop	
				if(victimBufferData(i) = buffer_row_cleared and stopQueuing = 0) then
					victimBufferData(i).data     <= evictedBlockInst;
					victimBufferData(i).valid    <= '1';
					victimBufferData(i).address  <= evictedBlockInstAddress;
					victimBufferData(i).isDirty  <= '0';    --Instrução não tem Write!
					stopQueuing := 1;
				end if;
			end loop queueLoop2;
		end if;
		-------------------------------------------------------------------------------------------------------
		--Queue by Instruction cache AND data cache
		--if(queueBlockInst'event and queueBlockInst = '1' and queueBlockData'event and queueBlockData = '1') then 
		--	stopQueuing := 0;
		--	queueLoop3 : for i in 0 to bufferLength-1 loop	
		--		if(victimBufferData(i) = buffer_row_cleared and stopQueuing = 0) then
		--			victimBufferData(i).data     <= evictedBlockInst;
		--			victimBufferData(i).valid    <= '1';
		--			victimBufferData(i).address  <= evictedBlockInstAddress;
		--			victimBufferData(i).dataInst <= '0';							  
		--			
		--			
		--			victimBufferData(i+1).data     <= evictedBlockdata;
		--			victimBufferData(i+1).valid    <= '1';
		--			victimBufferData(i+1).address  <= evictedBlockDataAddress;
		--			victimBufferData(i+1).dataInst <= '1';
		--			
		--			stopQueuing := 1;
		--		end if;
		--	end loop queueLoop3;
		--end if;	
		
		
	
	end process;																						 	   
	
	
	

end archi;							


