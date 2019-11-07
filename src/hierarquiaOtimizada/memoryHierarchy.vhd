-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     top level hierarquia de Memória

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto
use types.all;

entity memoryHierarchy is
    port(
		clkPipeline:   in  bit;
		clkI:          in  bit;
		clkD:          in  bit;
		clkMemory:     in  bit;
		clkL2:         in  bit;

		-- I/O relacionados ao pipeline
		cpuAddrI:      in  bit_vector(9 downto 0);
		stallI:        out  bit;
		dataOutI:      out word_type;
		stallD:        out bit;
		cpuAddrD:      in  bit_vector(9 downto 0);
		dataInD :      in  word_type;
		dataOutD:      out word_type;
		cpuWrite:      in  bit
    );
end memoryHierarchy;

architecture memoryHierarchy_arch of memoryHierarchy is

-- Cache L1
component cacheL1 is
    port(
		-- I/O relacionados ao pipeline
		clkPipeline: in bit;
		clkI:        in  bit;
		clkD:        in  bit;
		cpuAddrI:    in  bit_vector(9 downto 0);
		cpuAddrD:    in  bit_vector(9 downto 0);
		cpuWrite:    in  bit;
		dataInD:     in  word_type;
		stallI:      out bit := '0';
		stallD:      out bit := '0';
		dataOutD:    out word_type := (others => '0');
		dataOutI:    out word_type := (others => '0');

		-- I/O ao nivel L2
		L2DataInI:  in  word_vector_type(1 downto 0);
		L2ReadyI:   in  bit;
		L2RWI:      out bit := '0';  --- '1' write e '0' read
      	L2EnableI:  out bit := '0';
		L2AddrI:    out bit_vector(9 downto 0) := (others => '0');

		L2DataInD:  in  word_vector_type(1 downto 0);
		L2ReadyD:   in  bit;
		L2RWD:      out bit := '0';  --- '1' write e '0' read
      	L2EnableD:  out bit := '0';
		L2AddrD:    out bit_vector(9 downto 0) := (others => '0');
		L2DataOutD: out word_vector_type(1 downto 0) := (others => word_vector_init);

		L2ReadyVB:             in  bit;
		L2BlockOutVB:  	  	   out word_vector_type(1 downto 0) := (others => word_vector_init);
		L2BlockOutAddressVB:   out bit_vector(9 downto 0) := (others => '0');
		L2BlockOutIsDirty:     out bit
	);
end component;

-- Cache L2
component cacheL2 is
    port(
		clk : in bit;
		--------------------------------
		--INPUT
		--Victim Buffer
		vbDataIn    : in word_vector_type(1 downto 0) := (others => word_vector_init);
		vbAddr      : in  bit_vector(9 downto 0);
		dirtyData   : in  bit;
		--Cache de dados
		cdRW        : in  bit;
		cdEnable    : in  bit;
		cdAddr		: in  bit_vector(9 downto 0);
		--Cache de Instrucoes
		ciRW        : in  bit;
		ciEnable    : in  bit;
		ciAddr      : in  bit_vector(9 downto 0);
		--Memoria Principal
		memReady	: in bit;
		memBlockIn  : in  word_vector_type(1 downto 0);
		--------------------------------
		--OUTPUT
		--Victim Buffer
		vbReady     : out bit;
		cdataL2Hit  : out bit := '0';
		cdDataOut   : out word_vector_type(1 downto 0) := (others => word_vector_init);
		--Cache de Instrucoes
		cinstL2Hit  : out bit := '0';
		ciDataOut   : out word_vector_type(1 downto 0) := (others => word_vector_init);
		--Memoria Principal
		memRW       : out bit := '0';  --- '1' write e '0' read
		memEnable   : out bit := '0';
		memAddr     : out bit_vector(9 downto 0) := (others => '0');
		memBlockOut : out word_vector_type(1 downto 0) := (others => word_vector_init)
    );
end component;

-- Memory
component memoryL3 is
    generic (
        accessTimeMemory: in time := 200 ns
    );
    port(

        clk : in bit;

        -- I/O com cache L2
        enable :   in bit;
        memRw :    in bit;
        addr :     in bit_vector(9 downto 0);
        dataIn :   in word_vector_type(1 downto 0);
        memReady : out bit;
        dataOut :  out word_vector_type(1 downto 0)
    );
end component;

	-- sinais L1 - L2
	signal iL2DataInI: word_vector_type(1 downto 0);
	signal iL2ReadyI:  bit;
	signal iL2RWI:     bit;
	signal iL2EnableI: bit;
	signal iL2AddrI:   bit_vector(9 downto 0);
	signal iL2DataInD:  word_vector_type(1 downto 0);
	signal iL2ReadyD:   bit;
	signal iL2RWD:      bit;
	signal iL2EnableD:  bit;
	signal iL2AddrD:    bit_vector(9 downto 0);
	signal iL2DataOutD: word_vector_type(1 downto 0);
	signal iL2ReadyVB:          bit;
	signal iL2BlockOutVB:       word_vector_type(1 downto 0);
	signal iL2BlockOutAddressVB:bit_vector(9 downto 0);
	signal iL2BlockOutIsDirty:  bit;

	-- sinais L2 e Mem
	signal imemReady:    bit;
    signal imemBlockIn:  word_vector_type(1 downto 0);
    signal imemRW:       bit;
    signal imemEnable:   bit;
    signal imemAddr:     bit_vector(9 downto 0);
    signal imemBlockOut: word_vector_type(1 downto 0);


begin


    cacheNivel1 : cacheL1 port map (
		-- I/O relacionados ao pipeline
		clkPipeline         => clkPipeline,
		clkI                => clkI,
		clkD                => clkD,
		cpuAddrI            => cpuAddrI,
		cpuAddrD            => cpuAddrD,
		cpuWrite            => cpuWrite,
		dataInD             => dataInD,
		stallI              => stallI,
		stallD              => stallD,
		dataOutD            => dataOutD,
		dataOutI            => dataOutI,

		-- I/O ao nivel L2
		L2DataInI           => iL2DataInI,
		L2ReadyI            => iL2ReadyI,
		L2RWI               => iL2RWI,
      	L2EnableI           => iL2EnableI,
		L2AddrI             => iL2AddrI,

		L2DataInD           => iL2DataInD,
		L2ReadyD            => iL2ReadyD,
		L2RWD               => iL2RWD,
      	L2EnableD           => iL2EnableD,
		L2AddrD             => iL2AddrD,
		L2DataOutD          => iL2DataOutD,

		L2ReadyVB           => iL2ReadyVB,
		L2BlockOutVB        => iL2BlockOutVB,
		L2BlockOutAddressVB => iL2BlockOutAddressVB,
		L2BlockOutIsDirty   => iL2BlockOutIsDirty
	);


	cacheNivel2 : cacheL2 port map (
		clk 				=> clkL2,
		cinstL2Hit          => iL2ReadyI,
		ciRW                => iL2RWI,
		ciEnable            => iL2EnableI,
		ciAddr              => iL2AddrI,
		ciDataOut           => iL2DataInI,
		cdataL2Hit          => iL2ReadyD,
		cdEnable            => iL2EnableD,
		cdAddr		        => iL2AddrD,
		cdDataOut           => iL2DataInD,
		cdRW                => iL2RWD,
		vbDataIn            => iL2BlockOutVB,
		vbAddr              => iL2BlockOutAddressVB,
		vbReady             => iL2ReadyVB,
		dirtyData           => iL2BlockOutIsDirty,
		memReady	        => imemReady,
		memBlockIn          => imemBlockIn,
		memRW               => imemRW,
		memEnable           => imemEnable,
		memAddr             => imemAddr,
		memBlockOut         => imemBlockOut
    );

	memory : memoryL3 port map (

        clk                 => clkMemory,
        enable              => imemEnable,
        memRw               => imemRW,
        addr                => imemAddr,
        dataIn              => imemBlockOut,
        memReady            => imemReady,
        dataOut             => imemBlockIn
    );

end architecture;