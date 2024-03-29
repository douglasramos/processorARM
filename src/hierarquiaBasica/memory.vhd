-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- PicoMIPS
--
-- Description:
--     Memoria Principal (RAM) - Level 2
--			Interface direta com CacheI e CacheD

library ieee;
use ieee.numeric_bit.all;
use std.textio.all;

-- importa os types do projeto
library arm;
use arm.types.all;


entity memory is
    generic (
        accessTime: in time := 40 ns
    );
    port (

		-- I/O relacionados cache de Instrucoes
		ciEnable:     in   bit := '0';
		ciMemRw:      in   bit; --- '1' write e '0' read
		ciAddr:       in   bit_vector(9 downto 0);
		ciDataBlock:  out  word_vector_type(1 downto 0) := (others => word_vector_init);
		ciMemReady:   out  bit := '0';

		-- I/O relacionados cache de dados
		cdEnable:    in  bit;
		cdMemRw:     in  bit; --- '1' write e '0' read
		cdAddr:      in  bit_vector(9 downto 0);
		cdDataIn:    in  word_vector_type(1 downto 0);
		cdDataOut:   out word_vector_type(1 downto 0) := (others => word_vector_init);
		cdMemReady:  out bit := '0'

    );
end entity memory;

architecture memory_arch of memory is

	constant memSize: positive := 2**10; -- 1024Bytes = 256 * 4 bytes (256 words de 32bits)
	constant wordsPerBlock: positive := 2;
	constant blockSize: positive := wordsPerBlock * 4; --- 8Bytes
    constant numberOfBlocks: positive := memSize / blockSize; -- 128 blocos

	--- Cada "linha" na memoria possui data, que corresponde a um bloco de dados
	type memRowType is record
        data:  word_vector_type(wordsPerBlock - 1 downto 0);
    end record memRowType;

	type memType is array (numberOfBlocks - 1 downto 0) of memRowType;

	--- leitura do arquivo memory.dat

	impure function readFile(fileName : in string) return memType is
		file     F  : text open read_mode is fileName;
		variable L    : line;
		variable tempWord  : word_type;
		variable tempMem : memType;
		begin
			for bloc in 0 to numberOfBlocks - 1 loop
				for offset in 0 to wordsPerBlock - 1 loop
					readline(F, L);
					read(L, tempWord);
					tempMem(bloc).data(offset) := tempWord;
				end loop;
			end loop;
			file_close(F);
			return tempMem;
		end;

	--- inicializa memoria
	signal memory : memType := readFile("memory.dat");

	--- Demais sinais internos
	signal ciBlockAddr: natural;
	signal ciIndex: natural;
	signal cdBlockAddr: natural;
	signal cdIndex: natural;
	signal enable: bit;

begin

	-- obtem index a partir do endereco de entrada
	ciBlockAddr <= to_integer(unsigned(ciAddr(9 downto 3)));
	ciIndex <= ciBlockAddr mod numberOfBlocks;

	cdBlockAddr <= to_integer(unsigned(cdAddr(9 downto 3)));
	cdIndex <= cdBlockAddr mod numberOfBlocks;

	-- enable geral
	enable <= ciEnable or cdEnable;

	-- atualizacao do cache de acordo com os sinais de controle
	process(enable)
	begin
		if (enable'event and enable = '1') then

			-- Inicio do processamento
			ciMemReady <= '0';
			cdMemReady <= '0';

			-- Memory Read Cache Instrucoes
			if (ciEnable = '1' and ciMemRw = '0') then
				ciDataBlock <=  memory(ciIndex).data after accessTime;
				ciMemReady  <=  '1' after accessTime;
			end if;

			-- Memory Read Cache Dados
			if (cdEnable = '1' and cdMemRw = '0') then
				cdDataOut   <=  memory(cdIndex).data after accessTime;
				cdMemReady  <=  '1' after accessTime;
			end if;

			-- Memory Write Cache Dados
			if (cdEnable = '1' and cdMemRw = '1') then
				memory(cdIndex).data <= cdDataIn after accessTime;
				cdMemReady  <= '1' after accessTime;
			end if;

		end if;
	end process;

	--- process para escrita no arquivo

	process(memory)
	file     F  : text open write_mode is "memory.dat";
	variable L    : line;
	variable tempWord  : word_type;
	begin
		if (memory'event) then
			for bloc in 0 to numberOfBlocks - 1 loop
				for offset in 0 to wordsPerBlock - 1 loop
					tempWord := memory(bloc).data(offset);
					write(L, tempWord);
					writeline(F, L);
				end loop;
			end loop;
			file_close(F);
		end if;
	end process;

end architecture memory_arch;