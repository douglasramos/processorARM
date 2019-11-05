-- PCS3412 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Cache de instrucoes (Fluxo de dados + Unidade de controle)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto
library arm;
use arm.types.all;

entity cacheD is
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
end cacheD;

architecture cacheD_arch of cacheD is

component cacheDControl is
    generic (
        accessTime: in time := 5 ns
    );
    port (

		-- I/O relacionados ao stage MEM
		clk:           in bit;
		clkPipeline:   in  bit;
        cpuWrite:      in  bit;
		cpuAddr:       in  bit_vector(9 downto 0);
		stall:         out bit := '0';

		-- I/O relacionados ao cache
		dirtyBit:      in  bit;
		hitSignal:     in  bit;
		writeOptions:  out bit_vector(1 downto 0) := "00";
		updateInfo:    out bit := '0';

        -- I/O relacionados a Memoria princial
		memReady:      in  bit;
		memRW:         out bit := '0';  --- '1' write e '0' read
        memEnable:     out bit := '0'

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

		-- I/O relacionados ao MEM stage
        cpuAddr:        in  bit_vector(9 downto 0);
		dataIn :        in  word_type;
		dataOut:        out word_type;

		-- I/O relacionados a Memoria princial
        memBlockIn:     in  word_vector_type(1 downto 0);
		memAddr:        out bit_vector(9 downto 0) := (others => '0');
		memBlockOut:    out word_vector_type(1 downto 0) := (others => word_vector_init)

    );
end component;

		signal iDirtyBit : bit;
		signal iHit : bit;
		signal iWriteOptions : bit_vector(1 downto 0);
		signal iUpdateInfo : bit;
		signal iMemWrite: bit;

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

        -- I/O relacionados a Memoria princial
		memReady		=> memReady,
		memRW			=> memRW,
      	memEnable		=> memEnable
    );

	dataPath : cacheDPath port map(
		-- I/O relacionados ao controle
		writeOptions	=> iWriteOptions,
		updateInfo		=> iUpdateInfo,
		hit				=> iHit,
		dirtyBit		=> iDirtyBit,

		-- I/O relacionados ao MEM stage
      	cpuAddr			=> cpuAddr,
		dataIn 			=> dataIn,
		dataOut			=> dataOut,

		-- I/O relacionados a Memoria princial
      	memBlockIn		=> memBlockIn,
		memAddr			=> memAddr,
		memBlockOut		=> memBlockOut
	);

end architecture;