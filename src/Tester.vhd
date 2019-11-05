-- PCS3422 - Organização e Arquitetura de Computadores II
-- ARM		 
--
-- Description:
--     Testador para a hierarquia de memória. Propõe endereços para fetch e responde a stalls
								     						  --Modos de funcionamento: saltos uniformes (4 em 4 endereços)
															  --						saltos aleatórios
library ieee;												  --                        possibilidade de executar branch nos dois casos
use ieee.numeric_bit.all; 										
use ieee.math_real.all;										  -- OBS: para alterar a sequencia de valores aleatorios gerados, é necessário
															  -- mudar o valor das variáveis "seed" (linhas 56 - 59)

-- importa os types do projeto

use types.all; -- 1 word, 32 bits							 

entity tester is											 
	generic (
		addrSize   : natural := 10;
		rangeBits  : natural := 4;                           -- Quantidade de bits de range no gerador aleatório de saltos
		rand1_data : natural := 1;
		rand2_data : natural := 2;
		rand1_inst : natural := 21;
		rand2_inst : natural := 22
	);
    port (	
		clk          	  : in  bit;						 -- Mesmo ciclo de clock que os caches L1
		addressMode  	  : in  bit;                         -- Mode '0' = instruções consecutivas a partir de startAddress; '1' = instruções randomicas
		cacheMode	 	  : in  bit_vector(1 downto 0);      -- Mode "01" = só cache de instruções; "10" = só cache de dados; "11" = os dois caches
		startAddressData  : in  bit_vector(addrSize-1 downto 0);	
		startAddressInst  : in  bit_vector(addrSize-1 downto 0);	
   		stallData	 	  : in  bit;						
		stallInst    	  : in  bit; 
		isBranchData	  : in  bit;
		isBranchInst	  : in  bit;
		branchDataOffset  : in  bit_vector(addrSize-1 downto 0);
		branchInstOffset  : in  bit_vector(addrSize-1 downto 0);
		toTestAddressData : out bit_vector(addrSize-1 downto 0);
		toTestAddressInst : out bit_vector(addrSize-1 downto 0)
    );																	 	
end tester;
		
		
architecture archi of tester is	 	  

signal addressDataToMemory, addressInstToMemory : bit_vector(addrSize-1 downto 0);

signal randomVectorData : bit_vector(addrSize-1 downto 0);
signal randomVectorInst : bit_vector(addrSize-1 downto 0);

begin
	toTestAddressData <= addressDataToMemory;
	toTestAddressInst <= addressInstToMemory;
	
process(clk, stallData, stallInst)
		variable start 			  : natural := 0;	 
		variable addressDataSum   : unsigned(addrSize-1 downto 0); 
		variable addressInstSum   : unsigned(addrSize-1 downto 0); 
		variable temp 			  : unsigned(addrSize-1 downto 0) := "0000000100"; 
		variable seed1Data 	      : positive := rand1_data;
		variable seed2Data 	      : positive:= rand2_data;
		variable seed1Inst 	      : positive := rand1_inst;
		variable seed2Inst 	      : positive:= rand2_inst;
		variable re1Data, re1Inst : integer;
		variable re2Data, re2Inst : real;
		
		begin
			if(clk'event and clk = '1') then
				if(start = 0) then
					addressDataToMemory <= startAddressData;
					addressInstToMemory <= startAddressInst;
					start := 1;
				
				else
					if(stallData = '0') then
						if(cacheMode(0) = '1') then															   --Geração de ends. para cache de dados ativa!
							if(addressMode = '0' and (not isBranchData'event) and isBranchData = '0') then	   --Endereços consecutivos
								addressDataSum := unsigned(addressDataToMemory) + unsigned(temp);	           --end. += 4
						
							elsif(addressMode = '1' and (not isBranchData'event) and isBranchData = '0') then  --Endereços randomicos
								uniform(seed1Data, seed2Data, re2Data);
								re1Data := integer(re2Data * real(2**rangeBits-1));
								randomVectorData <= bit_vector(to_unsigned(re1Data, addrSize));
								addressDataSum := unsigned(addressDataToMemory) + unsigned(randomVectorData); 
								
							elsif(isBranchData'event and isBranchData = '1') then							   --Endereços 
								addressDataSum := unsigned(addressDataToMemory) + unsigned(branchDataOffset); 
						
							end if;
						end if;
					end if;
					addressDataToMemory <= bit_vector(addressDataSum);
					
					
					if(stallInst = '0') then
						if(cacheMode(1) = '1') then		--Geração de ends. para cache de inst ativa!
							if(addressMode = '0' and (not isBranchInst'event) and isBranchInst = '0') then
								addressInstSum := unsigned(addressInstToMemory) + unsigned(temp);	         --end. += 4
						
							elsif(addressMode = '1' and (not isBranchInst'event) and isBranchInst = '0') then
								uniform(seed1Inst, seed2Inst, re2Inst);
								re1Inst := integer(re2Inst * real(2**rangeBits-1));
								randomVectorInst <= bit_vector(to_unsigned(re1Inst, addrSize));
								addressInstSum := unsigned(addressInstToMemory) + unsigned(randomVectorInst); 
								
							elsif(isBranchInst'event and isBranchInst = '1') then
								addressInstSum := unsigned(addressInstToMemory) + unsigned(branchInstOffset); 
						
							end if;
						end if;
					end if;
					addressInstToMemory <= bit_vector(addressInstSum);			
				end if;
			end if;
	end process;
							  
			
			   
		
end archi;