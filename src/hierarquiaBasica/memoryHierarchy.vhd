-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     top level hierarquia de Memoria nao otimizada (cache de 1 nivel somente; L2 ja eh a memoria)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto

use types.all;

entity memoryHierarchy is
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
		
		--Para testes no top level
		Istate_d:      out bit_vector(2 downto 0);
		Dstate_d :	   out bit_vector(3 downto 0);
		Mstate_d:   out bit_vector(2 downto 0)
		
    );
end memoryHierarchy;

architecture memoryHierarchy_arch of memoryHierarchy is

------------------------------------------------------------------------- Cache de instrucoes
component cacheI is
    port(
		-- I/O relacionados ao pipeline
		clk:     in  bit;
		cpuAddr: in  bit_vector(9 downto 0);
      	stall:   out bit := '0';

		-- I/O ao nivel L2
		memReady:  in  bit;
		memRW:     out bit := '0';  --- '1' write e '0' read
      	memEnable: out bit := '0';
      	dataOut:   out word_type := (others => '0');
		dataIn:    in  word_vector_type(1 downto 0);
		memAddr:   out bit_vector(9 downto 0) := (others => '0');
		state_d:   out bit_vector(2 downto 0)
	);
end component;

------------------------------------------------------------------------- Cache de dados
component cacheD is
    port(
		clk:           in  bit;
		clkPipeline:   in  bit;
		cpuWrite:      in  bit;
		cpuAddr:       in  bit_vector(9 downto 0);
		stall:         out bit := '0';

		dataIn :       in  word_type;
		dataOut:       out word_type;

		memReady:      in  bit;
		memRW:         out bit := '0';  --- '1' write e '0' read
        memEnable:     out bit := '0';

		memBlockIn:    in  word_vector_type(1 downto 0);
		memAddr:       out bit_vector(9 downto 0) := (others => '0');
		memBlockOut:   out word_vector_type(1 downto 0) := (others => word_vector_init);
		--Para testes no top level
		state_d :	   out bit_vector(3 downto 0)
    );
end component;

------------------------------------------------------------------------- L2: Memoria
component MemoryL2 is
    generic (
        accessTimeMemory: in time := 200 ns
    );
    port (	
		clk : in bit;
		-- I/O relacionados cache instrucao
		ciEnable:      in  bit;
        ciMemRw:       in  bit; --- '1' write e '0' read
		-- I/O cacheI e datapath da memoria
        ciMemReady:    out bit := '1';		 
		-- I/O relacionados cache dados
		cdEnable:      in  bit;
        cdMemRw:       in  bit; --- '1' write e '0' read
        -- I/O cacheD e datapath da memoria
        cdMemReady:    out bit := '1'; 

		-- I/O relacionados ao cache de instrucoes
		ciAddr:       in  bit_vector(9 downto 0);
		ciDataOut:    out word_vector_type(1 downto 0) := (others => word_vector_init);

		-- I/O relacionados ao cache de dados
		cdAddr:       in  bit_vector(9 downto 0);
		cdDataIn:     in  word_vector_type(1 downto 0);
		cdDataOut:    out word_vector_type(1 downto 0) := (others => word_vector_init);
		--Para teste no top level
		Mstate_d:   out bit_vector(2 downto 0)
    );
end component;


------------------------------------------------------------------------- Signals

	signal iMemReadyI: bit;
	signal iMemRWI: bit;
	signal iMemEnableI: bit;
	signal iMemDataInI: word_vector_type(1 downto 0);
	signal iMemAddrI: bit_vector(9 downto 0);

	signal iMemReadyD: bit;
	signal iMemRWD: bit;
	signal iMemEnableD: bit;
	signal iMemDataInD: word_vector_type(1 downto 0);
	signal iMemDataOutD: word_vector_type(1 downto 0);
	signal iMemAddrD: bit_vector(9 downto 0);

	signal writeOptions : bit_vector(1 downto 0);
	
	signal blockOut 				   : word_vector_type(1 downto 0);     -- Saida do victim buffer: um bloco
	signal blockOutAddress			   : bit_vector(9 downto 0);
	signal blockOutIsDirty			   : bit;
	
begin

	instruction : cacheI port map (
		-- I/O relacionados ao pipeline
		clk            => clkI,
		cpuAddr        => cpuAddrI,
      	stall          => stallI,
		dataOut        => dataOutI,

		-- I/O ao nivel L2
		memReady       => iMemReadyI,
		memRW          => iMemRWI,
      	memEnable      => iMemEnableI,
		dataIn         => iMemDataInI,
		memAddr        => iMemAddrI,
		state_d        => Istate_d
	);

	data : cacheD  port map (
		clk            => clkD,
		clkPipeline    => clkPipeline,
		cpuWrite       => cpuWrite,
		cpuAddr        => cpuAddrD,
		stall          => stallD,
		dataIn         => dataInD,
		dataOut        => dataOutD,

		memReady       => iMemReadyD,
		memRW          => iMemRWD,
        memEnable      => iMemEnableD,

		memBlockIn     => iMemDataInD,
		memAddr        => iMemAddrD,
		memBlockOut    => iMemDataOutD,
		state_d        => Dstate_d
    );

	
	
	
	MemoriaL2 : MemoryL2 generic map(accessTimeMemory) port map(clkI, iMemEnableI, iMemRWI, iMemReadyI, iMemEnableD, iMemRWD, iMemReadyD,
																 iMemAddrI, iMemDataInI, iMemAddrD, iMemDataOutD, iMemDataInD, Mstate_d);
										 
										
end architecture;