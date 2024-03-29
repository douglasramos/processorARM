-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Memoria L2

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto

use types.all;


entity MemoryL2 is
    generic (
        accessTimeMemory: in time := 200 ns
    );
    port (	
		clk : in bit;
		-- I/O relacionados cache instrucao
		ciEnable:      in  bit;
        ciMemRw:       in  bit; --- '1' write e '0' read
		-- I/O cacheI e datapath da memoria
        ciMemReady:    out bit := '1';		 
		-- I/O relacionados cache dados
		cdEnable:      in  bit;
        cdMemRw:       in  bit; --- '1' write e '0' read
        -- I/O cacheD e datapath da memoria
        cdMemReady:    out bit := '1'; 

		-- I/O relacionados ao cache de instrucoes
		ciAddr:       in  bit_vector(9 downto 0);
		ciDataOut:    out word_vector_type(1 downto 0) := (others => word_vector_init);

		-- I/O relacionados ao cache de dados
		cdAddr:       in  bit_vector(9 downto 0);
		cdDataIn:     in  word_vector_type(1 downto 0);
		cdDataOut:    out word_vector_type(1 downto 0) := (others => word_vector_init);
		--Para teste no top level
		Mstate_d:   out bit_vector(2 downto 0)
    );
end MemoryL2;

architecture archi of MemoryL2 is

component MemoryL2Control is
    generic (
        accessTime: in time := 200 ns
    );
    port (

        clk:         in  bit;

        -- I/O relacionados a memoria
        cReadI:        in  bit;
        cReadD:        in  bit;
		cWrite:        in  bit;
        writeOptions:  out bit_vector(1 downto 0) := "00";

		-- I/O relacionados cache instrucao
		ciEnable:      in  bit;
        ciMemRw:       in  bit; --- '1' write e '0' read
        -- I/O cacheI e datapath da memoria
        ciMemReady:    out bit := '1';
        
        -- I/O relacionados cache dados
		cdEnable:      in  bit;
        cdMemRw:       in  bit; --- '1' write e '0' read
        -- I/O cacheD e datapath da memoria
        cdMemReady:    out bit := '1'
		
 

    );
end component;


component MemoryL2Path is
    generic (
        accessTime: in time := 200 ns
    );
    port (

		-- I/O relacionados ao controle
		writeOptions: in  bit_vector(1 downto 0);
		ciReady:      in  bit;
		cdReady:      in  bit; 
		cReadI:       out bit := '0';
		cReadD:       out bit := '0';
		cWrite:       out bit := '0';

		-- I/O relacionados ao cache de instrucoes
		ciAddr:       in  bit_vector(9 downto 0);
		ciDataOut:    out word_vector_type(1 downto 0) := (others => word_vector_init);

		-- I/O relacionados ao cache de dados
		cdAddr:       in  bit_vector(9 downto 0);
		cdDataIn:     in  word_vector_type(1 downto 0);
		cdDataOut:    out word_vector_type(1 downto 0) := (others => word_vector_init)
        
    );
end component;

signal writeOptions	    : bit_vector(1 downto 0);
signal cReadI, cReadD, cwrite    : bit;
signal ciReady, cdReady : bit;


begin

	L2MemoFD : MemoryL2Path generic map(accessTimeMemory) port map(writeOptions, ciReady, cdReady, cReadI, cReadD, cWrite, ciAddr, ciDataOut,
																    cdAddr, cdDataIn, cdDataOut);
	
	L2MemoUC : MemoryL2Control generic map(accessTimeMemory) port map(clk, cReadI, cReadD, cWrite, writeOptions, ciEnable, ciMemRw, ciReady,
        															   cdEnable, cdMemRw, cdReady);
 		ciMemReady <= ciReady;
		cdMemReady <= cdReady;																							  
	
end archi;
