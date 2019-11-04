-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Write Buffer (Unidade de controle)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto

use types.all;


entity WBControl is
    port (
		-- I/O relacionados ao stage IF
		clk				   : in  bit;
        queue			   : in  bit;
		read			   : in  bit;
		queueControl	   : out bit;
		readReady		   : out bit
    );
end entity WBControl;

architecture archi of WBControl is	 	  
							  
	-- Definicao de estados
    type states is (INIT, READY, QUEUE_STATE, READ_STATE, QREAD);
    signal state: states := INIT; 
	
	-- debug
    signal state_d: bit_vector(2 downto 0);
	
begin 								
	
	
	queueControl <= '1' when state = QUEUE_STATE or state = QREAD else '0';
	readReady <= '1' when state = READ_STATE else '0';
	
	process (clk)									  
	begin 
		
		if rising_edge(clk) then
			case state is 
				
				--- estado inicial
				when INIT =>
					state <= READY;	
					
				when READY =>
					if(queue = '1' and read = '0') then
						state <= QUEUE_STATE;
					end if;
						
					if(queue = '0' and read = '1') then 
						state <= READ_STATE;
					end if;
					
					if(queue = '1' and read = '1') then
						state <= QREAD;
					end if;						 
					
					if(queue = '0' and read = '0') then
						state <= READY;
					end if;
					
				when QUEUE_STATE =>
					state <= READY;
				
				when READ_STATE =>
					state <= READY;
				
				when QREAD =>	   
					state <= READ_STATE;
				
				when others =>
					state <= INIT;
			end case;
		end if;
		
	end process;
		
end archi;