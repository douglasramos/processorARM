-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Cache de instrucoes (Fluxo de dados + Unidade de controle)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto
use types.all;

entity cacheL1 is
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
      	L2EnableI:  out bit := '0';
		L2AddrI:    out bit_vector(9 downto 0) := (others => '0');

		L2DataInD:  in  word_vector_type(1 downto 0);
		L2ReadyD:   in  bit;
      	L2EnableD:  out bit := '0';
		L2AddrD:    out bit_vector(9 downto 0) := (others => '0');
		L2DataOutD: out word_vector_type(1 downto 0) := (others => word_vector_init);

		L2ReadyVB:             in  bit;
		L2BlockOutVB:  	  	   out word_vector_type(1 downto 0) := (others => word_vector_init);
		L2BlockOutAddressVB:   out bit_vector(9 downto 0) := (others => '0');
		L2BlockOutIsDirty:     out bit
	);
end cacheL1;


architecture cacheL1_arch of cacheL1 is

-- CacheI
component cacheI is
    port(
		-- I/O relacionados ao pipeline
		clk:     in  bit;
		cpuAddr: in  bit_vector(9 downto 0);
		stall:   out bit := '0';
		dataOut: out word_type := (others => '0');

		-- I/O ao nivel L2
		L2DataIn: in  word_vector_type(1 downto 0);
		L2Ready:  in  bit;
      	L2Enable: out bit := '0';
		L2Addr:   out bit_vector(9 downto 0) := (others => '0');

		-- I/O relacionados ao victim buffer
		isVBFull:         in  bit;
		vbEnable:         out bit;
		evictedBlockData: out word_vector_type(1 downto 0);
		evictedBlockAddr: out bit_vector(9 downto 0)
	);
end component;


-- CacheD
component cacheD is
    port(
		clk:           in  bit;
		clkPipeline:   in  bit;
		cpuWrite:      in  bit;
		cpuAddr:       in  bit_vector(9 downto 0);
		stall:         out bit := '0';

		dataIn :       in  word_type;
		dataOut:       out word_type;

		L2Ready:       in  bit;
        L2Enable:      out bit := '0';

		L2BlockIn:    in  word_vector_type(1 downto 0);
		L2Addr:       out bit_vector(9 downto 0) := (others => '0');
        L2BlockOut:   out word_vector_type(1 downto 0) := (others => word_vector_init);

		-- I/O relacionados ao Victim Buffer
        isVBFull:   	  in  bit;
        vbEnable:   	  out bit;
		evictedBlockData: out word_vector_type(1 downto 0);
		evictedBlockAddr: out bit_vector(9 downto 0);
		dirtyBit:   	  out bit

    );
end component;

-- Victim Buffer
component victimBuffer is
    generic (
        accessTime: in time := 5 ns
    );
    port (
		clk 			   		   : in  bit;
		queueInst		           : in  bit;
		queueData		           : in  bit;
		readyL2			   		   : in  bit;
		evictedBlockData		   : in  word_vector_type(1 downto 0);
		evictedBlockDataAddress	   : in  bit_vector(9 downto 0);
		evictedBlockDataDirty	   : in  bit;
		evictedBlockInst		   : in  word_vector_type(1 downto 0);
		evictedBlockInstAddress	   : in  bit_vector(9 downto 0);
		evictedBlockInstDirty	   : in  bit := '0';
		blockOut  	  			   : out word_vector_type(1 downto 0);
		blockOutAddress			   : out bit_vector(9 downto 0);
		blockOutIsDirty			   : out bit
    );
end component;

	-- sinais internos
	signal iVbEnableI : bit;
	signal iEvictedBlockDataI : word_vector_type(1 downto 0);
	signal iEvictedBlockAddrI : bit_vector(9 downto 0);


	signal iVbEnableD : bit;
	signal iEvictedBlockDataD : word_vector_type(1 downto 0);
	signal iEvictedBlockAddrD : bit_vector(9 downto 0);
	signal iDirtyBitD : bit;


	signal iIsVBFull : bit;
begin

	instruction : cacheI port map (
		-- I/O relacionados ao pipeline
		clk                => clkI,
		cpuAddr            => cpuAddrI,
		stall              => stallI,
		dataOut            => dataOutI,

		-- I/O ao nivel L2
		L2DataIn           => L2DataInI,
		L2Ready            => L2ReadyI,
		L2RW               => L2RWI,
      	L2Enable           => L2EnableI,
		L2Addr             => L2AddrI,

		-- I/O relacionados ao victim buffer
		isVBFull           => iIsVBFull,
		vbEnable           => iVbEnableI,
		evictedBlockData   => iEvictedBlockDataI,
		evictedBlockAddr   => iEvictedBlockAddrI
	);

	data : cacheD port map (
		clk                => clkD,
		clkPipeline        => clkPipeline,
		cpuWrite           => cpuWrite,
		cpuAddr            => cpuAddrD,
		stall              => stallD,

		dataIn             => dataInD,
		dataOut            => dataOutD,

		L2Ready            => L2ReadyD,
		L2RW               => L2RWD,
        L2Enable           => L2EnableD,
		L2BlockIn          => L2DataInD,
		L2Addr             => L2AddrD,
        L2BlockOut         => L2DataOutD,

		-- I/O relacionados ao Victim Buffer,
        isVBFull           => iIsVBFull,
        vbEnable           => iVbEnableD,
		evictedBlockData   => iEvictedBlockDataD,
		evictedBlockAddr   => iEvictedBlockAddrD,
		dirtyBit           => iDirtyBitD
	);

	vb: victimBuffer port map (
		clk 			   		   => clkD,
		queueInst		           => iVbEnableI,
		queueData		           => iVbEnableD,
		readyL2			   		   => L2ReadyVB,
		evictedBlockData		   => iEvictedBlockDataD,
		evictedBlockDataAddress	   => iEvictedBlockAddrD,
		evictedBlockDataDirty	   => iDirtyBitD,
		evictedBlockInst		   => iEvictedBlockDataI,
		evictedBlockInstAddress	   => iEvictedBlockAddrI,
		evictedBlockInstDirty	   => '0', -- instrucao nao tem dirtyBit
		blockOut  	  			   => L2BlockOutVB,
		blockOutAddress			   => L2BlockOutAddressVB,
		blockOutIsDirty		       => L2BlockOutIsDirty
    );

end architecture;