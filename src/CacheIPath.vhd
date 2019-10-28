-- PCS3412 - Organizacao e Arquitetura de Computadores I
-- PicoMIPS
-- Author: Douglas Ramos
-- Co-Authors: Pedro Brito, Rafael Higa
--
-- Description:
--     Cache de Instrucoes

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all; 

-- importa os types do projeto
library arm;
use arm.types.all;


entity CacheI is
    generic (
        accessTime: in time := 5 ns
    );
    port (
		
		-- I/O relacionados ao controle
		writeOptions:   in bit;
		updateInfo:     in bit; 
		hit:             out bit := '0';
		
		-- I/O relacionados ao IF stage
        cpuAdrr: in  bit_vector(15 downto 0);
        dataOut: out wordType;	

        -- I/O relacionados a Memoria princial
        memBlocoData: in  wordVectorType(15 downto 0);
		memAddr:      out bit_vector(15 downto 0) := (others => '0')
		
		   
    );
end entity CacheI;

architecture CacheIArch of CacheI is	 	  
							  
	constant cacheSize:        positive := 2**14; -- 16KBytes = 4096 * 4 bytes (4096 words de 32bits)
	constant palavrasPorBloco: positive := 16;
	constant blocoSize:        positive := palavrasPorBloco * 4; --- 16 * 4 = 64Bytes
    constant numberOfBlocks:   positive := cacheSize / blocoSize; -- 256 blocos
	
	--- Cada "linha" no cache possui valid + tag + data
	    type cacheRowType is record
        valid: bit;
        tag:   bit_vector(1 downto 0);
        data:  wordVectorType(palavrasPorBloco - 1 downto 0);
    end record cacheRowType;

    type cacheType is array (numberOfBlocks - 1 downto 0) of cacheRowType;
	
	constant cache_row_init : cacheRowType := (valid => '0',
												 tag => (others => '0'),   
												 data => (others => word_vector_init));

	
	constant cache_row_instruction : cacheRowType := (valid => '1',
												 tag => (others => '0'),   
												 data => (0 => word_vector_instruction1,
												 		  1 => word_vector_instruction2,
												 		  others => word_vector_init));
												 
	constant cache_row_instruction_nop : cacheRowType := (valid => '1',
												 tag => (others => '0'),   
												 data => (0 => word_vector_instruction1,
												 		  4 => word_vector_instruction2,
												 		  others => word_vector_init));
														   
    constant cache_row_instruction2 : cacheRowType := (valid => '1',
												 tag => (others => '0'),   
												 data => (0 => word_vector_instruction3,
												 		  1 => word_vector_instruction4,
												 		  others => word_vector_init));
												 
	constant cache_row_instruction_nop2 : cacheRowType := (valid => '1',
												 tag => (others => '0'),   
												 data => (0 => word_vector_instruction3,
												 		  4 => word_vector_instruction4,
												 		  others => word_vector_init));
														   
   	constant cache_row_instruction_t1 : cacheRowType := (valid => '1',
												 tag => (others => '0'),   
												 data => (0 => j_10,
												 		  1 => jal_20,
												 		  2 => add_r1_r2_r3,
														  3 => slt_r4_r5_r6,
														  4 => addu_r7_r8_r9,
														  5 => sll_r10_r11_r12,
														  6 => lw_r1_50_r2,
														  7 => sw_r3_20_r4,
														  8 => addi_r1_r2_7,
														  9 => slti_r1_r2_20,
														  others => word_vector_init));	
														   
	constant cache_row_instruction_t2 : cacheRowType := (valid => '1',
												 tag => (others => '0'),   
												 data => (0 => add_r1_r2_r3,
												 		  1 => add_r4_r5_r6,
												 		  2 => add_r7_r8_r9,
												 		  others => word_vector_init));	
														   
 	constant cache_row_instruction_t3 : cacheRowType := (valid => '1',
												 tag => (others => '0'),   
												 data => (0 => add_0_r1_r2,
												 		  1 => addi_r3_0_5,
												 		  others => word_vector_init));	

  	constant cache_row_instruction_t5 : cacheRowType := (valid => '1',
												 tag => (others => '0'),   
												 data => (0 => lw_r1_20_r2,
												 		  1 => add_r3_r4_r5,
												 		  2 => add_r6_r1_r7,
												 		  others => word_vector_init));	
														   
   	constant cache_row_instruction_t6 : cacheRowType := (valid => '1',
												 tag => (others => '0'),   
												 data => (0 => add_r1_r1_r2,
												 		  1 => add_r1_r1_r3,
												 		  2 => add_r1_r1_r4,
												 		  others => word_vector_init));	
														   
  	constant cache_row_instruction_t7 : cacheRowType := (valid => '1',
												 tag => (others => '0'),   
												 data => (0 => beq_r1_r2_25,
												 		  1 => add_r3_r4_r5,
												 		  2 => add_r6_r7_r8,
														  3 => add_r9_r10_r11,
														  4 => addu_r7_r8_r9,
														  5 => sll_r10_r11_r12,
														  6 => lw_r1_50_r2,
														  7 => sw_r3_20_r4,
														  8 => addi_r1_r2_7,
														  9 => slti_r1_r2_20,
												 		  others => word_vector_init));	
														   														   

	--- definicao do cache												 
    signal cache: cacheType := (64 => 	cache_row_instruction,
								 68 => 	cache_row_instruction2,
								 72 =>  cache_row_instruction_nop2,
								 128 => cache_row_instruction_nop, 
								 148 => cache_row_instruction_t1,
								 149 => cache_row_instruction_t2,
								 150 => cache_row_instruction_t3,
								 151 => cache_row_instruction_t5,
								 152 => cache_row_instruction_t6,
								 153 => cache_row_instruction_t7,
								 others => cache_row_init);
	
	--- Demais sinais internos
	signal memBlockAddr: natural;
	signal index: natural;
	signal wordOffset: natural;
	signal tag: bit_vector(1 downto 0);
	
		
begin 
	-- obtem campos do cache a partir do endereco de entrada
	memBlockAddr <= to_integer(unsigned(cpuAdrr(15 downto 6)));
	index        <= memBlockAddr mod numberOfBlocks;
	tag          <= cpuAdrr(15 downto 14);
	wordOffset   <= to_integer(unsigned(cpuAdrr(5 downto 2)));
		
							
    --  saidas
	hit <= '1' when cache(index).valid = '1' and cache(index).tag = tag else '0';
	dataOut <=	cache(index).data(wordOffset);
	memAddr <= cpuAdrr;
	
	-- atualizacao do cache de acordo com os sinais de controle
	process(updateInfo, writeOptions)
	begin
		if (updateInfo'event or writeOptions'event) then
			
			-- atualiza informacoes do cache
			if (updateInfo'event and updateInfo = '1') then
				cache(index).tag <= tag;
				cache(index).valid <= '1';
			end if;
			
			-- writeOptions 0 -> mantem valor do cache inalterado
			-- writeOptions 1 -> usa o valor do mem (ocorreu miss)
			if (writeOptions'event and writeOptions = '1') then
				cache(index).data <= memBlocoData;
			end if;
			
		end if;
	end process;

end architecture CacheIArch;