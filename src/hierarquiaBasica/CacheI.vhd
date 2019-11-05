-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Cache de instrucoes (Fluxo de dados + Unidade de controle)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto
library arm;
use arm.types.all;


entity cacheI is
    port(
		-- I/O relacionados ao pipeline
		clk:     in  bit;
		cpuAddr: in  bit_vector(9 downto 0);
		stall:   out bit := '0';
		dataOut: out word_type := (others => '0');

		-- I/O ao nível L2
		dataIn:    in  word_vector_type(1 downto 0);
		memReady:  in  bit;
		memRW:     out bit := '0';  --- '1' write e '0' read
      	memEnable: out bit := '0';
		memAddr:   out bit_vector(9 downto 0) := (others => '0')
	);
end cacheI;

architecture cacheI_arch of cacheI is

-- Controle do CacheI
component cacheIControl is
    generic (
        accessTime: in time := 5 ns
    );
    port (

		-- I/O relacionados ao stage IF
		clk:    in  bit;
      	stall:  out bit := '0';
		pc:     in  bit_vector(9 downto 0);

		-- I/O relacionados ao cache
		hitSignal:      in  bit;
		writeOptions:   out bit := '0';
		updateInfo:     out bit := '0';

        -- I/O relacionados a Mem�ria princial
		memReady:      in  bit;
		memRW:         out bit := '0';  --- '1' write e '0' read
        memEnable:     out bit := '0'

    );
end component;

-- Fluxo de dados cacheI
component cacheIPath is
    generic (
        accessTime: in time := 5 ns
    );
    port (

		-- I/O relacionados ao controle
		writeOptions:   in  bit;
		updateInfo:     in  bit;
		hit:            out bit := '0';

		-- I/O relacionados ao IF stage
        cpuAddr: in  bit_vector(9 downto 0);
        dataOut: out word_type;

        -- I/O relacionados a Memoria princial
        memBlocoData:  in  word_vector_type(1 downto 0);
		memAddr:       out bit_vector(9 downto 0) := (others => '0')

    );
end component;

	-- sinais internos
	signal iHit : bit;
	signal iWriteOptions : bit;
	signal iUpdateInfo : bit;

begin

	control : cacheIControl port map (

		-- I/O relacionados ao stage IF
		clk				=> clk,
        stall			=> stall,
		pc				=> cpuAddr,

		-- I/O relacionados ao cache
		hitSignal		=> iHit,
		writeOptions	=> iWriteOptions,
		updateInfo		=> iUpdateInfo,

        -- I/O relacionados a Memoria princial
		memReady		=> memReady,
		memRW			=> memRW,
        memEnable		=> memEnable

    );

	dataPath : cacheIPath port map(

		-- I/O relacionados ao controle
		writeOptions	=> iHit,
		updateInfo		=> iUpdateInfo,
		hit				=> iHit,

		-- I/O relacionados ao IF stage
        cpuAddr			=> cpuAddr,
        dataOut			=> dataOut,

        -- I/O relacionados a Memoria princial
        memBlocoData	=> dataIn,
		memAddr			=> memAddr
    );

end architecture;