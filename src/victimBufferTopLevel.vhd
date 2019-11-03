-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Top Level - L1 da hierarquia de memoria

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto

use types.all;

entity victimBufferTopLevel is
    generic (
		accessTime		: in time := 5 ns;
		bufferLength	: natural := 20
    );
    port (									   
		clk							 : in  bit;
		VBDataAccess				 : in  bit;
		VBInstAccess				 : in  bit;
		isEvictedL1_Data			 : in  bit;		
		isEvictedL1_Inst			 : in  bit;		
		isDequeueAddr_Data			 : in  bit;
		isDequeueAddr_Inst			 : in  bit;
		L2Dequeue					 : in  bit;
		isClear 					 : in  bit; 
		evictedBlockData			 : in  word_vector_type(31 downto 0);
		evictedBlockInst			 : in  word_vector_type(31 downto 0);	
		evictedBlockDataTag		     : in  bit_vector(49 downto 0);
		evictedBlockDataIndex	     : in  bit_vector(6  downto 0);
		evictedBlockInstTag		     : in  bit_vector(49 downto 0);
		evictedBlockInstIndex	     : in  bit_vector(6  downto 0);
		readAddressDataTag		   	 : in  bit_vector(49 downto 0);			
		readAddressDataIndex	     : in  bit_vector(6  downto 0);			
		readAddressInstTag		  	 : in  bit_vector(49 downto 0);
		readAddressInstIndex	   	 : in  bit_vector(6  downto 0);
		missAckData					 : out bit;					   
		missAckInst					 : out bit;															
		blockOut  	  			     : out word_vector_type(31 downto 0);     -- Saída do buffer: um bloco
		isFullBuffer   			     : out bit
    );
end victimBufferTopLevel;

architecture archi of victimBufferTopLevel is	 	  

component victimBuffer is
    generic (
		accessTime	   : in time := 5 ns;
		bufferLength   : natural := 20	  						
    );
    port (	
		clearBuffer				   : in bit;			
	   	queueBlockData			   : in  bit;		
		queueBlockInst       	   : in  bit;		  
		dequeue_initial_address    : in  bit;			
		dequeue_given_address_data : in  bit;			  
		dequeue_given_address_inst : in  bit;				
		evictedBlockData		   : in  word_vector_type(31 downto 0);		-- Um bloco, 16 words
		evictedBlockInst		   : in  word_vector_type(31 downto 0);		-- Um bloco, 16 words 
		evictedBlockDataTag		   : in  bit_vector(49 downto 0);
		evictedBlockDataIndex	   : in  bit_vector(6  downto 0);
		evictedBlockInstTag		   : in  bit_vector(49 downto 0);
		evictedBlockInstIndex	   : in  bit_vector(6  downto 0);
		readAddressDataTag		   : in  bit_vector(49 downto 0);			
		readAddressDataIndex	   : in  bit_vector(6  downto 0);			
		readAddressInstTag		   : in  bit_vector(49 downto 0);
		readAddressInstIndex	   : in  bit_vector(6  downto 0);
		missAckData		   		   : out bit;								
		missAckInst				   : out bit;
		blockOut  	  			   : out word_vector_type(31 downto 0);     
		isFullBuffer   			   : out bit
    );
end component;

component ControlVB is
    generic (
        accessTime: in time := 5 ns
    );
    port (
		clk							 : in  bit;
		VBDataAccess				 : in  bit;
		VBInstAccess				 : in  bit;
		isEvictedL1_Data			 : in  bit;		
		isEvictedL1_Inst			 : in  bit;		
		--isDequeueAddr_Data			 : in  bit;
		--isDequeueAddr_Inst			 : in  bit;
		L2Dequeue					 : in  bit;			--L2 envia esse sinal qdo quer puxar um bloco do victim buffer.
		isClear						 : in  bit;						--isso tem que estar incluso como algo periódico de o L2 fazer!
		dequeue_initial_address 	 : out bit;	   
		dequeue_given_address_data   : out bit;
		dequeue_given_address_inst	 : out bit;	 
		queueBlockData			     : out bit;
		queueBlockInst				 : out bit;	 
		clearBuffer			    	 : out bit	   
    );
end component;

	signal clearBuffer                : bit;								
	signal queueBlockData             : bit;
	signal queueBlockInst             : bit;						
	signal dequeue_initial_address    : bit;
	signal dequeue_given_address_data : bit;
	signal dequeue_given_address_inst : bit;	  
	
begin
		
	VBDatapath : victimBuffer generic map(accessTime, bufferLength) port map(clearBuffer, queueBlockData, queueBlockInst, dequeue_initial_address, dequeue_given_address_data,
										dequeue_given_address_inst, evictedBlockData, evictedBlockInst, evictedBlockDataTag, 
										evictedBlockDataIndex, evictedBlockInstTag, evictedBlockInstIndex, readAddressDataTag, readAddressDataIndex, 
										readAddressInstTag, readAddressInstIndex, missAckData, missAckInst, blockOut, isFullBuffer);
				
										
	VBUC : ControlVB port map(clk, VBDataAccess, VBInstAccess,isEvictedL1_Data, isEvictedL1_Inst, L2Dequeue, isClear, dequeue_initial_address,
								dequeue_given_address_data, dequeue_given_address_inst, queueBlockData, queueBlockInst, clearBuffer);
end architecture archi;