-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Cache de instrucoes (Fluxo de dados)

library ieee;
use ieee.numeric_bit.all;		


-- importa os types do projeto

use types.all;

entity CacheI is
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
		readAddressInstTag 	 : out bit_vector(49 downto 0);
		readAddressInstIndex : out bit_vector(6 downto 0);
		-- I/O relacionados ao victim buffer
		evictedBlockInstr    : out word_vector_type(31 downto 0);  
		evictedBlockTag	     : out bit_vector(49 downto 0);		 
		evictedBlockIndex    : out bit_vector(6 downto 0)
		--isDequeueAddr_Inst   : out bit                            --vai indicar se tem bloco despejado. Se o set não estava cheio, não precisa despejar um bloco. Apesar de que ainda é interessante dar um fetch no victim buffer!
    );
end entity CacheI;

architecture CacheIArch of CacheI is	 	  
							  
	constant cacheSize:        positive := 2**15; 					-- 32KBytes = 8192 * 4 bytes (4096 words de 32bits)
	constant palavrasPorBloco: positive := 32;
	constant blocoSize:        positive := palavrasPorBloco * 4; 	-- 32 * 4 = 128Bytes
    constant numberOfBlocks:   positive := cacheSize / blocoSize; 	-- 256 blocos
	
	--- Cada "linha" no cache possui valid + tag + data		   Esse type corresponde a um bloco dentro do cache
	type cacheRowType is record
        valid: bit;											   		--dirty bit entraria aqui também?
        tag:   bit_vector(49 downto 0);													--Resp. Só se mudarmos a associatividade aqui!
        data:  word_vector_type(palavrasPorBloco - 1 downto 0);
    end record cacheRowType;

    type cacheType is array (numberOfBlocks - 1 downto 0) of cacheRowType;												   														   

	--- definicao do cache												 
	signal cache: cacheType;
	
	--- Demais sinais internos
	signal memBlockAddr: natural;
	signal index: 		 natural;
	signal wordOffset:   natural;
	signal tag: 		 bit_vector(49 downto 0);
	
		
begin 
	-- obtem campos do cache a partir do endereco de entrada
	memBlockAddr <= to_integer(signed(cpuAddr(63 downto 7)));
	index        <= memBlockAddr mod numberOfBlocks;
	tag          <= cpuAddr(63 downto 14);
	wordOffset   <= to_integer(unsigned(cpuAddr(6 downto 2)));	 --para definir qual das 32 words de dentro do bloco mandar para output
							
    --  saidas
	hit          	  	 <= '1' when cache(index).valid = '1' and cache(index).tag = tag else '0';
	dataOut      	  	 <= cache(index).data(wordOffset);
	evictedBlockInstr 	 <= cache(index).data; 
	evictedBlockIndex 	 <= cpuAddr(13 downto 7);   --mesmo que cpuaddr responda a um bloco que está FORA do set, ainda se trata do mesmo index, então não tem problema aqui! Acho...
	evictedBlockTag   	 <= cache(index).tag;
	readAddressInstTag 	 <= cpuAddr(63 downto 14);
	readAddressInstIndex <= cpuAddr(13 downto 7);
	-- atualizacao do cache de acordo com os sinais de controle		
						
	
	process(updateInfo, writeOptions)
	begin
		if(updateInfo'event or writeOptions'event) then
			
			-- atualiza informacoes do cache
			if (updateInfo'event and updateInfo = '1') then
				cache(index).tag <= tag;
				cache(index).valid <= '1';
			end if;
			
			-- writeOptions 0 -> mantem valor do cache inalterado
			-- writeOptions 1 -> usa o valor do mem (ocorreu miss)
			if (writeOptions'event and writeOptions = '1') then
				cache(index).data <= memBlocoData;
			end if;
			
		end if;
	end process;
	
	
	
end architecture CacheIArch;