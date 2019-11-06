-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Cache de instruções (Unidade de controle)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto

use types.all;


entity ControlCacheI is
    generic (
        accessTime: in time := 5 ns
    );
    port (
		-- I/O relacionados ao stage IF
		clk				   : in  bit;
        stall			   : out bit := '0';
		pc				   : in  bit_vector(63 downto 0);
		-- I/O relacionados ao cache
		hitSignal		   : in  bit;
		writeOptions	   : out bit := '0';
		updateInfo	   	   : out bit := '0';
        -- I/O relacionados ao L2
		L2Ready			   : in  bit;
		L2RW			   : out bit := '0';  --- '1' write e '0' read
        L2Enable		   : out bit := '0';
		-- I/O relacionados ao victim buffer
		isFull			   : in  bit;
		dequeue_given_address_inst : in bit;	   
		VBInstAccess	   : out bit
		
    );
end entity ControlCacheI;

architecture ControlCacheIArch of ControlCacheI is	 	  
							  
	-- Definicao de estados
    type states is (INIT, READY, CTAG, CTAG2, HIT, MISS, MEM);
    signal state: states := INIT; 
	
	-- debug
    signal state_d: bit_vector(2 downto 0);
	
begin 
	process (clk, pc)									  
	
	
	begin
		if rising_edge(clk) or pc'event then
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
					if hitSignal = '1' then 
					   state <= HIT;

					else -- Miss
						state <= MISS;
													
                    end if;
					
				--- estado Compare Tag2 
				--- (segunda comparacao apos MISS)
				when CTAG2 =>
					if hitSignal = '1' or dequeue_given_address_inst = '1' then    --dequeue_given_address_inst seria redundante aqui???
					   state <= HIT;

					else -- Miss
						state <= MISS;
													
                    end if;	
					
				--- estado Hit
				when HIT =>
					state <= READY;
					
				--- estado Miss
				when MISS =>
					if L2Ready = '1' or isFull = '0' then
						state <= MEM;
                    else
						state <= MISS;
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
	
	-- memRW
	L2RW <= '0'; -- sempre leitra
	
	-- stall -- trava pipeline
	stall <= '1' after accessTime when state = MISS  or 
										state = MEM   or 
										state = CTAG2 else '0';  
	         
	-- compare_tag
	writeOptions <= '1' when state = MEM else '0';
	         		 
	-- updateInfo
	updateInfo <= '1' when state = MEM else '0';
	         	   				  
    -- memEnable		
	L2Enable <= '1' when state = MISS else '0';
	
	VBInstAccess <= '1' when state = MEM else '0';     --só aqui mesmo ou tem mais???

end architecture ControlCacheIArch;