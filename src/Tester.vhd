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
		addrSize        : natural := 10; 
		dataBlockAmount : natural := 100000;
		instBlockAmount : natural := 100000;
		rangeBits       : natural := 4;    --Basta colocar qualquer natural dessa linha para baixo! Variáveis para geração de 
		rand1_data      : natural := 1;						--números aleatórios!
		rand2_data      : natural := 2;
		rand1_inst      : natural := 21;
		rand2_inst      : natural := 22;
		plusMinusData1  : natural := 50;
		plusMinusData2  : natural := 51;
		plusMinusInst1  : natural := 100;
		plusMinusInst2  : natural := 100
	);
    port (	
		clk          	  : in  bit;						 -- Mesmo ciclo de clock que os caches L1
		restartAddr		  : in  bit;       
		addressMode  	  : in  bit_vector(1 downto 0);      -- Mode "00" = instruções consecutivas a partir de startAddress; "01" = instruções com offset randomico; "10" = instruções totalmente randomicas
		cacheMode	 	  : in  bit_vector(1 downto 0);      -- Mode "10" = só cache de instruções; "01" = só cache de dados; "11" = os dois caches
		startAddressData  : in  bit_vector(addrSize-1 downto 0);	
		startAddressInst  : in  bit_vector(addrSize-1 downto 0);			  
		endAddressData	  : in  bit_vector(addrSize-1 downto 0);	
		endAddressInst	  : in  bit_vector(addrSize-1 downto 0);
		setAddressEnable  : in  bit;
		setAddressData    : in  bit_vector(addrSize-1 downto 0);
		setAddressInst    : in  bit_vector(addrSize-1 downto 0);
   		stallData	 	  : in  bit;						
		stallInst    	  : in  bit; 
		isBranchData	  : in  bit;
		branchUpDownData  : in  bit;
		isBranchInst	  : in  bit;
		branchUpDownInst  : in  bit;
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
	
process(stallData)
		variable stallDataCounter : integer := 0;
begin			 
	if(stallData'event and stallData = '1') then
		stallDataCounter := stallDataCounter + 1;		
	end if;
		
end process;

process(stallInst)
		variable stallInstCounter : integer := 0;
begin			 
	if(stallInst'event and stallInst = '1') then	
		stallInstCounter := stallInstCounter + 1;
	end if;
		
end process;

process(clk, stallData, stallInst)
		variable start 			  	  : natural := 0;	 
		variable addressDataSum   	  : unsigned(addrSize-1 downto 0); 
		variable addressInstSum   	  : unsigned(addrSize-1 downto 0); 
		variable temp 			  	  : unsigned(addrSize-1 downto 0) := "0000000100"; 
		variable seed1Data 	     	  : positive := rand1_data;
		variable seed2Data 	      	  : positive := rand2_data;
		variable seed1Inst 	      	  : positive := rand1_inst;
		variable seed2Inst 	      	  : positive := rand2_inst;				
		variable seedSignalData1  	  : positive := plusMinusData1;
		variable seedSignalData2  	  : positive := plusMinusData2;
		variable seedSignalInst1  	  : positive := plusMinusInst1;
		variable seedSignalInst2  	  : positive := plusMinusInst2;
		variable re1Data, re1Inst 	  : integer;
		variable re2Data, re2Inst 	  : real;
		variable pm1Data, pm1Inst 	  : integer;
		variable pm2Data, pm2Inst 	  : real;  
		variable DsingleStallDuration : integer := 0;
		variable IsingleStallDuration : integer := 0;
		variable clkCounter			  : integer := 0;	 --tempo de execução
		variable dataStallTimer		  : integer := 0;
		variable instStallTimer		  : integer := 0;	   
		variable dataStallEnable	  : integer := 0;
		variable instStallMark	      : integer := 0;
		variable dataStallMark 	      : integer := 0;
		variable dataTotalStallTime   : integer := 0;
		variable instTotalStallTime   : integer := 0;
		variable instructionDataCount : integer := 0;
		variable instructionInstCount : integer := 0;
		
		--variable countInst, countData : integer := 2;   --para dar dois clk's de delay após o stall, para coordenar bem com a máq. de estados!
		
		
		begin  
			-----------------------------------------------------------------------------
			--Logica para computo de estatisticas
			if(clk'event and clk = '1') then
				clkCounter := clkCounter + 1;
					
				if(stallData = '1') then
					DsingleStallDuration := DsingleStallDuration + 1;
					dataStallMark  := 1; 
				end if;
				 
				if(stallData = '0' and dataStallMark = 1) then	
					dataStallMark        := 0;
					dataTotalStallTime   := dataTotalStallTime + DsingleStallDuration;
					DsingleStallDuration := 0;
				end if;
				 
				if(stallInst = '1') then
					IsingleStallDuration := IsingleStallDuration + 1;
					instStallMark        := 1; 
				end if;
													
				if(stallInst = '0' and instStallMark = 1) then	
					instStallMark        := 0;
					instTotalStallTime   := instTotalStallTime + IsingleStallDuration;
					IsingleStallDuration := 0;
				end if;
			-----------------------------------------------------------------------------
			--Lógica de cuspir endereços
				if(start = 0) then
					addressDataToMemory <= startAddressData;
					addressInstToMemory <= startAddressInst;
					start := 1;								
					
				elsif(restartAddr = '1') then				
					addressDataToMemory <= startAddressData;
					addressInstToMemory <= startAddressInst;
					
				elsif(setAddressEnable = '1') then
					addressDataSum := unsigned(setAddressData);
					addressInstSum := unsigned(setAddressInst);
				elsif(unsigned(endAddressData) /= addressDataSum) then
					if(stallData = '0') then
						instructionDataCount := instructionDataCount + 1;
						if(cacheMode(0) = '1') then															   --Geração de ends. para cache de dados ativa!
							if(addressMode = "00" and (not isBranchData'event) and isBranchData = '0') then	   --Endereços consecutivos
								addressDataSum := unsigned(addressDataToMemory) + unsigned(temp);	           --end. += 4
						
							elsif(addressMode = "01" and (not isBranchData'event) and isBranchData = '0') then  --Endereços randomicos
								uniform(seed1Data, seed2Data, re2Data);
								re1Data := integer(re2Data * real(2**rangeBits-1));
								randomVectorData <= bit_vector(to_unsigned(re1Data, addrSize));
								
								uniform(seedSignalData1, seedSignalData2, pm2Data);
								pm1Data := integer(pm2Data * real(1));
								
								if(pm1data = 1) then
									addressDataSum := unsigned(addressDataToMemory) + unsigned(randomVectorData); 
								else
									addressDataSum := unsigned(addressDataToMemory) - unsigned(randomVectorData); 
								end if;
								
							elsif(addressMode = "10") then			   
								uniform(seed1Data, seed2Data, re2Data);
								re1Data := integer(re2Data * real(2**addrSize-1));
								randomVectorData <= bit_vector(to_unsigned(re1Data, addrSize));
								addressDataSum := unsigned(randomVectorData); 
								
							elsif(isBranchData'event and isBranchData = '1') then							   --Endereços 	
								if(branchUpDownData = '1') then
									addressDataSum := unsigned(addressDataToMemory) + unsigned(branchDataOffset); 
								else
									addressDataSum := unsigned(addressDataToMemory) - unsigned(branchDataOffset); 
								end if;
							end if;
						end if;
					end if;
					addressDataToMemory <= bit_vector(addressDataSum);
					
					
					if(stallInst = '0' and unsigned(endAddressInst) /= addressInstSum) then
						instructionInstCount := instructionInstCount +1;
						if(cacheMode(1) = '1') then		--Geração de ends. para cache de inst ativa!
							if(addressMode = "00" and (not isBranchInst'event) and isBranchInst = '0') then
								addressInstSum := unsigned(addressInstToMemory) + unsigned(temp);	         --end. += 4
						
							elsif(addressMode = "01" and (not isBranchInst'event) and isBranchInst = '0') then
								uniform(seed1Inst, seed2Inst, re2Inst);
								re1Inst := integer(re2Inst * real(2**rangeBits-1));
								randomVectorInst <= bit_vector(to_unsigned(re1Inst, addrSize));
								
								uniform(seedSignalInst1, seedSignalInst2, pm2Inst);
								pm1Inst := integer(pm2Inst * real(1));
								
								if(pm1Inst = 1) then
									addressInstSum := unsigned(addressInstToMemory) + unsigned(randomVectorInst); 
								else
									addressInstSum := unsigned(addressInstToMemory) - unsigned(randomVectorInst); 
								end if;
								
							elsif(addressMode = "10") then			   
								uniform(seed1Inst, seed2Inst, re2Inst);
								re1Inst := integer(re2Inst * real(2**addrSize-1));
								randomVectorInst <= bit_vector(to_unsigned(re1Inst, addrSize));
								addressInstSum := unsigned(randomVectorInst); 
								
							elsif(isBranchInst'event and isBranchInst = '1') then
								if(branchUpDownInst = '1') then
									addressInstSum := unsigned(addressInstToMemory) + unsigned(branchInstOffset); 
								else
									addressInstSum := unsigned(addressInstToMemory) - unsigned(branchInstOffset); 
								end if;
							end if;
						end if;
					end if;
					addressInstToMemory <= bit_vector(addressInstSum);			
				end if;
			end if;
	end process;
							  
			
			   
		
end archi;