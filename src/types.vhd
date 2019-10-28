-- PCS3412 - Organizacao e Arquitetura de Computadores I
-- PicoMIPS
-- Author: Douglas Ramos
-- Co-Authors: Pedro Bitro, Rafael Higa
--
-- Description:
--     Define tipos comuns utilizados no proejto

library ieee;
use ieee.numeric_bit.all;

package types is

    subtype word_type     is bit_vector(31 downto 0);
	type word_vector_type is array(natural range <>) of word_type;

	constant word_vector_init: word_type := (others => '0');

	constant word_vector_instruction1: word_type := x"8C410050";
	constant word_vector_instruction2: word_type := x"20230005";
	constant word_vector_instruction3: word_type := x"00430820";
	constant word_vector_instruction4: word_type := x"00242820";
	
	constant j_10:            word_type := x"02001016";
	constant jal_20:          word_type := x"03001016";
	constant add_r1_r2_r3:    word_type := x"02119020";
	constant add_r4_r5_r6:    word_type := x"0274A820";
	constant add_r7_r8_r9:    word_type := x"02D7C020";
	constant slt_r4_r5_r6:    word_type := x"0274A82A";
	constant addu_r7_r8_r9:   word_type := x"02D7C021";
	constant sll_r10_r11_r12: word_type := x"033AD900";
	constant lw_r1_50_r2:     word_type := x"8E110034";
	constant sw_r3_20_r4:     word_type := x"AE530014";
	constant addi_r1_r2_7:    word_type := x"42110007";
	constant slti_r1_r2_20:   word_type := x"2A110030";
	constant add_0_r1_r2:     word_type := x"00108820";
	constant addi_r3_0_5:     word_type := x"00240005";
	constant lw_r1_20_r2:     word_type := x"8E110014";
	constant add_r3_r4_r5:    word_type := x"0253A020";
	constant add_r6_r1_r7:    word_type := x"01585810";
	constant add_r1_r1_r2:    word_type := x"02108820";
	constant add_r1_r1_r3:    word_type := x"02109020";
	constant add_r1_r1_r4:    word_type := x"02109820";
	constant beq_r1_r2_25:    word_type := x"12110019";
	constant add_r6_r7_r8:    word_type := x"02B6B820";
	constant add_r9_r10_r11:  word_type := x"0319D020";
	

	constant word_vector_test: word_type := (others => '1');

	constant word_vector_value:  word_type := x"00000070";
	constant word_vector_value2: word_type := x"00001570";
	constant word_vector_value3: word_type := x"00001670";
	constant word_vector_value4: word_type := x"00001770";

end package types;
