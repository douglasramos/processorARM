-- PCS3412 - Organizacao e Arquitetura de Computadores I
-- PicoMIPS
-- Author: Douglas Ramos
-- Co-Authors: Pedro Brito, Rafael Higa
--
-- Description:
--     Controle do Cache de Instrucoes

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all; 

-- importa os types do projeto
library pipeline;
use pipeline.types.all;


entity ControlCacheI is
    generic (
        access_time: in time := 5 ns
    );
    port (
			
		-- I/O relacionados ao stage IF
		clk:    in std_logic;
        stall:  out std_logic := '0';
		pc:     in word_type;
		
		-- I/O relacionados ao cache
		hit_signal:      in  std_logic;
		write_options:   out std_logic := '0';
		update_info:     out std_logic := '0';
		
        -- I/O relacionados a Memória princial
		mem_ready:      in  std_logic;
		mem_rw:         out std_logic := '0';  --- '1' write e '0' read
        mem_enable:     out std_logic := '0'
        
    );
end entity ControlCacheI;

architecture ControlCacheI_arch of ControlCacheI is	 	  
							  
	-- Definicao de estados
    type states is (INIT, READY, CTAG, CTAG2, HIT, MISS, MEM);
    signal state: states := INIT; 
	
	-- debug
    signal state_d: std_logic_vector(2 downto 0);
	
begin 
	process (clk, pc)									  
	
	
	begin
		if rising_edge(clk) then
			case state is 
				
				--- estado inicial
				when INIT =>
					state <= READY;	
					
				--- estado Ready
				when READY =>
                    if pc'event then
                        state <= CTAG;
                    end if;
					
				--- estado Compare Tag
				when CTAG =>
					if hit_signal = '1' then 
					   state <= HIT;

					else -- Miss
						state <= MISS;
													
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
						state <= MEM;
                    end if;
					
				--- estado Memory Ready
				when MEM =>
					state <= CTAG2;			
					
				when others =>
					state <= INIT;
			end case;
		end if;
	end process;
	
	--- saidas ---
	
	-- mem_rw
	mem_rw <= '0'; -- sempre leitra
	
	-- stall -- trava pipeline
	stall <= '1' after access_time when state = MISS  or 
										state = MEM   or 
										state = CTAG2 else '0';  
	         
	-- compare_tag
	write_options <= '1' when state = MEM else '0';
	         		 
	-- update_info
	update_info <= '1' when state = MEM else '0';
	         	   				  
    -- mem_enable		
	mem_enable <= '1' when state = MISS else '0';
		          

end architecture ControlCacheI_arch;