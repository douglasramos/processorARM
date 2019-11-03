-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- ARM		 
--
-- Description:
--     Implementação de Exclusion Policy - Victim Buffer - Datapath



--https://surf-vhdl.com/vhdl-for-loop-statement/    "como fazer loops for"
	
	
library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto

use types.all; -- 1 word, 32 bits

entity victimBuffer is
    generic (
		accessTime	   : in time := 5 ns;
		bufferLength   : natural := 20	  						-- Tamanho do Buffer
    );
    port (	
		clearBuffer				   : in  bit;
	   	queueBlockData			   : in  bit;
		queueBlockInst       	   : in  bit;
		dequeue_initial_address    : in  bit;
		dequeue_given_address_data : in  bit;
		dequeue_given_address_inst : in  bit;
		evictedBlockData		   : in  word_vector_type(31 downto 0);		-- Um bloco, 32 words
		evictedBlockInst		   : in  word_vector_type(31 downto 0);		-- Um bloco, 32 words
		evictedBlockDataTag		   : in  bit_vector(49 downto 0);
		evictedBlockDataIndex	   : in  bit_vector(6 downto 0);
		evictedBlockInstTag		   : in  bit_vector(49 downto 0);
		evictedBlockInstIndex	   : in  bit_vector(6 downto 0);
		readAddressDataTag		   : in  bit_vector(49 downto 0);			
		readAddressDataIndex	   : in  bit_vector(6  downto 0);			
		readAddressInstTag		   : in  bit_vector(49 downto 0);
		readAddressInstIndex	   : in  bit_vector(6  downto 0);
		missAckData		   		   : out bit;								-- Com esses sinais de miss, dá pra saber se continua a buscar bloco no L2 ou não
		missAckInst				   : out bit;
		blockOut  	  			   : out word_vector_type(31 downto 0);     -- Saída do buffer: um bloco
		isFullBuffer   			   : out bit
    );
end victimBuffer;
		
		
architecture archi of victimBuffer is	 	  


	signal tag 	 				: bit_vector(49 downto 0);    
	signal index 				: bit_vector(6 downto 0);	   
	signal hitBlockVictimBuffer : bit := '0';
	signal bufferIndex 			: natural;
	signal bufferEnable         : bit; 
	signal fullBuffer			: bit;

	constant palavrasPorBloco: positive := 32;
	constant blocoSize:        positive := palavrasPorBloco * 4; --- 16 * 4 = 64Bytes  1 word = 4 bytes
	
	type RowType is record
        valid : bit;
        tag   : bit_vector(49 downto 0);
		index : bit_vector(6 downto 0);
        data  : word_vector_type(palavrasPorBloco - 1 downto 0);
    end record RowType;
	
	type bufferType is array (bufferLength-1 downto 0) of RowType;       
	
	signal victimBufferData : bufferType;  	

	   
	constant buffer_row_cleared : RowType := (valid => '0',
										      tag   => (others => '0'),
											  data  => (others => word_vector_init),
											  index => (others => '0'));
	
begin														  
	
	
	
	
	
	isFullBuffer <= '1' when victimBufferData(bufferLength - 1) /= buffer_row_cleared else '0';
	-----------------------------------------------------------------------------------------------------
	process(clearBuffer, dequeue_initial_address, dequeue_given_address_data, dequeue_given_address_inst, queueBlockData, queueBlockInst)
		variable dequeueFetchingStop : natural := 0; 	
		variable stopQueuing : natural := 0;
	
	begin	
		-------------------------------------------------------------------------------------------------------
		--Clear
		if(clearBuffer'event and clearBuffer = '1') then
			victimBufferData <= (others => buffer_row_cleared);	
		end if;
		
		-------------------------------------------------------------------------------------------------------
		--Dequeue by L2 request
		if(dequeue_initial_address'event and dequeue_initial_address = '1') then
			
			blockOut <= victimBufferData(0).data;
			dequeueLoop : for i in 0 to bufferLength-2 loop
				victimBufferData(i) <= victimBufferData(i+1);	
			end loop dequeueLoop;								 
			victimBufferData(bufferLength-1) <= buffer_row_cleared;
		end if;
		
		-------------------------------------------------------------------------------------------------------
		--Dequeue by data cache Fetch
		if(dequeue_given_address_data'event and dequeue_given_address_data = '1') then 
			dequeueFetchingStop := 0;
			dequeueFetchingLoop : for i in 0 to bufferLength-1 loop			
				if(victimBufferData(i).tag = readAddressDataTag and victimBufferData(i).index = readAddressDataIndex and dequeueFetchingStop = 0) then
					
					blockOut <= victimBufferData(i).data;
					shiftLoop : for j in i to bufferLength-2 loop
						victimBufferData(j) <= victimBufferData(j+1);
					end loop shiftLoop;								 
					victimBufferData(bufferLength-1) <= buffer_row_cleared;	
					dequeueFetchingStop := 1;
						
				end if;					
				
				if(dequeueFetchingStop = 0) then
					missAckData <= '1';
				else
					missAckData <= '0';
				end if;				   
				
			end loop dequeueFetchingLoop;				
			
		end if;
		
		-------------------------------------------------------------------------------------------------------
		--Dequeue by instruction cache fetch
		if(dequeue_given_address_inst'event and dequeue_given_address_inst = '1') then 
			dequeueFetchingStop := 0;
			dequeueFetchingLoop2 : for i in 0 to bufferLength-1 loop			
				if(victimBufferData(i).tag = readAddressInstTag and victimBufferData(i).index = readAddressInstIndex and dequeueFetchingStop = 0) then
			
					blockOut <= victimBufferData(i).data;
					shiftLoop : for j in i to bufferLength-2 loop
						victimBufferData(j) <= victimBufferData(j+1);
					end loop shiftLoop;								 
					victimBufferData(bufferLength-1) <= buffer_row_cleared;	
					dequeueFetchingStop := 1;
						
				end if;					
				
				if(dequeueFetchingStop = 0) then
					missAckInst <= '1';
				else
					missAckInst <= '0';
				end if;				   
			end loop dequeueFetchingLoop2;					
		end if;
		-------------------------------------------------------------------------------------------------------
		--Queue by data cache
		if(queueBlockData'event and queueBlockData = '1') then 
			stopQueuing := 0;
			queueLoop : for i in 0 to bufferLength-1 loop	
				if(victimBufferData(i) = buffer_row_cleared and stopQueuing = 0) then
					victimBufferData(i).data  <= evictedBlockData;
					victimBufferData(i).tag   <= evictedBlockDataTag;
					victimBufferData(i).index <= evictedBlockDataIndex;
					victimBufferData(i).valid <= '1';
					stopQueuing := 1;
				end if;
			end loop queueLoop;
		end if;												   
		-------------------------------------------------------------------------------------------------------
		--Queue by instruction cache
		if(queueBlockInst'event and queueBlockInst = '1') then 
			stopQueuing := 0;
			queueLoop2 : for i in 0 to bufferLength-1 loop	
				if(victimBufferData(i) = buffer_row_cleared and stopQueuing = 0) then
					victimBufferData(i).data  <= evictedBlockInst;
					victimBufferData(i).tag   <= evictedBlockInstTag;
					victimBufferData(i).index <= evictedBlockInstIndex;
					victimBufferData(i).valid <= '1';
					stopQueuing := 1;
				end if;
			end loop queueLoop2;
		end if;
		
	end process;																						 
	
	

end archi;							



