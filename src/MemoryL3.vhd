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


entity MemoryL3 is
    generic (
        accessTime: in time := 40 ns
    );
    port (

		-- I/O relacionados cache L2
		enable:    in  bit;
		memRw:    in  bit; --- '1' write e '0' read
		addr:      in  bit_vector(31 downto 0);
		dataIn:   in  word_vector_type(31 downto 0);
		dataOut:  out word_vector_type(31 downto 0) := (others => word_vector_init);
		memReady: out bit := '0' 
        
    );
end entity MemoryL3;

architecture MemoryL3_arch of MemoryL3 is	 	  
							  
	constant memSize: positive := 2**18; -- 256KBytes = 65536 * 4 bytes (65536 words de 32bits)
	constant wordsPerBlock: positive := 32;
	constant blockSize: positive := wordsPerBlock * 4; --- 32 * 4 = 128Bytes
    constant numberOfBlocks: positive := memSize / blockSize; -- 2048 blocos
		
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
	
begin 
	
	blockAddr <= to_integer(unsigned(addr(17 downto 7)));
	index <= blockAddr mod numberOfBlocks;
	

	-- atualizacao do cache de acordo com os sinais de controle
	process(enable)				 
	begin
		if (enable'event) then
			
			-- Memory Read Cache L2
			if (enable = '1' and memRw = '0') then
				dataOut   <=  memory(index).data after accessTime;
				memReady  <=  '1' after accessTime;
			end if;
			
			-- Memory Write Cache L2
			if (enable = '1' and memRw = '1') then
				memory(index).data <= dataIn after accessTime;  
				memReady  <= '1' after accessTime;			
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

end architecture MemoryL3_arch;