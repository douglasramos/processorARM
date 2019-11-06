-- PCS3412 - Organizacao e Arquitetura de Computadores II
-- PicoMIPS
--
-- Description:
--     Memoria Principal (RAM) - Level 3
--			Interface com Cache L2

library ieee;
use ieee.numeric_bit.all;
use std.textio.all;

-- importa os types do projeto
library arm;
use arm.types.all;


entity MemoryL3Path is
    generic (
        accessTime: in time := 200 ns
    );
    port (

		-- I/O relacionados ao controle
		RW:          in  bit_vector(1 downto 0);
		cRead:       out bit := '0';
		cWrite:      out bit := '0';

		-- I/O relacionados cache L2
		addr:      in  bit_vector(9 downto 0);
		dataIn:    in  word_vector_type(1 downto 0);
		dataOut:   out word_vector_type(1 downto 0) := (others => word_vector_init)
        
    );
end entity MemoryL3Path;

architecture MemoryL3Path_arch of MemoryL3Path is	 	  
							  
	constant memSize: positive := 2**10; -- 1KBytes = 256 * 4 bytes (256 words de 32bits)
	constant wordsPerBlock: positive := 2;
	constant blockSize: positive := wordsPerBlock * 4; --- 2 * 4 = 8 Bytes
    constant numberOfBlocks: positive := memSize / blockSize; --  128 blocos
		
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
	signal blockAddr: natural;
	signal index: natural;
	signal sdataOut: word_vector_type(1 downto 0);
	
begin 
	
	blockAddr <= to_integer(unsigned(addr(9 downto 3)));
	index <= blockAddr mod numberOfBlocks;
	
	-- leitura
	sdataOut <= (memory(index).data) after accessTime when RW = "01";
	dataOut <= sdataOut;
	cRead <= '1' when (sdataOut'event and RW /= "00") else '0';

	-- escrita
	memory(index).data <= (dataIn) after accessTime when RW = "10";
	cWrite <= '1' when (memory'event and RW /= "00") else '0'; 
	
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

end architecture MemoryL3Path_arch;