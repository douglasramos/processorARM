-- PCS3422 - Organizacao e Arquitetura de Computadores II
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
		writeOptions:   in  bit_vector(1 downto 0);
		updateInfo:     in  bit;
		updateLRU:      in  bit;
		hit:            out bit := '0';
		dirtyBit:       out bit := '0';
		valid:          out bit := '0';

		-- I/O relacionados ao MEM stage
        cpuAddr:        in  bit_vector(9 downto 0);
		dataIn :        in  word_type;
		dataOut:        out word_type;

		-- I/O relacionados ao L2
        L2BlockIn:     in  word_vector_type(1 downto 0);
		L2Addr:        out bit_vector(9 downto 0) := (others => '0');
		L2BlockOut:    out word_vector_type(1 downto 0) := (others => word_vector_init);

		-- I/O relacionados ao Victim Buffer
		evictedBlockData     : out word_vector_type(1 downto 0);
		evictedBlockAddr	 : out bit_vector(9 downto 0)
    );
end entity cacheDPath;

architecture cacheDPath_arch of cacheDPath is

	constant cacheSize:        positive := 64; -- 64Bytes (16 palavras)
	constant palavrasPorBloco: positive := 2;
	constant blocoSize:        positive := palavrasPorBloco * 4; --- 2 * 4 = 8Bytes
	constant numberOfBlocks:   positive := cacheSize / blocoSize; --- 8
	constant blocksPerSet:     positive := 2; -- Associativo por conjunto de 2 blocos
	constant numberOfSets:     positive := numberOfBlocks / blocksPerSet; --  4 conjuntos

	--- Cada bloco possui valid + tag + data
	type block_row_type is record
		valid: bit;
		dirty: bit;
        tag:   bit_vector(4 downto 0);
        data:  word_vector_type(palavrasPorBloco - 1 downto 0);
    end record block_row_type;

	constant block_row_init : block_row_type := (valid => '0',
                                                 dirty => '0',
										         tag =>   (others => '0'),
											     data =>  (others => word_vector_init));

	-- set
    type set_type is array (blocksPerSet - 1 downto 0) of block_row_type;

	type set_vector_type is record  -- Cache eh formado por um array de conjuntos
		set: set_type;
		LRU: natural;
    end record set_vector_type;

	type cache_type is array (numberOfSets - 1 downto 0) of set_vector_type;

	constant set_vector_init : set_vector_type := (set => (others => block_row_init),
												   LRU => 0);

	--- definicao do cache
    signal cache: cache_type := (others => set_vector_init);

	--- Sinais internos
	signal memBlockAddr: natural;
	signal index: natural;
	signal wordOffset: natural;
	signal tag: bit_vector(4 downto 0);
	signal setIndex: natural;
	signal hitSignal: bit; --- sinal interno utilizado para poder usar o hit na logica do setIndex

begin
	-- obtem campos do cache a partir do endereco de entrada
	memBlockAddr <= to_integer(unsigned(cpuAddr(9 downto 3)));
	index <= memBlockAddr mod numberOfSets;
	tag <= cpuAddr(9 downto 5);
	wordOffset <= to_integer(unsigned(cpuAddr(2 downto 2)));

	-- Logica que define o index dentro do conjunto em caso de hit ou nao.
	-- Note que caso o conjunto esteja cheio, troca-se sempre o primeiro bloco
	setIndex <= 0 when (cache(index).set(0).valid = '1' and cache(index).set(0).tag = tag) or
	                    (hitSignal = '0' and cache(index).set(0).valid = '0') else
    			1 when (cache(index).set(1).valid = '1' and cache(index).set(1).tag = tag) or
			            (hitSignal = '0' and cache(index).set(1).valid = '0') else 0;

	-- dois (2 blocos por conjunto) comparadores em paralelo para definir o hit
	hitSignal <= '1' when (cache(index).set(0).valid = '1' and cache(index).set(0).tag = tag) or
					 (cache(index).set(1).valid = '1' and cache(index).set(1).tag = tag) else '0';

	--  saidas
    dataOut <=	cache(index).set(setIndex).data(wordOffset) after accessTime;
	valid <= cache(index).set(setIndex).valid;
	L2Addr <= cpuAddr;
	dirtyBit <= cache(index).set(setIndex).dirty;
	hit <= hitSignal;

	-- monta address e data do bloco a ser mandado para o VB
	evictedBlockData <= cache(index).set(setIndex).data;   -- posicao index do addr que entra no index do bloco que sai tambem

	evictedBlockAddr(9 downto 5)  <= cache(index).set(setIndex).tag;
	evictedBlockAddr(4 downto 3)  <= cpuAddr(4 downto 3);
	evictedBlockAddr(2  downto 0) <= "000";

	-- atualizacao do cache de acordo com os sinais de controle
	process(updateInfo, writeOptions)
	begin
		if (updateInfo'event or writeOptions'event or updateLRU'event) then

			-- atualiza info (tag e valid bit)
			if (updateInfo'event and updateInfo = '1') then
				cache(index).set(setIndex).tag <= tag;
				cache(index).set(setIndex).valid <= '1';
			end if;

			-- writeOptions 00 -> mantem valor do cache inalterado
			-- writeOptions 01 -> usa o valor do mem (ocorreu miss)
			-- writeOptions 10 -> usa o valor do dataIn (cpu write)
			if (writeOptions = "01") then
				cache(index).set(setIndex).data <= L2BlockIn;
				cache(index).set(setIndex).dirty <= '0'; -- agora cache e mem estão atualizados

			elsif (writeOptions = "10") then
				cache(index).set(setIndex).data(wordOffset) <= dataIn after accessTime;
				cache(index).set(setIndex).dirty <= '1';
			end if;

			if(updateLRU'event and updateLRU = '1') then
				if (setIndex = 1) then
					cache(index).LRU <= 0;
				else
					cache(index).LRU <= 1;
				end if;
			end if;

		end if;
	end process;

end architecture cacheDPath_arch;