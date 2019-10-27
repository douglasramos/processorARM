-- PCS3412 - Organizacao e Arquitetura de Computadores I
-- PicoMIPS
-- Author: Douglas Ramos
-- Co-Authors: Pedro Bitro, Rafael Higa
--
-- Description:
--     Define tipos comuns utilizados no proejto

library IEEE;
use IEEE.std_logic_1164.all;

package types is

    subtype wordType     is bit_vector(31 downto 0);
	type wordVectorType is array(natural range <>) of wordType;

	constant word_vector_init: wordType := (others => '0');

	constant word_vector_instruction1: wordType := x"8C410050";
	constant word_vector_instruction2: wordType := x"20230005";
	constant word_vector_instruction3: wordType := x"00430820";
	constant word_vector_instruction4: wordType := x"00242820";
	
	constant j_10:            wordType := x"02001016";
	constant jal_20:          wordType := x"03001016";
	constant add_r1_r2_r3:    wordType := x"02119020";
	constant add_r4_r5_r6:    wordType := x"0274A820";
	constant add_r7_r8_r9:    wordType := x"02D7C020";
	constant slt_r4_r5_r6:    wordType := x"0274A82A";
	constant addu_r7_r8_r9:   wordType := x"02D7C021";
	constant sll_r10_r11_r12: wordType := x"033AD900";
	constant lw_r1_50_r2:     wordType := x"8E110034";
	constant sw_r3_20_r4:     wordType := x"AE530014";
	constant addi_r1_r2_7:    wordType := x"42110007";
	constant slti_r1_r2_20:   wordType := x"2A110030";
	constant add_0_r1_r2:     wordType := x"00108820";
	constant addi_r3_0_5:     wordType := x"00240005";
	constant lw_r1_20_r2:     wordType := x"8E110014";
	constant add_r3_r4_r5:    wordType := x"0253A020";
	constant add_r6_r1_r7:    wordType := x"01585810";
	constant add_r1_r1_r2:    wordType := x"02108820";
	constant add_r1_r1_r3:    wordType := x"02109020";
	constant add_r1_r1_r4:    wordType := x"02109820";
	constant beq_r1_r2_25:    wordType := x"12110019";
	constant add_r6_r7_r8:    wordType := x"02B6B820";
	constant add_r9_r10_r11:  wordType := x"0319D020";
	

	constant word_vector_test: wordType := (others => '1');

	constant word_vector_value:  wordType := x"00000070";
	constant word_vector_value2: wordType := x"00001570";
	constant word_vector_value3: wordType := x"00001670";
	constant word_vector_value4: wordType := x"00001770";

end package types;
