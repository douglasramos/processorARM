-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     top level hierarquia de Memória (Fluxo de dados + Unidade de controle)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto
library arm;
use arm.types.all;

entity memoryHierarchy is
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
		cpuWrite:      in  bit
    );
end memoryHierarchy;

architecture memoryHierarchy_arch of memoryHierarchy is

--- Cache de instruções
component cacheI is
    port(
		-- I/O relacionados ao pipeline
		clk:     in  bit;
		cpuAddr: in  bit_vector(9 downto 0);
      	stall:   out bit := '0';

		-- I/O ao nível L2
		memReady:  in  bit;
		memRW:     out bit := '0';  --- '1' write e '0' read
      	memEnable: out bit := '0';
      	dataOut:   out word_type := (others => '0');
		dataIn:    in  word_vector_type(1 downto 0);
		memAddr:   out bit_vector(9 downto 0) := (others => '0')
	);
end component;

--- Cache de dados
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
		memBlockOut:   out word_vector_type(1 downto 0) := (others => word_vector_init)

    );
end component;

component memory is
    generic (
        accessTime: in time := 40 ns
    );
    port (

		-- I/O relacionados cache de Instrucoes
		ciEnable:     in   bit := '0';
		ciMemRw:      in   bit; --- '1' write e '0' read
		ciAddr:       in   bit_vector(9 downto 0);
		ciDataBlock:  out  word_vector_type(1 downto 0) := (others => word_vector_init);
		ciMemReady:   out  bit := '0';

		-- I/O relacionados cache de dados
		cdEnable:    in  bit;
		cdMemRw:     in  bit; --- '1' write e '0' read
		cdAddr:      in  bit_vector(9 downto 0);
		cdDataIn:    in  word_vector_type(1 downto 0);
		cdDataOut:   out word_vector_type(1 downto 0) := (others => word_vector_init);
		cdMemReady:  out bit := '0'

    );
end component;

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
		memAddr        => iMemAddrI
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
		memBlockOut    => iMemDataOutD
    );

	mem : memory port map (

		-- I/O relacionados cache de Instrucoes
		ciEnable      => iMemEnableI,
		ciMemRw       => iMemRWI,
		ciAddr        => iMemAddrI,
		ciDataBlock   => iMemDataInI,
		ciMemReady    => iMemReadyI,

		-- I/O relacionados cache de dados
		cdEnable      => iMemEnableD,
		cdMemRw       => iMemRWD,
		cdAddr        => iMemAddrD,
		cdDataIn      => iMemDataOutD,
		cdDataOut     => iMemDataInD,
		cdMemReady    => iMemReadyD

    );
end architecture;