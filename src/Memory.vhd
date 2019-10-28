-- PCS3412 - Organizacao e Arquitetura de Computadores II
-- PicoMIPS
--
-- Description:
--     Memoria Principal (RAM)

library ieee;
use ieee.numeric_bit.all;
use std.textio.all;

-- importa os types do projeto
library arm;
use arm.types.all;


entity Memory is
    generic (
        accessTime: in time := 40 ns
    );
    port (
		
		-- I/O relacionados cache de Instrucoes
		ciEnable:     in   bit := '0';
		ciMemRw:     in   bit; --- '1' write e '0' read
		ciAddr:       in   bit_vector(15 downto 0);
		ciDataBlock: out  word_vector_type(15 downto 0) := (others => word_vector_init);
		ciMemReady:  out  bit := '0'; 
		
		
		-- I/O relacionados cache de dados
		cdEnable:    in  bit;
		cdMemRw:    in  bit; --- '1' write e '0' read
		cdAddr:      in  bit_vector(15 downto 0);
		cdDataIn:   in  word_vector_type(15 downto 0);
		cdDataOut:  out word_vector_type(15 downto 0) := (others => word_vector_init);
		cdMemReady: out bit := '0' 
		
        
    );
end entity Memory;

architecture Memory_arch of Memory is	 	  
							  
	constant memSize: positive := 2**16; -- 64KBytes = 16384 * 4 bytes (16384 words de 32bits)
	constant wordsPerBlock: positive := 16;
	constant blockSize: positive := wordsPerBlock * 4; --- 16 * 4 = 64Bytes
    constant numberOfBlocks: positive := memSize / blockSize; -- 1024 blocos
		
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
	ciBlockAddr <= to_integer(unsigned(ciAddr(15 downto 6)));
	ciIndex <= ciBlockAddr mod numberOfBlocks;	
	
	cdBlockAddr <= to_integer(unsigned(cdAddr(15 downto 6)));
	cdIndex <= cdBlockAddr mod numberOfBlocks;
	
	-- enable geral
	enable <= ciEnable or cdEnable;

	-- atualizacao do cache de acordo com os sinais de controle
	process(enable)				 
	begin
		if (enable'event) then
			
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

end architecture Memory_arch;