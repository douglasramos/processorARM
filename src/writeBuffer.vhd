-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- ARM		 
--
-- Description:
--     Write Buffer
	
library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto

use types.all; -- 1 word, 32 bits

entity writeBuffer is
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
end writeBuffer;
		
		
architecture archi of writeBuffer is	 	  

	constant palavrasPorBloco: positive := 32;
	constant blocoSize:        positive := palavrasPorBloco * 4; --- 16 * 4 = 64Bytes  1 word = 4 bytes
	
	type RowType is record
        valid    : bit;
        addr     : bit_vector(63 downto 0);
		instAddr : bit;
        data     : word_vector_type(palavrasPorBloco - 1 downto 0);
    end record RowType;
	
	type bufferType is array (bufferLength-1 downto 0) of RowType;       
	
	signal bufferData : bufferType;  	

	   
	constant buffer_row_cleared : RowType := (valid    => '0',
        						  			  addr     => (others => '0'),
											  instAddr => '0',
        									  data     => (others => word_vector_init));
					
											  
	
	
	
begin
	
	
	process(queueEnable, readReady)
		variable dequeueStop : natural := 0; 	
		variable stopQueuing : natural := 0; 
	
	begin	
		-------------------------------------------------------------------------------------------------------
		--Queue by request
		if(queueEnable'event and queueEnable = '1' and readReady = '0') then 
			stopQueuing := 0;
			queueLoop : for i in 0 to bufferLength-1 loop	
				if(bufferData(i) = buffer_row_cleared and stopQueuing = 0) then
					bufferData(i).data     <= blockIn;
					bufferData(i).addr     <= blockInAddress;
					bufferData(i).instAddr <= blockIn_InstAddr;
					bufferData(i).valid    <= '1';
					stopQueuing := 1;
				end if;
			end loop queueLoop;
		end if;										
		-------------------------------------------------------------------------------------------------------
		--Dequeue by request
		if(readReady'event and readReady = '1' and queueEnable = '0') then
			
			blockOut          <= bufferData(0).data;	  
			blockOutAddress   <= bufferData(0).addr;
			blockOut_InstAddr <= bufferData(0).instAddr;
			
			dequeueLoop : for i in 0 to bufferLength-2 loop
				bufferData(i) <= bufferData(i+1);	
			end loop dequeueLoop;								 
			bufferData(bufferLength-1) <= buffer_row_cleared;
		end if;
		-------------------------------------------------------------------------------------------------------
		
	end process;
	
end archi;