-- PCS3412 - Organizacao e Arquitetura de Computadores I
-- PicoMIPS
-- Author: Douglas Ramos
-- Co-Authors: Pedro Brito, Rafael Higa
--
-- Description:
--     Controle do Cache de Dados

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all; 

-- importa os types do projeto
library pipeline;
use pipeline.types.all;


entity ControlCacheD is
    generic (
        access_time: in time := 5 ns
    );
    port (			  
			
		-- I/O relacionados ao stage MEM
		clk:            in std_logic;
		clk_pipeline:   in  std_logic;
        cpu_write:      in  std_logic;
		cpu_addr:       in  std_logic_vector(15 downto 0);
		stall:          out std_logic := '0';
		
		-- I/O relacionados ao cache
		dirty_bit:      in  std_logic;
		hit_signal:     in  std_logic;
		write_options:  out std_logic_vector(1 downto 0) := "00";
		update_info:    out std_logic := '0';
		
        -- I/O relacionados a Memoria princial
		mem_ready:      in  std_logic;
		mem_rw:         out std_logic := '0';  --- '1' write e '0' read
        mem_enable:     out std_logic := '0'
        
    );
end entity ControlCacheD;

architecture ControlCacheD_arch of ControlCacheD is	 	  
							  
	-- Definicao de estados
    type states is (INIT, READY, CTAG, WRITE, MWRITE, CTAG2, HIT, MISS, MREADY);
    signal state: states := INIT; 
	
begin 
	process (clk, clk_pipeline, cpu_addr)									  
	begin
		if rising_edge(clk) or cpu_addr'event then -- talvez precise do rising_edge do clk pipeline
			case state is 
				
				--- estado inicial
				when INIT =>
					state <= READY;	
					
				--- estado Ready
				when READY =>
                    if cpu_addr'event then
                        state <= CTAG;
                    end if;
					
				--- estado Compare Tag
				when CTAG =>
					if cpu_write = '0' then	  -- Leitura
						if hit_signal = '1' then 
					   		state <= HIT;

						else -- Miss
							state <= MISS;								
                		end if;

					elsif cpu_write = '1' and clk_pipeline = '1' then -- Escrita no primeiro ciclo
						if dirty_bit = '1' then
							state <= MWRITE;	-- precisa colocar dado atual na Memoria primeiro
						elsif dirty_bit = '0' then
						 	state <= WRITE; -- pode ja escrever no cache
						end if;
                	end if;
				
				--- estado Write
				when WRITE =>
				   state <= READY;
				
				--- estado Memory Write
				when MWRITE =>
					if mem_ready = '1' then
						state <= READY;
					elsif mem_ready = '0' then
						state <= MWRITE;
					end if;
				
						
				--- estado Compare Tag2 
				--- (segunda comparacao apos MISS)
				when CTAG2 =>
					if hit_signal = '1' then 
					   state <= HIT;

					else -- Miss
						state <= MISS;
													
                    end if;	
					
				--- estado Hit
				when HIT =>
					state <= READY;
					
				--- estado Miss
				when MISS =>
					if mem_ready = '1' then
						state <= MREADY;
                    end if;
					
				--- estado Memory Ready
				when MREADY =>
					state <= CTAG2;			
					
				when others =>
					state <= INIT;
			end case;
		end if;
	end process;
	
	--- saidas ---
	
	-- stall -- trava pipeline
	stall <= '1' when state = MISS   or 
					  state = MREADY or
					  state = CTAG2  or
					  state = MWRITE else '0';  
	         
	-- write_options
	write_options <= "01" when state = MREADY   else
        	         "10" when state = WRITE else 
		             "00";
	         		 
	-- update_info
	update_info <= '1' when state = MREADY else '0';
	         	   				  
    -- memory		
	mem_enable <= '1' when state = MISS   else '0';
	mem_rw     <= '1' when state = MWRITE else '0';
	

end architecture ControlCacheD_arch;