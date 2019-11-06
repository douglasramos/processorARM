-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Cache de instrucoes (Fluxo de dados)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto

use types.all;


entity cacheIPath is
    generic (
        accessTime: in time := 5 ns
    );
    port (

		-- I/O relacionados ao controle
		writeOptions:   in  bit;
		updateInfo:     in  bit;
		hit:            out bit := '0';

		-- I/O relacionados ao IF stage
        cpuAddr: in  bit_vector(9 downto 0);
        dataOut: out word_type := (others => '0');

        -- I/O relacionados a Memoria princial
        memBlocoData: in  word_vector_type(1 downto 0);
		memAddr:      out bit_vector(9 downto 0) := (others => '0')


    );
end entity cacheIPath;

architecture cacheIPath_arch of cacheIPath is

	constant cacheSize:        positive := 32; -- 32Bytes (8 palavras)
	constant palavrasPorBloco: positive := 2;
	constant blocoSize:        positive := palavrasPorBloco * 4; --- 2 * 4 = 8Bytes
    constant numberOfBlocks:   positive := cacheSize / blocoSize; --- 4

	--- Cada "linha" no cache possui valid + tag + data
	type cache_row_type is record
        valid: bit;
        tag:   bit_vector(4 downto 0);
        data:  word_vector_type(palavrasPorBloco - 1 downto 0);
    end record cache_row_type;

    type cache_type is array (numberOfBlocks - 1 downto 0) of cache_row_type;

	constant cache_row_init : cache_row_type := (valid => '0',
												 tag => (others => '0'),
												 data => (others => word_vector_init));

	--- definicao do cache
    signal cache: cache_type := (others => cache_row_init);

	--- Sinais internos
	signal memBlockAddr: natural;
	signal index: natural;
	signal wordOffset: natural;
	signal tag: bit_vector(4 downto 0);


begin
	-- obtem campos do cache a partir do endereco de entrada
	memBlockAddr <= to_integer(unsigned(cpuAddr(9 downto 3)));
	index        <= memBlockAddr mod numberOfBlocks;
	tag          <= cpuAddr(9 downto 5);
	wordOffset   <= to_integer(unsigned(cpuAddr(2 downto 2)));


    --  saidas
	hit     <= '1' when cache(index).valid = '1' and cache(index).tag = tag else '0';
	dataOut <=	cache(index).data(wordOffset);
	memAddr <= cpuAddr;

	-- atualizacao do cache de acordo com os sinais de controle
	process(updateInfo, writeOptions)
	begin
		if (updateInfo'event or writeOptions'event) then

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

end architecture cacheIPath_arch;