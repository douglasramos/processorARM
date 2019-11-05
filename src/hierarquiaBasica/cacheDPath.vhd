-- PCS3412 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Cache de dados (Fluxo de dados)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto
library arm;
use arm.types.all;


entity cacheDPath is
    generic (
        accessTime: in time := 5 ns
    );
    port (

		-- I/O relacionados ao controle
		writeOptions:   in  bit_vector(1 downto 0);
		updateInfo:     in  bit;
		hit:            out bit := '0';
		dirtyBit:       out bit := '0';

		-- I/O relacionados ao MEM stage
        cpuAddr:        in  bit_vector(9 downto 0);
		dataIn :        in  word_type;
		dataOut:        out word_type;

		-- I/O relacionados a Memoria princial
        memBlockIn:    in  word_vector_type(1 downto 0);
		memAddr:       out bit_vector(9 downto 0) := (others => '0');
		memBlockOut:   out word_vector_type(1 downto 0) := (others => word_vector_init)

    );
end entity cacheDPath;

architecture cacheDPath_arch of cacheDPath is

	constant cacheSize:        positive := 32; -- 32Bytes (8 palavras)
	constant palavrasPorBloco: positive := 2;
	constant blocoSize:        positive := palavrasPorBloco * 4; --- 2 * 4 = 8Bytes
    constant numberOfBlocks:   positive := cacheSize / blocoSize; --- 4

	--- Cada "linha" em um conjunto possui valid + dirty + tag + data
	type cache_row_type is record
         valid: bit;
		 dirty: bit;
         tag:   bit_vector(4 downto 0);
         data:  word_vector_type(palavrasPorBloco - 1 downto 0);
    end record cache_row_type;

	type cache_type is array (numberOfBlocks - 1 downto 0) of cache_row_type;


    --- Cache eh formado por um array de conjuntos
	type cacheType is array (numberOfBlocks - 1 downto 0) of cache_row_type;

	constant cache_row_init : cache_row_type := (valid => '0',
												 tag => (others => '0'),
												 dirty => '0',
												 data => (others => word_vector_init));
	--- definicao do cache
    signal cache: cache_type := (others => cache_row_init);

	-- demais sinais internos
	signal memBlockAddr: natural;
	signal index: natural;
	signal wordOffset: natural;
	signal tag: bit_vector(4 downto 0);
	signal set_index: natural;

begin
	-- obtem campos do cache a partir do endereco de entrada
	memBlockAddr <= to_integer(unsigned(cpuAddr(9 downto 3)));
	index <= memBlockAddr mod numberOfBlocks;
	tag <= cpuAddr(9 downto 5);
	wordOffset <= to_integer(unsigned(cpuAddr(2 downto 2)));

	-- Logica que define o index dentro do conjunto em caso de hit ou nao.
	-- Note que caso o conjunto esteja cheio, troca-se sempre o primeiro bloco

	-- dois (2 blocos por conjunto) comparadores em paralelo para definir o hit
	hit <= '1' when (cache(index).valid = '1' and cache(index).tag = tag) or
	                 (cache(index).valid = '1' and cache(index).tag = tag) else '0';

	--  saidas
	dataOut <=	cache(index).data(wordOffset) after accessTime;
	memAddr <= cpuAddr;
	dirtyBit <= cache(index).dirty;
	memBlockOut <= cache(index).data;

	-- atualizacao do cache de acordo com os sinais de controle
	process(updateInfo, writeOptions)
	begin
		if (updateInfo'event or writeOptions'event) then

			-- atualiza info (tag e valid bit)
			if (updateInfo'event and updateInfo = '1') then
				cache(index).tag <= tag;
				cache(index).valid <= '1';
			end if;

			-- writeOptions 00 -> mantem valor do cache inalterado
			-- writeOptions 01 -> usa o valor do mem (ocorreu miss)
			-- writeOptions 10 -> usa o valor do dataIn (cpu write)
			if (writeOptions = "01") then
				cache(index).data <= memBlockIn;

			elsif (writeOptions = "10") then
				cache(index).data(wordOffset) <= dataIn after accessTime;
				cache(index).dirty <= '1';
			end if;

		end if;
	end process;

end architecture cacheDPath_arch;