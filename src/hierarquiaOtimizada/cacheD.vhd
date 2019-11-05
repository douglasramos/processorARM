-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Cache de instrucoes (Fluxo de dados + Unidade de controle)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto
use types.all;

entity cacheD is
    port(
		clk:           in  bit;
		clkPipeline:   in  bit;
		cpuWrite:      in  bit;
		cpuAddr:       in  bit_vector(9 downto 0);
		stall:         out bit := '0';

		dataIn :       in  word_type;
		dataOut:       out word_type;

		L2Ready:       in  bit;
		L2RW:          out bit := '0';  --- '1' write e '0' read
        L2Enable:      out bit := '0';

		L2BlockIn:    in  word_vector_type(1 downto 0);
		L2Addr:       out bit_vector(9 downto 0) := (others => '0');
        L2BlockOut:   out word_vector_type(1 downto 0) := (others => word_vector_init);

        isVBFull:   in  bit;
        vbEnable:   out bit;

        -- I/O relacionados ao Victim Buffer
		evictedBlockData: out word_vector_type(1 downto 0);
		evictedBlockAddr: out bit_vector(9 downto 0)

    );
end cacheD;

architecture cacheD_arch of cacheD is

component cacheDControl is
    generic (
        accessTime: in time := 5 ns
    );
    port (

		-- I/O relacionados ao stage MEM
		clk:            in  bit;
		clkPipeline:    in  bit;
        cpuWrite:       in  bit;
		cpuAddr:        in  bit_vector(9 downto 0);
		stall:          out bit := '0';

		-- I/O relacionados ao cache
		dirtyBit:      in  bit;
		hitSignal:     in  bit;
		valid:         in  bit;
        writeOptions:  out bit_vector(1 downto 0) := "00";
		updateInfo:    out bit := '0';

        -- I/O relacionados ao L2
		L2Ready:      in  bit;
		L2RW:         out bit := '0';  --- '1' write e '0' read
        L2Enable:     out bit := '0';

        -- I/O relacionados ao victim buffer
		isVBFull:   in  bit;
        vbEnable:   out bit

    );
end component;

component cacheDPath is
    generic (
        accessTime: in time := 5 ns
    );
    port (

		-- I/O relacionados ao controle
		writeOptions:   in  bit_vector(1 downto 0);
		updateInfo:     in  bit;
		hit:            out bit := '0';
		dirtyBit:       out bit := '0';
		valid:          out bit := '0';

		-- I/O relacionados ao MEM stage
        cpuAddr:        in  bit_vector(9 downto 0);
		dataIn :        in  word_type;
		dataOut:        out word_type;

		-- I/O relacionados ao L2
        L2BlockIn:     in  word_vector_type(1 downto 0);
		L2Addr:        out bit_vector(9 downto 0) := (others => '0');
		L2BlockOut:    out word_vector_type(1 downto 0) := (others => word_vector_init);

		-- I/O relacionados ao Victim Buffer
		evictedBlockData: out word_vector_type(1 downto 0);
		evictedBlockAddr: out bit_vector(9 downto 0)
    );
end component;

    signal iDirtyBit : bit;
    signal iHit : bit;
    signal iWriteOptions : bit_vector(1 downto 0);
    signal iUpdateInfo : bit;
    signal iMemWrite: bit;
    signal iValid : bit;

begin

	control : cacheDControl port map(
		-- I/O relacionados ao stage MEM
		clk			   => clk,
		clkPipeline    => clkPipeline,
        cpuWrite       => cpuWrite,
		cpuAddr        => cpuAddr,
		stall          => stall,

		-- I/O relacionados ao cache
		dirtyBit		=> iDirtyBit,
		hitSignal		=> iHit,
		writeOptions	=> iWriteOptions,
        updateInfo		=> iUpdateInfo,
		valid  			=> iValid,

        -- I/O relacionados a Memoria princial
		L2Ready		    => L2Ready,
		L2RW			=> L2RW,
        L2Enable		=> L2Enable,

        -- I/O relacionados ao victim buffer
		isVBFull   		=> isVBFull,
        vbEnable        => vbEnable
    );

	dataPath : cacheDPath port map(
		-- I/O relacionados ao controle
		writeOptions	 => iWriteOptions,
		updateInfo		 => iUpdateInfo,
		hit				 => iHit,
        dirtyBit		 => iDirtyBit,
		valid  			=> iValid,

		-- I/O relacionados ao MEM stage
      	cpuAddr			 => cpuAddr,
		dataIn 			 => dataIn,
		dataOut			 => dataOut,

		-- I/O relacionados a ao L2
      	L2BlockIn		 => L2BlockIn,
		L2Addr			 => L2Addr,
        L2BlockOut		 => L2BlockOut,

        evictedBlockData => evictedBlockData,
        evictedBlockAddr => evictedBlockAddr
	);

end architecture;