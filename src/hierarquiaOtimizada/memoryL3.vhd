-------------------------------------------------------------------------------
-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Memoria L3

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto

use types.all;

entity memoryL3 is
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
end memoryL3;

architecture archi of memoryL3 is

component MemoryL3Control

  generic(
        accessTime : time := 200 ns
  );
  port (

        clk:        in  bit;

        -- I/O relacionados a memoria
        cRead:     in  bit;
        cWrite:    in  bit;
        RW:        out bit_vector(1 downto 0) := "00";

        -- I/O relacionados cache L2
        enable:    in  bit;
        memRw:     in  bit; --- '1' write e '0' read
        memReady:  out bit := '0'

  );
end component;


component MemoryL3Path
  generic(
        accessTime : time := 200 ns
  );
  port (

		-- I/O relacionados ao controle
		RW:          in  bit_vector(1 downto 0);
		cRead:       out bit := '0';
		cWrite:      out bit := '0';

		-- I/O relacionados cache L2
		addr:        in  bit_vector(9 downto 0);
		dataIn:      in  word_vector_type(1 downto 0);
        dataOut:     out word_vector_type(1 downto 0) := (others => word_vector_init)
        
  );
end component;

---- Signal declarations used on the diagram ----

signal cRead : bit;
signal cWrite : bit;
signal RW : bit_vector(1 downto 0);

begin

----  Component instantiations  ----

L3MemoUC : MemoryL3Control
    generic map(accessTimeMemory)
    port map(
        RW => RW,
        cRead => cRead,
        cWrite => cWrite,
        clk => clk,
        enable => enable,
        memReady => memReady,
        memRw => memRw
    );

L3MemoFD : MemoryL3Path
    generic map(accessTimeMemory)
    port map(
        RW => RW,
        addr => addr,
        cRead => cRead,
        cWrite => cWrite,
        dataIn => dataIn,
        dataOut => dataOut
    );


end archi;
