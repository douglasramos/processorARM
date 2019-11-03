-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Victim Buffer (Unidade de controle)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto

use types.all;


entity ControlVB is
    generic (
        accessTime: in time := 5 ns
    );
    port (
		clk							 : in  bit;	
		VBDataAccess				 : in  bit;
		VBInstAccess				 : in  bit;
		isEvictedL1_Data			 : in  bit;		
		isEvictedL1_Inst			 : in  bit;		
		--isDequeueAddr_Data			 : in  bit;
		--isDequeueAddr_Inst			 : in  bit;
		L2Dequeue					 : in  bit;	
		isClear						 : in  bit;
		dequeue_initial_address 	 : out bit;
		dequeue_given_address_data   : out bit;
		dequeue_given_address_inst	 : out bit;
		queueBlockData			     : out bit;
		queueBlockInst				 : out bit;
		clearBuffer			    	 : out bit
    );
end entity ControlVB;

architecture archi of ControlVB is	 	  
							  
	-- Definicao de estados
    type states is (INIT, READY, QUEUE_I, QUEUE_D, QUEUE_ID1, QUEUE_ID2, DEQUEUE_ID, DEQUEUE_INIT, DEQUEUE_ADDR_DATA, DEQUEUE_ADDR_INST, CLR);
    signal state: states := INIT; 
	
	-- debug
    signal state_d: bit_vector(2 downto 0);		
	signal trigger : bit;
begin 					
	
	trigger <= VBDataAccess or VBInstAccess;
	process (clk)									  
	
	
	begin
		if rising_edge(clk) then
			case state is 
	
				--- estado inicial
				when INIT =>
					state <= READY;	
					
				--- estado Ready
				when READY =>
					if(isEvictedL1_Data = '1' and isEvictedL1_Inst = '0' and VBDataAccess = '1' and VBInstAccess = '0') then 
						state <= QUEUE_D;
					end if;
					
					if(isEvictedL1_Inst = '1' and isEvictedL1_Data = '0' and VBDataAccess = '0' and VBInstAccess = '1') then
						state <= QUEUE_I;
					end if;
					
					if(isEvictedL1_Data = '1' and isEvictedL1_Inst = '1' and VBDataAccess = '1' and VBInstAccess = '1') then 
						state <= QUEUE_ID1;
					end if;							
					
					if(L2Dequeue = '1' and isEvictedL1_Data = '0' and isEvictedL1_Inst = '0' and VBDataAccess = '0' and VBInstAccess = '0' and L2Dequeue = '1') then
						state <= DEQUEUE_INIT;
					end if;
					
					if(isClear = '1') then
						state <= CLR;
					end if;
					
					if(isEvictedL1_Data = '0' and isEvictedL1_Inst = '0' and VBDataAccess = '1' and VBInstAccess = '0') then
						state <= DEQUEUE_ADDR_DATA;
					end if;
					
					if(isEvictedL1_Data = '0' and isEvictedL1_Inst = '0' and VBDataAccess = '0' and VBInstAccess = '1') then
						state <= DEQUEUE_ADDR_INST;
					end if;
					
					if(isEvictedL1_Data = '0' and isEvictedL1_Inst = '0' and VBDataAccess = '1' and VBInstAccess = '1') then
						state <= DEQUEUE_ID;
					end if;
					if(L2Dequeue = '0' and isEvictedL1_Data = '0' and isEvictedL1_Inst = '0' and isClear = '0') then
						state <= READY;
					end if;		
					
					
						   
				when QUEUE_I =>
					--if(isDequeueAddr_Inst = '1') then
						state <= DEQUEUE_ADDR_INST;
					--end if;
					
					--if(isDequeueAddr_Inst = '0' and L2Dequeue = '1') then 
					--	state <= DEQUEUE_INIT;
					--end if;					  
					
					--if(isDequeueAddr_Inst = '0' and L2Dequeue = '0') then
					--	state <= READY;
					--end if;
					
				when QUEUE_D =>
					--if(isDequeueAddr_Data = '1') then
						state <= DEQUEUE_ADDR_DATA;				  
					--end if;
					
					--if(isDequeueAddr_Data = '0' and L2Dequeue = '1') then 
					--	state <= DEQUEUE_INIT;
					--end if;					  
					
					--if(isDequeueAddr_Data = '0' and L2Dequeue = '0') then
					--	state <= READY;
					--end if;
					
				when QUEUE_ID1 =>
					state <= QUEUE_ID2;
					
				when QUEUE_ID2 =>
					--if(isDequeueAddr_Inst = '1') then
						state <= DEQUEUE_ID;
					--end if;
					
					--if(isDequeueAddr_Inst = '0' and isDequeueAddr_Data = '1') then 
					--	state <= DEQUEUE_ADDR_DATA;
					--end if;
					
					--if(isDequeueAddr_Inst = '0' and isDequeueAddr_Data = '0' and L2Dequeue = '1') then
					--	state <= DEQUEUE_INIT;
					--end if;
					
					--if(isDequeueAddr_Inst = '0' and isDequeueAddr_Data = '0' and L2Dequeue = '0') then
					--	state <= READY;
					--end if;
					
				when DEQUEUE_ID =>
					--if(isDequeueAddr_Data = '1') then
						state <= DEQUEUE_ADDR_DATA;
					--end if;
					
					--if(isDequeueAddr_Data = '0' and L2Dequeue = '1') then 
					--	state <= DEQUEUE_INIT;
					--end if;
					
					--if(isDequeueAddr_Data = '0' and L2Dequeue = '0') then
					--	state <= READY;
					--end if;
					
				when DEQUEUE_INIT =>			  
					state <= READY;
					
				when DEQUEUE_ADDR_DATA =>
					if(L2Dequeue = '1') then
						state <= DEQUEUE_INIT;
					else
						state <= READY;
					end if;
				
				
				when DEQUEUE_ADDR_INST =>
					if(L2Dequeue = '1') then
						state <= DEQUEUE_INIT;
					else
						state <= READY;
					end if;
				
				when CLR =>		   
					state <= CLR;
				
				when others=>
					state <= INIT;
			end case;
		end if;
	end process;
	
	--- saidas ---
	
	dequeue_initial_address    <= '1' when state = DEQUEUE_INIT      else '0';
	dequeue_given_address_data <= '1' when state = DEQUEUE_ADDR_DATA else '0';
	dequeue_given_address_inst <= '1' when state = DEQUEUE_ADDR_INST or state = DEQUEUE_ID else '0';
	queueBlockData 			   <= '1' when state = QUEUE_D           else '0';
	queueBlockInst			   <= '1' when state = QUEUE_I           else '0';
	clearBuffer				   <= '1' when state = CLR			     else '0';
		
		

end architecture archi;