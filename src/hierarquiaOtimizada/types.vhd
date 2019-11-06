-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Define tipos comuns utilizados no projeto

library ieee;
use ieee.numeric_bit.all;

package types is

	--- word types and definitions
    subtype word_type     is bit_vector(31 downto 0);
	type word_vector_type is array(natural range <>) of word_type;
	constant word_vector_init: word_type := (others => '0');

end package types;
