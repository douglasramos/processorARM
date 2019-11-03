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
		switchAddr:     in  bit;
		hit:            out bit := '0';
		dirtyBit:       out bit := '0';
		
		-- I/O relacionados ao victim buffer
		vbDataIn:       in word_vector_type(31 downto 0) := (others => word_vector_init);

		-- I/O relacionados ao cache de dados
		cdAddr:         in  bit_vector(63 downto 0);
		cdDataOut:      out word_vector_type(31 downto 0) := (others => word_vector_init);

		-- I/O relacionados ao cache de instruções
		ciAddr:         in  bit_vector(63 downto 0);
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

	signal addr: bit_vector(63 downto 0);
	signal memBlockAddr: natural;
	signal index: natural;
	signal wordOffset: natural;
	signal tag: bit_vector(46 downto 0);
	signal set_index: natural;
	signal hitSignal: bit; --- sinal interno utilizado para poder usar o hit na logica do set_index


begin

	-- lógica para definir qual endereço será análisado, dados ou instrução
	addr <= cdAddr when switchAddr = '1' else ciAddr;

	-- obtem campos do cache a partir do endereco de entrada
	memBlockAddr <= to_integer(unsigned(addr(63 downto 7)));
	index <= memBlockAddr mod number_of_sets;
	tag <= addr(63 downto 17);

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
	
	process(switchAddr)
	begin
		if(switchAddr'event) then
			if(switchAddr = '0') then
				ciDataOut <= cache(index).set(set_index).data after acessTime;
			elsif (switchAddr = '1') then
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