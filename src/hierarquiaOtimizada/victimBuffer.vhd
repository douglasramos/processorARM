-- PCS3422 - Organiza��o e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Victim Buffer (TopLevel)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto

use types.all;


entity victimBuffer is
    generic (
        accessTime: in time := 5 ns
    );
    port (
		clk 			   		   : in bit;
		queueInst		           : in  bit;
		queueData		           : in  bit;
		readyL2			   		   : in  bit;
		evictedBlockData		   : in  word_vector_type(1 downto 0);		-- Um bloco, 2 words
		evictedBlockDataAddress	   : in  bit_vector(9 downto 0);
		evictedBlockDataDirty	   : in  bit;
		evictedBlockInst		   : in  word_vector_type(1 downto 0);		-- Um bloco, 2 words
		evictedBlockInstAddress	   : in  bit_vector(9 downto 0);
		evictedBlockInstDirty	   : in bit := '0';						    -- Instru��o n�o tem write!
		blockOut  	  			   : out word_vector_type(1 downto 0);     -- Sa�da do buffer: um bloco
		blockOutAddress			   : out bit_vector(9 downto 0);
		blockOutIsDirty			   : out bit
    );
end entity victimBuffer;

architecture victimBuffer_arch of victimBuffer is

component victimBufferControl is
    port (
		-- I/O relacionados ao stage IF
		clk				   : in  bit;
        queueInst		   : in  bit;
		queueData		   : in  bit;
		readyL2			   : in  bit;
		queueBlockData	   : out bit;
		queueBlockInst     : out bit;
		readyRead		   : out bit
    );
end component;

component victimBufferPath is
    generic (
		accessTime	   : in time := 5 ns;
		bufferLength   : natural := 5	  						-- Tamanho do Buffer
    );
    port (
	   	queueBlockData			   : in  bit;
		queueBlockInst       	   : in  bit;
		readyRead			       : in  bit;
		evictedBlockData		   : in  word_vector_type(1 downto 0);		-- Um bloco, 32 words
		evictedBlockDataAddress	   : in  bit_vector(9 downto 0);
		evictedBlockDataDirty	   : in  bit;
		evictedBlockInst		   : in  word_vector_type(1 downto 0);		-- Um bloco, 32 words
		evictedBlockInstAddress	   : in  bit_vector(9 downto 0);
		evictedBlockInstDirty	   : in  bit;
		blockOut  	  			   : out word_vector_type(1 downto 0);     -- Sa�da do buffer: um bloco
		blockOutAddress			   : out bit_vector(9 downto 0);
		blockOutIsDirty			   : out bit
    );
end component;


signal queueBlockData, queueBlockInst: bit;
signal readyRead		  			 : bit;

begin

	VBUC : victimBufferControl port map(clk, queueInst, queueData, readyL2, queueBlockData, queueBlockInst, readyRead);

	VBDatapath : victimBufferPath generic map(accessTime) port map(queueBlockData, queueBlockInst, readyRead,evictedBlockData,
																evictedBlockDataAddress, evictedBlockDataDirty, evictedBlockInst, evictedBlockInstAddress,
																evictedBlockInstDirty, blockOut, blockOutAddress, blockOutIsDirty);
end victimBuffer_arch;
