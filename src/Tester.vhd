-- PCS3422 - Organizacaoo e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Testador para a hierarquia de mem�ria. Prop�e endere�os para fetch e responde a stalls
								     						  --Modos de funcionamento: saltos uniformes (4 em 4 endere�os)
															  --						saltos aleatorios
library ieee;												  --                        possibilidade de executar branch nos dois casos
use ieee.numeric_bit.all;
use ieee.math_real.all;										  -- OBS: para alterar a sequencia de valores aleatorios gerados, � necess�rio
															  -- mudar o valor das variaveis "seed" (linhas 56 - 59)

-- importa os types do projeto

use types.all; -- 1 word, 32 bits

entity tester is
	generic (
		addrSize       : natural := 10; --Basta colocar qualquer natural dessa linha para baixo!
		rangeBits      : natural := 4;                           -- Quantidade de bits de range no gerador aleat�rio de saltos
		rand1_data     : natural := 1;
		rand2_data     : natural := 2;
		rand1_inst     : natural := 21;
		rand2_inst     : natural := 22;
		plusMinusData1 : natural := 50;
		plusMinusData2 : natural := 51;
		plusMinusInst1 : natural := 100;
		plusMinusInst2 : natural := 100
	);
    port (
		clk          	  : in  bit;						 -- Mesmo ciclo de clock que os caches L1
		addressMode  	  : in  bit_vector(1 downto 0);      -- Mode "00" = instrucoes consecutivas a partir de startAddress; "01" = instru��es com offset randomico; "10" = instru��es totalmente randomicas
		cacheMode	 	  : in  bit_vector(1 downto 0);      -- Mode "01" = soh cache de instrucoes; "10" = s� cache de dados; "11" = os dois caches
		startAddressData  : in  bit_vector(addrSize-1 downto 0);
		startAddressInst  : in  bit_vector(addrSize-1 downto 0);
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

process(clk, stallData, stallInst)
		variable start 			  : natural := 0;
		variable addressDataSum   : unsigned(addrSize-1 downto 0);
		variable addressInstSum   : unsigned(addrSize-1 downto 0);
		variable temp 			  : unsigned(addrSize-1 downto 0) := "0000000100";
		variable seed1Data 	      : positive := rand1_data;
		variable seed2Data 	      : positive := rand2_data;
		variable seed1Inst 	      : positive := rand1_inst;
		variable seed2Inst 	      : positive := rand2_inst;
		variable seedSignalData1  : positive := plusMinusData1;
		variable seedSignalData2  : positive := plusMinusData2;
		variable seedSignalInst1  : positive := plusMinusInst1;
		variable seedSignalInst2  : positive := plusMinusInst2;
		variable re1Data, re1Inst : integer;
		variable re2Data, re2Inst : real;
		variable pm1Data, pm1Inst : integer;
		variable pm2Data, pm2Inst : real;


		begin
			if(clk'event and clk = '1') then
				if(start = 0) then
					addressDataToMemory <= startAddressData;
					addressInstToMemory <= startAddressInst;
					start := 1;

				else
					if(stallData = '0') then
						if(cacheMode(0) = '1') then															   --Gera��o de ends. para cache de dados ativa!
							if(addressMode = "00" and (not isBranchData'event) and isBranchData = '0') then	   --Endere�os consecutivos
								addressDataSum := unsigned(addressDataToMemory) + unsigned(temp);	           --end. += 4

							elsif(addressMode = "01" and (not isBranchData'event) and isBranchData = '0') then  --Endere�os randomicos
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

							elsif(isBranchData'event and isBranchData = '1') then							   --Endere�os
								if(branchUpDownData = '1') then
									addressDataSum := unsigned(addressDataToMemory) + unsigned(branchDataOffset);
								else
									addressDataSum := unsigned(addressDataToMemory) - unsigned(branchDataOffset);
								end if;
							end if;
						end if;
					end if;
					addressDataToMemory <= bit_vector(addressDataSum);


					if(stallInst = '0') then
						if(cacheMode(1) = '1') then		--Gera��o de ends. para cache de inst ativa!
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