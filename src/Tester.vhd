-- PCS3422 - Organização e Arquitetura de Computadores II
-- ARM		 
--
-- Description:
--     Testador para a hierarquia de memória. Propõe endereços para fetch e responde a stalls
								     
	
library ieee;
use ieee.numeric_bit.all; 


-- importa os types do projeto

use types.all; -- 1 word, 32 bits							 

entity tester is
    port (	
		clk          	  : in  bit;						 -- Mesmo ciclo de clock que os caches L1
		addressMode  	  : in  bit_vector(1 downto 0);   -- Mode "00" = instruções consecutivas a partir de startAddress; "01" = instruções randomicas; "10" = alguns branches aleatórios
		cacheMode	 	  : in  bit_vector(1 downto 0);   -- Mode "01" = só cache de instruções; "10" = só cache de dados; "11" = os dois caches
		startAddressData  : in  bit_vector(10 downto 0);	
		startAddressInst  : in  bit_vector(10 downto 0);	
   		stallData	 	  : in  bit;						
		stallInst    	  : in  bit;
		branchDataOffset  : in  bit_vector(10 downto 0);
		branchInstOffset  : in  bit_vector(10 downto 0);
		toTestAddressData : out bit_vector(10 downto 0);
		toTestAddressInst : out bit_vector(10 downto 0)
    );																	 	
end tester;
		
		
architecture archi of tester is	 	  

signal addressDataToMemory, addressInstToMemory : bit_vector(10 downto 0);

begin
	toTestAddressData <= addressDataToMemory;
	toTestAddressInst <= addressInstToMemory;
	process(clk, stallData, stallInst)
		variable start : natural := 0;	 
		variable addressDataSum : unsigned(10 downto 0); 
		variable addressInstSum : unsigned(10 downto 0); 
		variable temp : unsigned(10 downto 0) := "00000000100";
	
		begin		
		if(start = 0) then
			addressDataToMemory <= startAddressData;
			addressInstToMemory <= startAddressInst;
			start := 1;
		else
			----------------------------------------------------------------------------------
			--if endereços consecutivos
			if(stallData = '0' and cacheMode(0) = '1') then					 
				if(addressMode = "00") then
					addressDataSum := unsigned(addressDataToMemory) + unsigned(temp);
				end if;
				
			end if;
				addressDataToMemory <= bit_vector(addressDataSum);
			if(stallInst = '0' and cacheMode(1) = '1') then					 
				if(addressMode = "00") then
					addressInstSum := unsigned(addressInstToMemory) + unsigned(temp);
				end if;
				
			end if;
				addressInstToMemory <= bit_vector(addressInstSum);							  
			----------------------------------------------------------------------------------
			--if branches ideia: inserir "na mão" via simulação. Aí no próximo ciclo de clock vai dar um salto de tantos endereços pedidos!
			
			--	if(branchdataOffset'event) then
					
			--	end if;					   
				
			--	if(branchInstOffset'event) then
			--		
		--		end if;
		
				--esboço de logica:
				--if(isBranch = '1') then
				--	addressInstToMemory += jumpOffset
				--	...
			----------------------------------------------------------------------------------
			--if random             fico de pesquisar como faz pra usar random() em vhdl!
				
				
		end if;
		
		
	end process;
	
			   
		
end archi;