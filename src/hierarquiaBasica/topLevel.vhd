-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     top level hierarquia de Memoria (Fluxo de dados + Unidade de controle)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto

use types.all;

entity topLevel is 
	generic ( 
		accessTimeMemory : in time := 200 ns; 
		addrSize         : natural := 10; --Basta colocar qualquer natural dessa linha para baixo!
		rangeBits        : natural := 4;                           -- Quantidade de bits de range no gerador aleatório de saltos
		rand1_data       : natural := 1;
		rand2_data       : natural := 2;
		rand1_inst       : natural := 21;
		rand2_inst       : natural := 22;
		plusMinusData1   : natural := 50;
		plusMinusData2   : natural := 51;
		plusMinusInst1   : natural := 100;
		plusMinusInst2   : natural := 100
	);
    port(  
		--INPUT--------------------------------------------
		clkPipeline		  : in  bit;
		clkI			  : in  bit;	--Só vou simular com clkI msm por enquanto...
		clkD			  : in  bit;
		--Relacionados ao pipeline (Dados)	  
		dataInD 		  : in  word_type;
		cpuWrite		  : in  bit;
		--Relacionados ao "Tester"
		addressMode		  : in  bit_vector(1 downto 0);      -- Mode "00" = instruções consecutivas a partir de startAddress; "01" = instruções com offset randomico; "10" = instruções totalmente randomicas
		cacheMode	 	  : in  bit_vector(1 downto 0);      -- Mode "01" = só cache de instruções; "10" = só cache de dados; "11" = os dois caches
		startAddressData  : in  bit_vector(addrSize-1 downto 0);	
		startAddressInst  : in  bit_vector(addrSize-1 downto 0);	
		isBranchData	  : in  bit;
		branchUpDownData  : in  bit;
		isBranchInst	  : in  bit;
		branchUpDownInst  : in  bit;
		branchDataOffset  : in  bit_vector(addrSize-1 downto 0);
		branchInstOffset  : in  bit_vector(addrSize-1 downto 0);
		--OUTPUT--------------------------------------------
		--Relacionados ao pipeline (instrucao)
		stallI:        out bit;
		dataOutI:      out word_type;
		--Relacionados ao pipeline (Dados)
		stallD:        out bit;
		dataOutD:      out word_type;
		--Relacionados ao "Tester"								   --aqui exibido para poder acompanhar na simulação!
		toTestAddressData : out bit_vector(addrSize-1 downto 0);
		toTestAddressInst : out bit_vector(addrSize-1 downto 0);
		--Para testes no top level
		Istate_d:      out bit_vector(2 downto 0);
		Dstate_d :	   out bit_vector(3 downto 0);
		Mstate_d:   out bit_vector(2 downto 0)
    );
end topLevel;

architecture archi of topLevel is

component memoryHierarchy is
	generic(
		accessTimeMemory: in time := 200 ns
	);
    port(
		clkPipeline:   in  bit;
		clkI:          in  bit;
		clkD:          in  bit;

		-- I/O relacionados ao pipeline (instrucao)
		cpuAddrI:      in  bit_vector(9 downto 0);
		stallI:        out  bit;
		dataOutI:      out word_type;

		-- I/O relacionados ao pipeline (Dados)
		stallD:        out bit;
		cpuAddrD:      in  bit_vector(9 downto 0);
		dataInD :      in  word_type;
		dataOutD:      out word_type;
		cpuWrite:      in  bit;
		Istate_d:   out bit_vector(2 downto 0);
		Dstate_d:   out bit_vector(3 downto 0);
		Mstate_d:   out bit_vector(2 downto 0)
    );
end	component;


component tester is											 
	generic (									
		addrSize       : natural := 10; --Basta colocar qualquer natural dessa linha para baixo!
		rangeBits      : natural := 4;                           -- Quantidade de bits de range no gerador aleatório de saltos
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
		addressMode  	  : in  bit_vector(1 downto 0);      -- Mode "00" = instruções consecutivas a partir de startAddress; "01" = instruções com offset randomico; "10" = instruções totalmente randomicas
		cacheMode	 	  : in  bit_vector(1 downto 0);      -- Mode "01" = só cache de instruções; "10" = só cache de dados; "11" = os dois caches
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
end component;

signal  cpuAddrI, cpuAddrD: bit_vector(9 downto 0);				 
signal  stallData	 	  : bit;						
signal  stallInst    	  : bit; 

begin
	
	basicHierarchy : memoryHierarchy generic map(0 ns) port map(clkPipeline, clkI, clkI, cpuAddrI, stallInst, dataOutI, stallData, cpuAddrD, dataInD, dataOutD, cpuWrite,Istate_d, Dstate_d, Mstate_d);
	
	addressGenerator : tester generic map(addrSize, rangeBits, rand1_data, rand2_data, rand1_inst, rand2_inst, plusMinusData1, plusMinusData2,
											plusMinusInst1, plusMinusInst2)
    						  port map(clkPipeline, addressMode, cacheMode, startAddressData, startAddressInst, stallData, stallInst, isBranchData,
										branchUpDownData, isBranchInst, branchUpDownInst, branchDataOffset, branchInstOffset, cpuAddrD,
										cpuAddrI);
	toTestAddressData <= cpuAddrD;
	toTestAddressInst <= cpuAddrI;
	
	stallD <= stallData;						       
	stallI <= stallInst;
	
end archi;