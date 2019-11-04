-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Victim Buffer - UC

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto

use types.all;


entity VBControl is
    port (
		-- I/O relacionados ao stage IF
		clk				   : in  bit;
        queueInst		   : in  bit;
		queueData		   : in  bit;
		readyL2			   : in  bit;
		queueBlockData	   : out bit;
		queueBlockInst     : out bit;
		readyRead		   : out bit
    );
end entity VBControl;

architecture archi of VBControl is	 	  
							  
	-- Definicao de estados
    type states is (INIT, READY, QUEUE_DATA, QUEUE_INST, L2READY, QUEUEQUEUE_1, INST_L2READY, DATA_L2READY, QUEUEQUEUEREADY);
    signal state: states := INIT; 
	
	-- debug
    signal state_d: bit_vector(2 downto 0);
	
begin 								
	
	
		queueBlockData <= '1' when state = QUEUE_DATA or state = DATA_L2READY else '0';
		queueBlockInst <= '1' when state = QUEUE_INST or state = QUEUEQUEUE_1 or state = INST_L2READY or state = QUEUEQUEUEREADY else '0';
		readyRead      <= '1' when state = L2READY else '0';
	
	process (clk)									  
	begin 
		
		if rising_edge(clk) then
			case state is 
				
				--- estado inicial
				when INIT =>
					state <= READY;	
					
				--- estado Ready
				when READY =>
					if(queueInst'event and queueInst = '1' and queueData = '0' and readyL2 = '0') then
						state <= QUEUE_INST;
                    end if;					
					
					if(queueInst = '0' and queueData'event and queueData = '1' and readyL2 = '0') then
						state <= QUEUE_DATA;
					end if;					
					
					if(queueInst = '0' and queueData = '0' and readyL2'event and readyL2 = '1') then
						state <= L2READY;
					end if;				 
					
					if(queueInst'event and queueInst = '1' and queueData'event and queueData = '1' and readyL2 = '0') then
						state <= QUEUEQUEUE_1;
					end if;
					
					if(queueInst'event and queueInst = '1' and queueData = '0' and readyL2'event and readyL2 = '1') then
						state <= INST_L2READY;
					end if;					  
					
					if(queueInst = '0' and queueData'event and queueData = '1' and readyL2'event and readyL2 = '1') then
						state <= DATA_L2READY;
					end if;			 
					
					if(queueInst'event and queueInst = '1' and queueData'event and queueData = '1' and readyL2'event and readyL2 = '1') then
						state <= QUEUEQUEUEREADY;
					end if;						 
					
					if(queueInst = '0' and queueData = '0' and readyL2 = '0') then
						state <= READY;
					end if;										  
					
				when QUEUE_DATA =>
					state <= READY;
					
				when QUEUE_INST =>
					state <= READY;
				
				when L2READY =>
					state <= READY;
					
				when QUEUEQUEUE_1 =>   		--ativar leitura de bloco de instruções
					state <= QUEUE_DATA;
					
				when INST_L2READY =>  		--ativar queue de instrução
					state <= L2READY;
					
				when DATA_L2READY =>   		--ativar queue de data
					state <= L2READY;
					
				when QUEUEQUEUEREADY =>     --ativar queue de instrução
					state <= DATA_L2READY;
					
				when others =>
					state <= INIT;
			end case;
		end if;
	end process;
	
end archi;