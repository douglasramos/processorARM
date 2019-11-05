-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Cache de instrucoes (Fluxo de dados + Unidade de controle)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto
use types.all;


entity cacheI is
    port(
		-- I/O relacionados ao pipeline
		clk:     in  bit;
		cpuAddr: in  bit_vector(9 downto 0);
		stall:   out bit := '0';
		dataOut: out word_type := (others => '0');

		-- I/O ao nível L2
		L2DataIn: in  word_vector_type(1 downto 0);
		L2Ready:  in  bit;
		L2RW:     out bit := '0';  --- '1' write e '0' read
      	L2Enable: out bit := '0';
		L2Addr:   out bit_vector(9 downto 0) := (others => '0');

		-- I/O relacionados ao victim buffer
		isVBFull:         in  bit;
		vbEnable:         out bit;
		evictedBlockData: out word_vector_type(1 downto 0);
		evictedBlockAddr: out bit_vector(9 downto 0)
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
		valid:          in  bit;
		writeOptions:   out bit := '0';
		updateInfo:     out bit := '0';

        -- I/O relacionados ao L2
		L2Ready:      in  bit;
		L2RW:         out bit := '0';  --- '1' write e '0' read
		L2Enable:     out bit := '0';

		-- I/O relacionados ao victim buffer
		isVBFull:   in  bit;
        vbEnable:   out bit
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
		valid:          out bit := '0';

		-- I/O relacionados ao IF stage
        cpuAddr: in  bit_vector(9 downto 0);
        dataOut: out word_type := (others => '0');

        -- I/O relacionados ao L2
        dataIn:  in  word_vector_type(1 downto 0);
		L2Addr:  out bit_vector(9 downto 0) := (others => '0');

		-- I/O relacionados ao victim buffer
		evictedBlockData:     out word_vector_type(1 downto 0);
		evictedBlockAddr: 	  out bit_vector(9 downto 0)
    );
end component;

	-- sinais internos
	signal iHit : bit;
	signal iWriteOptions : bit;
	signal iUpdateInfo : bit;
	signal iValid : bit;

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
	 	valid  			=> iValid,

        -- I/O relacionados a Memoria princial
		L2Ready		    => L2Ready,
		L2RW			=> L2RW,
        L2Enable		=> L2Enable,

		-- I/O relacionados ao victim buffer
		isVBFull   		=> isVBFull,
        vbEnable        => vbEnable
    );

	dataPath : cacheIPath port map(

		-- I/O relacionados ao controle
		writeOptions	=> iWriteOptions,
		updateInfo		=> iUpdateInfo,
		hit				=> iHit,
		valid  			=> iValid,

		-- I/O relacionados ao IF stage
        cpuAddr			=> cpuAddr,
        dataOut			=> dataOut,

        -- I/O relacionados a Memoria princial
        dataIn	        => L2DataIn,
		L2Addr			=> L2Addr
    );

end architecture;