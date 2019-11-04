-- PCS3412 - Organização e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Hierarquia - com o VB acoplado

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto

use types.all;


entity memoryHierarchy is
    generic (
        accessTime: in time := 5 ns
    );												 
    port (
		clk               : in  bit; 
		clk_pipeline      : in  bit;
		I_cpuAddr         : in  bit_vector(63 downto 0);
		D_cpuAddr         : in  bit_vector(63 downto 0);
		I_dataOut         : out word_type;
		D_dataOut         : out word_type;	  
		I_L2_fetched      : in  word_vector_type(31 downto 0);
		D_L2_fetched      : in  word_vector_type(31 downto 0);
		I_readBlockAddr   : out bit_vector(63 downto 0);
		D_readBlockAddr   : out bit_vector(63 downto 0);	
		memWrite		  : in  bit;
		dataIn			  : in  word_type;
		D_L2BlockOut	  : out word_vector_type(31 downto 0) := (others => word_vector_init);
		I_Stall 		  : out bit;
		D_Stall 		  : out bit;
		readyL2 	      : in  bit;
		blockOut  	  	  : out word_vector_type(31 downto 0);     -- Saída do buffer: um bloco
		blockOutAddress	  : out bit_vector(63 downto 0);
		blockOutDataInst  : out bit;
		VB_BlockDirty	  : out bit
    );
end entity memoryHierarchy;

architecture archi of memoryHierarchy is
--------------------------------------------------------------------------------------
--UC cache de Instruções
--------------------------------------------------------------------------------------
component ControlCacheI is
    generic (
        accessTime: in time := 5 ns
    );
    port (
		-- I/O relacionados ao stage IF
		clk				   : in  bit;
        stall			   : out bit := '0';
		pc				   : in  bit_vector(63 downto 0);
		-- I/O relacionados ao cache
		hitSignal		   : in  bit;
		writeOptions	   : out bit := '0';
		updateInfo	   	   : out bit := '0';
        -- I/O relacionados ao L2
		L2Ready			   : in  bit;
		L2RW			   : out bit := '0';  --- '1' write e '0' read
        L2Enable		   : out bit := '0';
		-- I/O relacionados ao victim buffer
		isFull			   : in  bit;
		VBInstAccess	   : out bit
		
    );
end component;

--------------------------------------------------------------------------------------
--UC cache de Dados
--------------------------------------------------------------------------------------
component ControlCacheD is
    generic (
        accessTime: in time := 5 ns
    );
    port (			  		
		-- I/O relacionados ao stage MEM
		clk:            in  bit;
		clk_pipeline:   in  bit;
        cpu_write:      in  bit;
		cpu_addr:       in  bit_vector(63 downto 0);
		stall:          out bit := '0';
		-- I/O relacionados ao cache
		dirtyBit:      in  bit;
		hitSignal:     in  bit;
		writeOptions:  out bit_vector(1 downto 0) := "00";
		updateInfo:    out bit := '0';
        -- I/O relacionados a Memoria princial
		L2Ready:      in  bit;
		L2RW:         out bit := '0';  --- '1' write e '0' read
        L2Enable:     out bit := '0';
		-- Victim buffer
		isFull		 : in  bit;
		VBDataAccess : out bit
    );
end	component;

--------------------------------------------------------------------------------------
--FD cache de Instrução
--------------------------------------------------------------------------------------
component CacheI is
    generic (
        accessTime: in time := 5 ns
    );
    port (		
		-- I/O relacionados ao controle
		writeOptions	     : in  bit;
		updateInfo		     : in  bit; 
		hit				     : out bit := '0';	  --usar para ativar o evict block
		-- I/O relacionados ao IF stage
        cpuAddr			     : in  bit_vector(63 downto 0);
        dataOut			     : out word_type;	
        -- I/O relacionados ao L2 ou ao VB
        memBlocoData	     : in  word_vector_type(31 downto 0);	
		readAddress		 	 : out bit_vector(63 downto 0);
		-- I/O relacionados ao victim buffer
		evictedBlockInstr    : out word_vector_type(31 downto 0);  
		evictedBlockAddr	 : out bit_vector(63 downto 0);
		readBlockAddr	     : out bit_vector(63 downto 0) 			--goes to L2 & VictimBuffer
		--isDequeueAddr_Inst   : out bit                            --vai indicar se tem bloco despejado. Se o set não estava cheio, não precisa despejar um bloco. Apesar de que ainda é interessante dar um fetch no victim buffer!
    );
end component;																			 

--------------------------------------------------------------------------------------
--FD cache de Dados
--------------------------------------------------------------------------------------
component cacheDPath is
    generic (
        accessTime: in time := 5 ns
    );
    port (

		-- I/O relacionados ao controle
		writeOptions		 : in  bit_vector(1 downto 0);
		memWrite			 : in  bit;
		updateInfo			 : in  bit;
		hit					 : out bit := '0';
		dirtyBit			 : out bit := '0';
		-- I/O relacionados ao MEM stage
        cpuAddr				 : in  bit_vector(63 downto 0);
		dataIn 				 : in  word_type;
		dataOut				 : out word_type;
		-- I/O relacionados ao L2 ou ao VB
        memBlocoData		 : in  word_vector_type(31 downto 0);    --na verdade, esse bloco novo pode ser tanto vindo do L2 como do victim buffer!
		L2BlockOut			 : out word_vector_type(31 downto 0) := (others => word_vector_init);
		-- I/O relacionados ao Victim Buffer
		evictedBlockData     : out word_vector_type(31 downto 0);
		evictedBlockAddr	 : out bit_vector(63 downto 0);
		readBlockAddr   	 : out bit_vector(63 downto 0)           --goes to L2 & VictimBuffer
		--isDequeueAddr_Data   : out bit 	  --vai indicar se tem bloco despejado. Se o set não estava cheio, não precisa despejar um bloco. Apesar de que ainda é interessante dar um fetch no victim buffer!
		
    );
end component;


component VBTopLevel is
    generic (
        accessTime: in time := 5 ns
    );
    port (			  
		clk 			   		   : in bit;
		queueInst		           : in  bit;
		queueData		           : in  bit;
		readyL2			   		   : in  bit;						 
		evictedBlockData		   : in  word_vector_type(31 downto 0);		-- Um bloco, 32 words
		evictedBlockDataAddress	   : in  bit_vector(63 downto 0);				 
		evictedBlockDataDirty 	   : in  bit;
		evictedBlockInst		   : in  word_vector_type(31 downto 0);		-- Um bloco, 32 words
		evictedBlockInstAddress	   : in  bit_vector(63 downto 0);
		evictedBlockInstDirty      : in  bit := '0';
		blockOut  	  			   : out word_vector_type(31 downto 0);     -- Saída do buffer: um bloco
		blockOutAddress			   : out bit_vector(63 downto 0);
		blockOutDataInst		   : out bit;								-- '1' if data else '0'
		blockOutDirty			   : out bit
    );
end component;	

signal I_writeOptions 		      						: bit;
signal D_writeOptions 			  						: bit_vector(1 downto 0);
signal I_updateInfo, D_updateInfo 						: bit;
signal I_hitSignal, D_hitSignal	  					    : bit;
signal I_readAddress		       			            : bit_vector(63 downto 0);
signal evictedBlockInst, evictedBlockData 			    : word_vector_type(31 downto 0);
signal evictedBlockInstAddress, evictedBlockDataAddress : bit_vector(63 downto 0);
signal D_dirtyBit										: bit;
signal I_L2Ready, D_L2Ready								: bit;
signal I_L2RW, D_L2RW									: bit;
signal I_L2Enable,D_L2Enable							: bit;
signal I_isFull,D_isFull 								: bit;
signal VBInstAccess, VBDataAccess 						: bit; 
signal D_cpu_write 										: bit;
signal queueInst, queueData 							: bit;	


begin
	CacheI_FD : CacheI generic map(accessTime) port map(I_writeOptions, I_updateInfo, I_hitSignal, I_cpuAddr, I_dataOut, I_L2_fetched, I_readAddress, evictedBlockInst, evictedBlockInstAddress, I_readBlockAddr);
		
	CacheD_FD : cacheDPath generic map(accessTime) port map(D_writeOptions, memWrite, D_updateInfo, D_hitSignal, D_dirtyBit, D_cpuAddr, dataIn, D_dataOut,
															 D_L2_fetched, D_L2BlockOut, evictedBlockData, evictedBlockDataAddress, D_readBlockAddr);
	
	CacheI_UC : ControlCacheI generic map(accessTime) port map(clk, I_stall, I_cpuAddr, I_hitSignal, I_writeOptions, I_updateInfo, I_L2Ready, I_L2RW, 
																I_L2Enable, I_isFull, VBInstAccess);					 
	
	CacheD_UC : ControlCacheD generic map(accessTime) port map(clk, clk_pipeline, D_cpu_write, D_cpuAddr, D_stall, D_dirtyBit, D_hitSignal, D_writeOptions,
																D_updateInfo, D_L2Ready, D_L2RW, D_L2Enable, D_isFull, VBDataAccess);
	
	victimBuffer : VBTopLevel generic map(accessTime) port map (clk, queueInst, queueData, readyL2, evictedBlockData, evictedBlockDataAddress, D_dirtyBit,
													  evictedBlockInst, evictedBlockInstAddress, '0', blockOut, blockOutAddress, blockOutDataInst, VB_BlockDirty);

end archi;