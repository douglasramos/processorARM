-- PCS3412 - Organizacao e Arquitetura de Computadores I
-- PicoMIPS
-- Author: Douglas Ramos
-- Co-Authors: Pedro Brito, Rafael Higa
--
-- Description:
--     Cache de dados

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- importa os types do projeto
library pipeline;
use pipeline.types.all;


entity CacheD is
    generic (
        accessTime: in time := 5 ns
    );
    port (

		-- I/O relacionados ao controle
		writeOptions:   in  bit_vector(1 downto 0);
		memWrite:       in  bit;
		updateInfo:     in  bit;
		hit:            out bit := '0';
		dirtyBit:       out bit := '0';

		-- I/O relacionados ao MEM stage
        cpuAdrr:        in  bit_vector(15 downto 0);
		dataIn :        in  wordType;
		dataOut:        out wordType;

		-- I/O relacionados a Memoria princial
        memBlockIn:    in  wordVectorType(15 downto 0);
		memAddr:       out bit_vector(15 downto 0) := (others => '0');
		memBlockOut:   out wordVectorType(15 downto 0) := (others => word_vector_init)

    );
end entity CacheD;

architecture CacheD_arch of CacheD is

	constant cacheSize: positive := 2**14; -- 16KBytes = 4096 * 4 bytes (4096 words de 32bits)
	constant words_per_block: positive := 16;
	constant blocoSize: positive := words_per_block * 4; --- 16 * 4 = 64Bytes
    constant numberOfBlocks: positive := cacheSize / blocoSize; -- 256 blocos
	constant blocks_per_set: positive := 2; -- Associativo por conjunto de 2 blocos
	constant number_of_sets: positive := numberOfBlocks / blocks_per_set; --  128 conjuntos


	--- Cada "linha" em um conjunto possui valid + dirty + tag + data
	type block_row_type is record
         valid: bit;
		 dirty: bit;
         tag:   bit_vector(2 downto 0);
         data:  wordVectorType(words_per_block - 1 downto 0);
    end record block_row_type;

	type set_type is array (blocks_per_set - 1 downto 0) of block_row_type;

	constant block_row_init : block_row_type := (valid => '0',
										         dirty => '0',
										         tag =>   (others => '0'),
											     data =>  (others => word_vector_init));

	constant block_with_value : block_row_type := (valid => '1',
										           dirty =>  '0',
										           tag =>   (others => '0'),
											       data =>  (0 => word_vector_value,
												             others => word_vector_init));		  
												   
	constant block_with_value2 : block_row_type := (valid => '1',
										            dirty => '0',
										            tag =>   (others => '0'),
											        data =>  (0 => word_vector_value2 ,
												   			 others => word_vector_init));
												   
   	constant block_with_value3 : block_row_type := (valid => '1',
										            dirty => '0',
										            tag =>   (others => '0'),
											        data =>  (0 => word_vector_value3 ,
												   			 others => word_vector_init));
												   
    constant block_with_value4 : block_row_type := (valid => '1',
										            dirty => '0',
										            tag =>   (others => '0'),
											        data =>  (0 => word_vector_value4 ,
													         others => word_vector_init));											
												   
    --- Cache eh formado por um array de conjuntos
	type set_vector_type is record
		 set: set_type;
    end record set_vector_type;

	type cacheType is array (number_of_sets - 1 downto 0) of set_vector_type;

	constant cache_set_init : set_vector_type := (set => (others => block_row_init));

	constant cache_set_with_value  : set_vector_type := (set => (0 => block_with_value,  1 => block_row_init));
	constant cache_set_with_value2 : set_vector_type := (set => (0 => block_with_value2, 1 => block_row_init));
	constant cache_set_with_value3 : set_vector_type := (set => (0 => block_with_value3, 1 => block_row_init));
	constant cache_set_with_value4 : set_vector_type := (set => (0 => block_with_value4, 1 => block_row_init));

	--- definicao do cache
    signal cache: cacheType := (4 => cache_set_with_value,    -- endere�o x100
								 84 => cache_set_with_value2,   -- endere�o x1500
								 88 => cache_set_with_value3,   -- endere�o x1600
								 92 => cache_set_with_value4,   -- endere�o x1700
								 others => cache_set_init);

	signal memBlockAddr: natural;
	signal index: natural;
	signal wordOffset: natural;
	signal tag: bit_vector(2 downto 0);
	signal set_index: natural;
	signal hitSignal: bit; --- sinal interno utilizado para poder usar o hit na logica do set_index


begin
	-- obtem campos do cache a partir do endere�o de entrada
	memBlockAddr <= to_integer(unsigned(cpuAdrr(15 downto 6)));
	index <= memBlockAddr mod number_of_sets;
	tag <= cpuAdrr(15 downto 13);
	wordOffset <= to_integer(unsigned(cpuAdrr(5 downto 2)));

	-- Logica que define o index dentro do conjunto em caso de hit ou nao.
	-- Note que caso o conjunto esteja cheio, troca-se sempre o primeiro bloco
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

	memAddr <= cpuAdrr;

	dirtyBit <= cache(index).set(set_index).dirty;

	memBlockOut <= cache(index).set(set_index).data;

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
				cache(index).set(set_index).data <= memBlockIn;

			elsif (writeOptions = "10") then
				cache(index).set(set_index).data(wordOffset) <= dataIn after accessTime;
				cache(index).set(set_index).dirty <= '1';
			end if;

			-- Escreve na memoria
			if (memWrite'event and memWrite = '1') then
				memBlockOut <= cache(index).set(set_index).data after accessTime;
			end if;

		end if;
	end process;

end architecture CacheD_arch;