-- PCS3412 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Cache L2 (Fluxo de dados)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto
library arm;
use arm.types.all;


entity cacheL2Path is
    generic (
        accessTime: in time := 5 ns
    );
    port (

		-- I/O relacionados ao controle
		writeOptions:   in  bit_vector(1 downto 0);
		memWrite:       in  bit;
		updateInfo:     in  bit;
		addrCacheD:     in  bit;
		hit:            out bit := '0';
		dirtyBit:       out bit := '0';
		
		-- I/O relacionados ao victim buffer
		vbDataIn:       in word_vector_type(31 downto 0) := (others => word_vector_init);
		vbTag:          in  bit_vector(46 downto 0);
		vbIndex:        in  bit_vector(6 downto 0);

		-- I/O relacionados ao cache de dados
		cdTag:          in  bit_vector(46 downto 0);
		cdIndex:        in  bit_vector(6 downto 0);
		cdDataOut:      out word_vector_type(31 downto 0) := (others => word_vector_init);

		-- I/O relacionados ao cache de instruções
		ciTag:          in  bit_vector(46 downto 0);
		ciIndex:        in  bit_vector(6 downto 0);
		ciDataOut:      out word_vector_type(31 downto 0) := (others => word_vector_init);

		-- I/O relacionados a Memoria princial
        memBlockIn:     in  word_vector_type(31 downto 0);
		memAddr:        out bit_vector(63 downto 0) := (others => '0');
		memBlockOut:    out word_vector_type(31 downto 0) := (others => word_vector_init)

    );
end entity cacheL2Path;



architecture cacheL2Path_arch of cacheL2Path is

	constant cacheSize: positive := 2**17; -- 128KBytes = ‭32.768‬ * 4 bytes (‭32.768‬ words de 32bits)
	constant words_per_block: positive := 32;
	constant blocoSize: positive := words_per_block * 4; --- 32 * 4 = 128Bytes
    constant numberOfBlocks: positive := cacheSize / blocoSize; -- 1024 blocos
	constant blocks_per_set: positive := 8; -- Associativo por conjunto de 8 blocos
	constant number_of_sets: positive := numberOfBlocks / blocks_per_set; --  128 conjuntos


	--- Cada "linha" em um conjunto possui valid + dirty + tag + data
	type block_row_type is record
         valid: bit;
		 dirty: bit;
         tag:   bit_vector(46 downto 0);
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
    signal cache: cacheType := (others => cache_set_init);
	signal index: natural;
	signal tag: bit_vector(46 downto 0);
	signal set_index: natural;
	signal hitSignal: bit; --- sinal interno utilizado para poder usar o hit na logica do set_index


begin

	-- lógica para definir qual idenx ou tag será análisado, o de dados ou o de instrução
	index <= to_integer(unsigned(ciIndex) when addrCacheD = '1' else to_integer(unsigned(cdIndex);
	tag <= to_integer(unsigned(ciTag) when addrCacheD = '1' else to_integer(unsigned(cdTag);

	-- Logica que define o index dentro do conjunto em caso de hit ou nao.
	-- Note que caso o conjunto esteja cheio, troca-se sempre o primeiro bloco
	set_index <= 0 when (cache(index).set(0).valid = '1' and cache(index).set(0).tag = tag) or
						(hitSignal = '0' and cache(index).set(0).valid = '0') else
				 1 when (cache(index).set(1).valid = '1' and cache(index).set(1).tag = tag) or
						(hitSignal = '0' and cache(index).set(1).valid = '0') else
				 2 when (cache(index).set(2).valid = '1' and cache(index).set(2).tag = tag) or
						(hitSignal = '0' and cache(index).set(0).valid = '0') else
				 3 when (cache(index).set(3).valid = '1' and cache(index).set(3).tag = tag) or
						(hitSignal = '0' and cache(index).set(0).valid = '0') else
				 4 when (cache(index).set(4).valid = '1' and cache(index).set(4).tag = tag) or
						(hitSignal = '0' and cache(index).set(0).valid = '0') else
				 5 when (cache(index).set(5).valid = '1' and cache(index).set(5).tag = tag) or
						(hitSignal = '0' and cache(index).set(5).valid = '0') else
				 6 when (cache(index).set(6).valid = '1' and cache(index).set(6).tag = tag) or
	                    (hitSignal = '0' and cache(index).set(6).valid = '0') else
    			 7 when (cache(index).set(7).valid = '1' and cache(index).set(7).tag = tag) or
			            (hitSignal = '0' and cache(index).set(7).valid = '0') else 0;

	-- oito (8 blocos por conjunto) comparadores em paralelo para definir o hit
	hitSignal <= '1' when (cache(index).set(0).valid = '1' and cache(index).set(0).tag = tag) or
					 (cache(index).set(1).valid = '1' and cache(index).set(1).tag = tag) or
					 (cache(index).set(2).valid = '1' and cache(index).set(2).tag = tag) or
					 (cache(index).set(3).valid = '1' and cache(index).set(3).tag = tag) or
					 (cache(index).set(4).valid = '1' and cache(index).set(4).tag = tag) or
					 (cache(index).set(5).valid = '1' and cache(index).set(5).tag = tag) or
					 (cache(index).set(6).valid = '1' and cache(index).set(6).tag = tag) or
	                 (cache(index).set(7).valid = '1' and cache(index).set(7).tag = tag) else '0';

	--  saidas

	hit <= hitSignal;

	memAddr <= addr;

	dirtyBit <= cache(index).set(set_index).dirty;

	memBlockOut <= cache(index).set(set_index).data;

	ciDataOut <= cache(index).set(set_index).data after acessTime;

	cdDataOut <= cache(index).set(set_index).data after acessTime;
	
	process(addrCacheD)
	begin
		if(addrCacheD'event) then
			if(addrCacheD = '0') then
				ciDataOut <= cache(index).set(set_index).data after acessTime;
			elsif (addrCacheD = '1') then
				cdDataOut <= cache(index).set(set_index).data after acessTime;
			end if;
		end if;
	end process;

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
			-- writeOptions 10 -> usa o valor do vbDataIn (victim budder write)
			if (writeOptions = "01") then
				cache(index).set(set_index).data <= memBlockIn;

			elsif (writeOptions = "10") then
				-- implementar lógica de substituição de blocos (usa o que estiver vazio, se não sobrescreve o indice 0)
				cache(index).set(set_index).data(wordOffset) <= dataIn after accessTime;
				cache(index).set(set_index).dirty <= '1';
			end if;

			-- Escreve na memoria
			if (memWrite'event and memWrite = '1') then
				memBlockOut <= cache(index).set(set_index).data after accessTime;
			end if;

		end if;
	end process;

end architecture cacheL2Path_arch;