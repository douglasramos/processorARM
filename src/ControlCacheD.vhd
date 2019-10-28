-- PCS3412 - Organizacao e Arquitetura de Computadores I
-- PicoMIPS
-- Author: Douglas Ramos
-- Co-Authors: Pedro Brito, Rafael Higa
--
-- Description:
--     Controle do Cache de Dados

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto
library arm;
use arm.types.all;


entity ControlCacheD is
    generic (
        accessTime: in time := 5 ns
    );
    port (			  
			
		-- I/O relacionados ao stage MEM
		clk:            in bit;
		clk_pipeline:   in  bit;
        cpu_write:      in  bit;
		cpu_addr:       in  bit_vector(15 downto 0);
		stall:          out bit := '0';
		
		-- I/O relacionados ao cache
		dirtyBit:      in  bit;
		hitSignal:     in  bit;
		writeOptions:  out bit_vector(1 downto 0) := "00";
		updateInfo:    out bit := '0';
		
        -- I/O relacionados a Memoria princial
		memReady:      in  bit;
		memRW:         out bit := '0';  --- '1' write e '0' read
        memEnable:     out bit := '0'
        
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
						if hitSignal = '1' then 
					   		state <= HIT;

						else -- Miss
							state <= MISS;								
                		end if;

					elsif cpu_write = '1' and clk_pipeline = '1' then -- Escrita no primeiro ciclo
						if dirtyBit = '1' then
							state <= MWRITE;	-- precisa colocar dado atual na Memoria primeiro
						elsif dirtyBit = '0' then
						 	state <= WRITE; -- pode ja escrever no cache
						end if;
                	end if;
				
				--- estado Write
				when WRITE =>
				   state <= READY;
				
				--- estado Memory Write
				when MWRITE =>
					if memReady = '1' then
						state <= READY;
					elsif memReady = '0' then
						state <= MWRITE;
					end if;
				
						
				--- estado Compare Tag2 
				--- (segunda comparacao apos MISS)
				when CTAG2 =>
					if hitSignal = '1' then 
					   state <= HIT;

					else -- Miss
						state <= MISS;
													
                    end if;	
					
				--- estado Hit
				when HIT =>
					state <= READY;
					
				--- estado Miss
				when MISS =>
					if memReady = '1' then
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
	         
	-- writeOptions
	writeOptions <= "01" when state = MREADY   else
        	         "10" when state = WRITE else 
		             "00";
	         		 
	-- updateInfo
	updateInfo <= '1' when state = MREADY else '0';
	         	   				  
    -- memory		
	memEnable <= '1' when state = MISS   else '0';
	memRW     <= '1' when state = MWRITE else '0';
	

end architecture ControlCacheD_arch;