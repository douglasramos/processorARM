-- PCS3412 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Cache de dados (Unidade de controle)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto
library arm;
use arm.types.all;


entity ControlCacheL2 is
    generic (
        accessTime: in time := 5 ns
    );
    port (			  
        
        -- I/O pipeline?
        clk            in  bit;

		-- I/O relacionado ao victim buffer
		vbDequeue      out bit;

		-- I/O relacionado ao cache de dados
		cdRW           in  bit;
		cdEnable       in  bit;
		cdL2Ready      out bit;

		-- I/O relacionado ao cache de instruções
		ciRW           in  bit;
		ciEnable       in  bit;
		ciL2Ready      out bit;

		-- I/O relacionados ao cache L2
		dirtyBit:      in  bit;
		hitSignal:     in  bit;
		writeOptions:  out bit_vector(1 downto 0) := "00";
		updateInfo:    out bit := '0';
		switchAddr     out bit := '0';
		
        -- I/O relacionados a Memoria princial
		memReady:      in  bit;
		memRW:         out bit := '0';  --- '1' write e '0' read
        memEnable:     out bit := '0'
        
    );
end entity ControlCacheL2;

architecture ControlCacheL2_arch of ControlCacheL2 is	 	  
							  
	-- Definicao de estados
    type states is (INIT, READY, CTAG, WRITE, MWRITE, CTAG2, HIT, MISS, MREADY);
    signal state: states := INIT; 

    -- Sinais internos
    signal enable: bit;
    
begin 

    -- enable geral
    enable <= ciEnable or cdEnable;
    -- Write signal geral

    process (clk, enable, cdAddr, ciAddr)									  
	begin
		if rising_edge(clk) or cdAddr'event or ciAddr'event then
			case state is 
				
				--- estado inicial
				when INIT =>
					state <= READY;	
					
				--- estado Ready
				when READY =>
                    if enable'event then
                        state <= CTAG;
                    end if;
					
				--- estado Compare Tag
                when CTAG =>
                    if cdRw = '1' then
                        if dirtyBit = '1' then
							state <= MWRITE;	-- precisa colocar dado atual na Memoria primeiro
						elsif dirtyBit = '0' then
						 	state <= WRITE; -- pode ja escrever no cache
						end if;
                    elsif cdRW = '0' or ciRW = '0' then	  -- Leitura
						if hitSignal = '1' then 
					   		state <= HIT;

						else -- Miss
							state <= MISS;								
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
	         
	-- writeOptions
	writeOptions <= "01" when state = MREADY   else
        	         "10" when state = WRITE else 
		             "00";
	         		 
	-- updateInfo
	updateInfo <= '1' when state = MREADY else '0';
	         	   				  
    -- memory		
	memEnable <= '1' when state = MISS   else '0';
	memRW     <= '1' when state = MWRITE else '0';
	

end architecture ControlCacheL2_arch;