-- PCS3412 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Cache de dados (Fluxo de dados)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto

use types.all;


entity cacheDPath is
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
		readAddressDataTag 	 : out bit_vector(49 downto 0);
		readAddressDataIndex : out bit_vector(6 downto 0);
		-- I/O relacionados ao Victim Buffer
		evictedBlockData     : out word_vector_type(31 downto 0);  
		evictedBlockTag	     : out bit_vector(49 downto 0);		 
		evictedBlockIndex    : out bit_vector(6 downto 0)
		--isDequeueAddr_Data   : out bit 	  --vai indicar se tem bloco despejado. Se o set não estava cheio, não precisa despejar um bloco. Apesar de que ainda é interessante dar um fetch no victim buffer!
		
    );
end entity cacheDPath;

architecture cacheDPath_arch of cacheDPath is

	constant cacheSize: positive := 2**15; -- 32KBytes = 8192 * 4 bytes (4096 words de 32bits)
	constant words_per_block: positive := 32;
	constant blocoSize: positive := words_per_block * 4; --- 32 * 4 = 128Bytes
    constant numberOfBlocks: positive := cacheSize / blocoSize; -- 256 blocos
	constant blocks_per_set: positive := 2; -- Associativo por conjunto de 2 blocos
	constant number_of_sets: positive := numberOfBlocks / blocks_per_set; --  128 conjuntos


	--- Cada "linha" em um conjunto possui valid + dirty + tag + data
	type block_row_type is record
         valid: bit;
		 dirty: bit;
         tag:   bit_vector(49 downto 0);
         data:  word_vector_type(words_per_block - 1 downto 0);
    end record block_row_type;

	type set_type is array (blocks_per_set - 1 downto 0) of block_row_type;

	constant block_row_init : block_row_type := (valid => '0',
										         dirty => '0',
										         tag =>   (others => '0'),
											     data =>  (others => word_vector_init));

	
    --- Cache eh formado por um array de conjuntos
	type set_vector_type is record
		 set: set_type;
    end record set_vector_type;

	type cacheType is array (number_of_sets - 1 downto 0) of set_vector_type;

	constant cache_set_init : set_vector_type := (set => (others => block_row_init));

	--- definicao do cache
    signal cache: cacheType;

	signal memBlockAddr: natural;
	signal index: natural;
	signal wordOffset: natural;
	signal tag: bit_vector(49 downto 0);
	signal set_index: natural;
	signal hitSignal: bit; --- sinal interno utilizado para poder usar o hit na logica do set_index


begin
	-- obtem campos do cache a partir do endereï¿½o de entrada
	memBlockAddr <= to_integer(unsigned(cpuAddr(63 downto 7)));
	index 		 <= memBlockAddr mod number_of_sets;
	tag 		 <= cpuAddr(63 downto 14);
	wordOffset 	 <= to_integer(unsigned(cpuAddr(6 downto 2)));

	-- Logica que define o index dentro do conjunto em caso de hit ou nao.
	-- Note que caso o conjunto esteja cheio, troca-se sempre o primeiro bloco		  -----------------implementar LRU aqui!!!
	set_index <= 0 when (cache(index).set(0).valid = '1' and cache(index).set(0).tag = tag) or
	                    (hitSignal = '0' and cache(index).set(0).valid = '0') else
    			 1 when (cache(index).set(1).valid = '1' and cache(index).set(1).tag = tag) or
			            (hitSignal = '0' and cache(index).set(1).valid = '0') else 0;

	-- dois (2 blocos por conjunto) comparadores em paralelo para definir o hit
	hitSignal <= '1' when (cache(index).set(0).valid = '1' and cache(index).set(0).tag = tag) or
	                 (cache(index).set(1).valid = '1' and cache(index).set(1).tag = tag) else '0';

	--  saidas

	hit <= hitSignal;

	dataOut <=	cache(index).set(set_index).data(wordOffset) after accessTime;

	dirtyBit <= cache(index).set(set_index).dirty;

	L2BlockOut <= cache(index).set(set_index).data;
	
	evictedBlockData 	 <= cache(index).set(set_index).data; 
	evictedBlockIndex 	 <= cpuAddr(13 downto 7);   --mesmo que cpuaddr responda a um bloco que está FORA do set, ainda se trata do mesmo index, então não tem problema aqui! Acho...
	evictedBlockTag   	 <= cache(index).set(set_index).tag;
	readAddressDataTag 	 <= cpuAddr(63 downto 14);
	readAddressDataIndex <= cpuAddr(13 downto 7);
	-- atualizacao do cache de acordo com os sinais de controle
	process(updateInfo, writeOptions, memWrite)
	begin
		if (updateInfo'event or writeOptions'event) then

			-- atualiza info (tag e valid bit)
			if (updateInfo'event and updateInfo = '1') then
				cache(index).set(set_index).tag <= tag;
				cache(index).set(set_index).valid <= '1';
			end if;

			-- writeOptions 00 -> mantem valor do cache inalterado
			-- writeOptions 01 -> usa o valor do mem (ocorreu miss)
			-- writeOptions 10 -> usa o valor do dataIn (cpu write)
			if (writeOptions = "01") then
				cache(index).set(set_index).data <= memBlocoData;

			elsif (writeOptions = "10") then
				cache(index).set(set_index).data(wordOffset) <= dataIn after accessTime;
				cache(index).set(set_index).dirty <= '1';
			end if;

			-- Escreve na memoria
			if (memWrite'event and memWrite = '1') then
				--memBlockOut <= cache(index).set(set_index).data after accessTime;
			end if;

		end if;
	end process;

end architecture cacheDPath_arch;