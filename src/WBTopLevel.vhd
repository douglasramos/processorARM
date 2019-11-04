-- PCS3422 - Organização e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Write Buffer (TopLevel)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto

use types.all;


entity WBTopLevel is
    generic (
		accessTime: in time := 5 ns;
		bufferLength: natural := 20
    );
    port (			  
		clk   			  : in bit;  
		queue 			  : in bit;
		read              : in bit;
		blockIn		      : in  word_vector_type(31 downto 0);
		blockInAddress	  : in bit_vector(63 downto 0); 
		blockIn_InstAddr  : in bit;	
		blockOut		  : out word_vector_type(31 downto 0);
		blockOutAddress	  : out bit_vector(63 downto 0);
		blockOut_InstAddr : out bit
    );
end entity WBTopLevel;

architecture archi of WBTopLevel is	 	  

component WBControl is
    port (
		-- I/O relacionados ao stage IF
		clk				   : in  bit;
        queue			   : in  bit;
		read			   : in  bit;
		queueControl	   : out bit;
		readReady		   : out bit
    );
end component;

component writeBuffer is
    generic (
		accessTime	   : in time := 5 ns;
		bufferLength   : natural := 20	  						-- Tamanho do Buffer
    );
    port (									 
		blockIn					   : in  word_vector_type(31 downto 0);
		blockInAddress			   : in bit_vector(63 downto 0); 
		blockIn_InstAddr		   : in bit;	
		blockOut				   : out word_vector_type(31 downto 0);
		blockOutAddress			   : out bit_vector(63 downto 0);
		blockOut_InstAddr		   : out bit;
		queueEnable				   : in  bit;
		readReady    			   : in  bit
    );
end component;

signal queueControl, readReady : bit;

begin
   
	WBUC	   : WBControl port map(clk, queue, read, queueControl, readReady);
	
	WBDatapath : writeBuffer generic map(accessTime, bufferLength) port map(blockIn, blockInAddress, blockIn_InstAddr, blockOut, blockOutAddress, blockOut_InstAddr, queueControl, readReady);
	
end archi;
   