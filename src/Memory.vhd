-- PCS3412 - Organizacao e Arquitetura de Computadores I
-- PicoMIPS
-- Author: Douglas Ramos
-- Co-Authors: Pedro Brito, Rafael Higa
--
-- Description:
--     Memoria Principal

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.numeric_bit.all;

-- importa os types do projeto
library pipeline;
use pipeline.types.all;


entity Memory is
    generic (
        access_time: in time := 40 ns
    );
    port (
		
		-- I/O relacionados cache de Instrucoes
		ci_enable:     in   bit := '0';
		ci_mem_rw:     in   bit; --- '1' write e '0' read
		ci_addr:       in   bit_vector(15 downto 0);
		ci_data_block: out  word_vector_type(15 downto 0) := (others => word_vector_init);
		ci_mem_ready:  out  bit := '0'; 
		
		
		-- I/O relacionados cache de dados
		cd_clock:     in  bit;
		cd_enable:    in  bit;
		cd_mem_rw:    in  bit; --- '1' write e '0' read
		cd_addr:      in  bit_vector(15 downto 0);
		cd_data_in:   in  word_vector_type(15 downto 0);
		cd_data_out:  out word_vector_type(15 downto 0) := (others => word_vector_init);
		cd_mem_ready: out bit := '0' 
		
        
    );
end entity Memory;

architecture Memory_arch of Memory is	 	  
							  
	constant mem_size: positive := 2**16; -- 64KBytes = 16384 * 4 bytes (16384 words de 32bits)
	constant words_per_block: positive := 16;
	constant block_size: positive := words_per_block * 4; --- 16 * 4 = 64Bytes
    constant number_of_blocks: positive := mem_size / block_size; -- 1024 blocos
		
	--- Cada "linha" na memoria possui data, que corresponde a um bloco de dados
	type mem_row_type is record
        data:  word_vector_type(words_per_block - 1 downto 0);
    end record mem_row_type;

	type mem_type is array (number_of_blocks - 1 downto 0) of mem_row_type;
	
	--- funcoes de acesso a arquivo

	impure function readFile(file_name : in string) return mem_type is
		file     file_  : text open read_mode is file_name;
		variable line_    : line;
		variable temp_word  : bit_vector(31 downto 0);
		variable temp_mem : mem_type;
		begin
			for bloc in 0 to number_of_blocks - 1 loop
				for offset in 0 to words_per_block - 1 loop
					readline(file_, line_);
					read(line_, temp_word);
					temp_mem(bloc).data(offset) := temp_word;
				end loop;
		  end loop;
		  return temp_mem;
		end;
	
	--- inicializa memoria
	signal memory : mem_type := readFile("memory.dat")

	--- Demais sinais internos
	signal ci_block_addr: natural;
	signal ci_index: natural;
	signal cd_block_addr: natural;
	signal cd_index: natural;
	signal enable: bit;
	
	
begin 
	
	-- obtem index a partir do endere�o de entrada
	ci_block_addr <= to_integer(unsigned(ci_addr(15 downto 6)));
	ci_index <= ci_block_addr mod number_of_blocks;	
	
	cd_block_addr <= to_integer(unsigned(cd_addr(15 downto 6)));
	cd_index <= cd_block_addr mod number_of_blocks;
	
	-- enable geral
	enable <= ci_enable or cd_enable;
	
	
	-- atualizacao do cache de acordo com os sinais de controle
	process(enable)
	begin
		if (enable'event) then
			
			-- Memory Read Cache Instrucoes
			if (ci_enable = '1' and ci_mem_rw = '0') then
				ci_data_block <=  memory(ci_index).data after access_time;
				ci_mem_ready  <=  '1' after access_time;
			end if;
			
			-- Memory Read Cache Dados
			if (cd_enable = '1' and ci_mem_rw = '0') then
				cd_data_out   <=  memory(ci_index).data after access_time;
				cd_mem_ready  <=  '1' after access_time;
			end if;
			
			-- Memory Write Cache Dados
			if (cd_enable = '1' and ci_mem_rw = '1') then
				memory(ci_index).data <= cd_data_in after access_time;  
				ci_mem_ready  <=  '1' after access_time;
			end if;
			
		end if;
	end process;

end architecture Memory_arch;