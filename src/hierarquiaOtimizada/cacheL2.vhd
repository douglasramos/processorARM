-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     top level cache L2 (Fluxo de dados + Unidade de controle)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto

use types.all;

entity cacheL2 is
    port(
		clk : in bit;
		--------------------------------
		--INPUT
		--Victim Buffer
		vbDataIn    : in word_vector_type(1 downto 0) := (others => word_vector_init);
		vbAddr      : in  bit_vector(9 downto 0);
		dirtyData   : in  bit;
		--Cache de dados
		cdRW        : in  bit;
		cdEnable    : in  bit;	
		cdAddr		: in  bit_vector(9 downto 0);
		--Cache de Instru��es
		ciRW        : in  bit;
		ciEnable    : in  bit;
		ciAddr      : in  bit_vector(9 downto 0);
		--Memoria Principal
		memReady	: in bit;
		memBlockIn  : in  word_vector_type(1 downto 0);
		--------------------------------
		--OUTPUT
		--Victim Buffer
		vbReady     : out bit;	
		cdataL2Hit  : out bit := '0';
		cdDataOut   : out word_vector_type(1 downto 0) := (others => word_vector_init);
		--Cache de Instru��es
		cinstL2Hit  : out bit := '0';
		ciDataOut   : out word_vector_type(1 downto 0) := (others => word_vector_init);
		--Memoria Principal
		memRW       : out bit := '0';  --- '1' write e '0' read
		memEnable   : out bit := '0';
		memAddr     : out bit_vector(9 downto 0) := (others => '0');
		memBlockOut : out word_vector_type(1 downto 0) := (others => word_vector_init)
    );
end cacheL2;

architecture archi of cacheL2 is

component cacheL2Path is
    generic (
        accessTime: in time := 5 ns
    );
    port (

		-- I/O relacionados ao controle
		writeOptions:   in  bit_vector(1 downto 0);
		addrOptions:    in  bit_vector(1 downto 0);
		updateInfo:     in  bit;
		ciL2Hit:        in  bit;
		cdL2Hit:        in  bit;
		hit:            out bit := '0';
		dirtyBit:       out bit := '0';
		
		-- I/O relacionados ao victim buffer
		vbDataIn:       in word_vector_type(1 downto 0) := (others => word_vector_init);
		vbAddr:          in  bit_vector(9 downto 0);
		dirtyData:       in  bit;

		-- I/O relacionados ao cache de dados
		cdAddr:          in  bit_vector(9 downto 0);
		cdDataOut:      out word_vector_type(1 downto 0) := (others => word_vector_init);

		-- I/O relacionados ao cache de instruções
		ciAddr:         in  bit_vector(9 downto 0);
		ciDataOut:      out word_vector_type(1 downto 0) := (others => word_vector_init);

		-- I/O relacionados a Memoria princial
        memBlockIn:     in  word_vector_type(1 downto 0);
		memAddr:        out bit_vector(9 downto 0) := (others => '0');
		memBlockOut:    out word_vector_type(1 downto 0) := (others => word_vector_init)

    );
end component;

component cacheL2Control is
    generic (
        accessTime: in time := 50 ns
    );
    port (			  
        
        -- I/O pipeline?
        clk:           in  bit;

		-- I/O relacionado ao victim buffer
		vbDataIn:      in word_vector_type(1 downto 0) := (others => word_vector_init);
		vbAddr:        in  bit_vector(9 downto 0);
		vbReady:       out bit;

		-- I/O relacionado ao cache de dados
		cdRW:          in  bit;
		cdEnable:      in  bit;
		-- I/O cacheD e datapath do L2
		cdL2Hit:       out bit := '0';

		-- I/O relacionado ao cache de instruções
		ciRW:          in  bit;
		ciEnable:      in  bit;
		-- I/O cachel e datapath do L2
		ciL2Hit:       out bit := '0';

		-- I/O relacionados ao cache L2
		dirtyBit:      in  bit;
		hitSignal:     in  bit;
		writeOptions:  out bit_vector(1 downto 0) := "00";
		addrOptions:   out bit_vector(1 downto 0) := "00";
		updateInfo:    out bit := '0';
		
        -- I/O relacionados a Memoria princial
		memReady:      in  bit;
		memRW:         out bit := '0';  --- '1' write e '0' read
        memEnable:     out bit := '0'
        
    );
end component;

signal writeOptions, addrOptions : bit_vector(1 downto 0);
signal updateInfo                : bit;
signal dirtyBit					 : bit;
signal hitSignal				 : bit;		
signal ciL2Hit					 : bit;
signal cdL2Hit					 : bit;

begin
	
cdataL2Hit <= cdL2Hit;
cinstL2Hit <= ciL2Hit;
	
L2_UC : cacheL2Control port map(clk, vbDataIn, vbAddr, vbReady, cdRW, cdEnable, cdL2Hit, ciRW, ciEnable, ciL2Hit,
													      dirtyBit, hitSignal, writeOptions, addrOptions, updateInfo, memReady, memRW, memEnable);


L2_FD : cacheL2Path port map(writeOptions, addrOptions, updateInfo, ciL2Hit, cdL2Hit, hitSignal, dirtyBit, vbDataIn, vbAddr, dirtyData, cdAddr,
							  cdDataOut, ciAddr, ciDataOut, memBlockIn, memAddr, memBlockOut);




end archi;
