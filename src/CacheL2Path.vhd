-- PCS3412 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Cache L2 (Fluxo de dados)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto
library arm;
use arm.types.all;


entity cacheL2Path is
    generic (
        accessTime: in time := 5 ns
    );
    port (

		-- I/O relacionados ao controle
		writeOptions:   in  bit_vector(1 downto 0);
		memWrite:       in  bit;
		updateInfo:     in  bit;
		hit:            out bit := '0';
		dirtyBit:       out bit := '0';

        -- I/O relacionados cache de Instrucoes
		ciEnable:       in  bit := '0';
		ciMemRw:        in  bit; --- '1' write e '0' read
		ciAddr:         in  bit_vector(31 downto 0);
		ciDataBlock:    out word_vector_type(31 downto 0) := (others => word_vector_init);
		ciMemReady:     out bit := '0'; 
		
		
		-- I/O relacionados cache de dados
		cdEnable:       in  bit;
		cdMemRw:        in  bit; --- '1' write e '0' read
		cdAddr:         in  bit_vector(31 downto 0);
		cdDataIn:       in  word_vector_type(31 downto 0);
		cdDataOut:      out word_vector_type(31 downto 0) := (others => word_vector_init);
		cdMemReady:     out bit := '0' 

		-- I/O relacionados a Memoria princial
        memBlockIn:     in  word_vector_type(15 downto 0);
		memAddr:        out bit_vector(15 downto 0) := (others => '0');
		memBlockOut:    out word_vector_type(15 downto 0) := (others => word_vector_init)

    );
end entity cacheL2Path;