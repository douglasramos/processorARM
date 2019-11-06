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
		addrOptions:    in  bit_vector(1 downto 0);
		updateInfo:     in  bit;
		ciL2Hit:        in  bit;
		cdL2Hit:        in  bit;
		hit:            out bit := '0';
		dirtyBit:       out bit := '0';
		
		-- I/O relacionados ao victim buffer
		vbDataIn:       in word_vector_type(1 downto 0) := (others => word_vector_init);
		vbAddr:          in  bit_vector(9 downto 0);
		dirtyData:       in  bit;

		-- I/O relacionados ao cache de dados
		cdAddr:          in  bit_vector(9 downto 0);
		cdDataOut:      out word_vector_type(1 downto 0) := (others => word_vector_init);

		-- I/O relacionados ao cache de instruções
		ciAddr:         in  bit_vector(9 downto 0);
		ciDataOut:      out word_vector_type(1 downto 0) := (others => word_vector_init);

		-- I/O relacionados a Memoria princial
        memBlockIn:     in  word_vector_type(1 downto 0);
		memAddr:        out bit_vector(9 downto 0) := (others => '0');
		memBlockOut:    out word_vector_type(1 downto 0) := (others => word_vector_init)

    );
end entity cacheL2Path;



architecture cacheL2Path_arch of cacheL2Path is

	constant cacheSize: positive := 2**8; -- 256Bytes = 64 * 4 bytes (64 words de 32bits)
	constant words_per_block: positive := 2;
	constant blocoSize: positive := words_per_block * 4; --- 2 * 4 = 8 Bytes
	constant numberOfBlocks: positive := cacheSize / blocoSize; -- 32 blocos
	constant blocks_per_set: positive := 2; -- Associativo por conjunto de 2 blocos
	constant number_of_sets: positive := numberOfBlocks / blocks_per_set; --  16 conjuntos


	--- Cada "linha" em um conjunto possui valid + dirty + tag + data
	type block_row_type is record
         valid: bit;
		 dirty: bit;
         tag:   bit_vector(2 downto 0);
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

	signal addr: bit_vector(9 downto 0);
	signal memBlockAddr: natural;
	signal index: natural;
	signal tag: bit_vector(2 downto 0);
	signal set_index: natural;
	signal hitSignal: bit; --- sinal interno utilizado para poder usar o hit na logica do set_index


begin

	-- logica para definir qual idenx ou tag será analisado, o de dados ou o de instrucao
	addr <= ciAddr when (addrOptions = "01") else
		    cdAddr when (addrOptions = "10") else
			vbAddr when (addrOptions = "11");
	

	-- obtem campos do cache a partir do endere?o de entrada
	memBlockAddr <= to_integer(unsigned(addr(9 downto 3)));
	index 		 <= memBlockAddr mod number_of_sets;
	tag 		 <= addr(9 downto 7);

	-- Logica que define o index dentro do conjunto em caso de hit ou nao.
	-- Note que caso o conjunto esteja cheio, troca-se sempre o primeiro bloco
	set_index <= 0 when (cache(index).set(0).valid = '1' and cache(index).set(0).tag = tag) or
						(hitSignal = '0' and cache(index).set(0).valid = '0') else
				 1 when (cache(index).set(1).valid = '1' and cache(index).set(1).tag = tag) or
						(hitSignal = '0' and cache(index).set(1).valid = '0') else 0;

	-- dois (2 blocos por conjunto) comparadores em paralelo para definir o hit
	hitSignal <= '1' when (cache(index).set(0).valid = '1' and cache(index).set(0).tag = tag) or
						  (cache(index).set(1).valid = '1' and cache(index).set(1).tag = tag) 
					 else '0';

	--  saidas

	hit <= hitSignal;

	memAddr <= addr;

	dirtyBit <= cache(index).set(set_index).dirty;

	memBlockOut <= cache(index).set(set_index).data after accessTime;

	ciDataOut <= (cache(index).set(set_index).data) after accessTime when ciL2Hit = '1';

	cdDataOut <= (cache(index).set(set_index).data) after accessTime when cdL2Hit = '1';
	

	-- atualizacao do cache de acordo com os sinais de controle
	process(updateInfo, writeOptions)
	begin
		if (updateInfo'event or writeOptions'event) then

			-- atualiza info (tag e valid bit)
			if (updateInfo'event and updateInfo = '1') then
				cache(index).set(set_index).tag <= tag;
				cache(index).set(set_index).valid <= '1';
			end if;

			-- writeOptions 00 -> mantem valor do cache inalterado
			-- writeOptions 01 -> usa o valor do mem (ocorreu miss)
			-- writeOptions 10 -> usa o valor do vbDataIn (victim buffer write)
			if (writeOptions = "01") then
				cache(index).set(set_index).data <= memBlockIn;
				-- atualizou com a memoria => dirty bit recebe 0
				cache(index).set(set_index).dirty <= '0';

			elsif (writeOptions = "10") then
				cache(index).set(set_index).data <= vbDataIn after accessTime;
				if dirtyData = '1' then 
					cache(index).set(set_index).dirty <= '1';
				end if;
			end if;


		end if;
	end process;

end architecture cacheL2Path_arch;