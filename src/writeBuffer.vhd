-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- ARM		 
--
-- Description:
--     Write Buffer
	
library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto

use types.all; -- 1 word, 32 bits

entity victimBuffer is
    generic (
		accessTime	   : in time := 5 ns;
		bufferLength   : natural := 20	  						-- Tamanho do Buffer
    );
    port (									 
		blockIn					   : in  word_vector_type(31 downto 0);
		blockInTag				   : in bit_vector(49 downto 0);
		blockInIndex			   : in bit_vector(6 downto 0);
		blockOut				   : out word_vector_type(31 downto 0);
		blockOutTag				   : out bit_vector(49 downto 0);
		blockOutIndex			   : out bit_vector(6 downto 0);
		queueEnable				   : in  bit;
		dequeueEnable			   : in  bit;
		clearBuffer				   : in  bit;
		isFullBuffer   			   : out bit;
		isEmptyBuffer			   : out bit			 --para dizer que um dequeue não adianta nada
    );
end victimBuffer;
		
		
architecture archi of victimBuffer is	 	  

	constant palavrasPorBloco: positive := 32;
	constant blocoSize:        positive := palavrasPorBloco * 4; --- 16 * 4 = 64Bytes  1 word = 4 bytes
	
	type RowType is record
        valid : bit;
        tag   : bit_vector(49 downto 0);
		index : bit_vector(6 downto 0);
        data  : word_vector_type(palavrasPorBloco - 1 downto 0);
    end record RowType;
	
	type bufferType is array (bufferLength-1 downto 0) of RowType;       
	
	signal bufferData : bufferType;  	

	   
	constant buffer_row_cleared : RowType := (valid => '0',
										      tag   => (others => '0'),
											  data  => (others => word_vector_init),
											  index => (others => '0'));
											  
	signal isEmpty : bit;
	
begin
	
	
isFullBuffer <= '1' when bufferData(bufferLength - 1) /= buffer_row_cleared else '0';
isEmpty      <= '1' when bufferData(0) = buffer_row_cleared else '0';
isEmptyBuffer <= isEmpty;	  

	process(clearBuffer, queueEnable, dequeueEnable)
		variable dequeueStop : natural := 0; 	
		variable stopQueuing : natural := 0;
	
	begin	
		-------------------------------------------------------------------------------------------------------
		--Clear
		if(clearBuffer'event and clearBuffer = '1') then
			bufferData <= (others => buffer_row_cleared);	
		end if;
		
		-------------------------------------------------------------------------------------------------------
		--Queue by request
		if(queueEnable'event and queueEnable = '1' and dequeueEnable = '0') then 
			stopQueuing := 0;
			queueLoop : for i in 0 to bufferLength-1 loop	
				if(bufferData(i) = buffer_row_cleared and stopQueuing = 0) then
					bufferData(i).data  <= blockIn;
					bufferData(i).tag   <= blockInTag;
					bufferData(i).index <= blockInIndex;
					bufferData(i).valid <= '1';
					stopQueuing := 1;
				end if;
			end loop queueLoop;
		end if;										
		-------------------------------------------------------------------------------------------------------
		--Dequeue by request
		if(dequeueEnable'event and dequeueEnable = '1' and queueEnable = '0') then
			
			blockOut      <= bufferData(0).data;	  
			blockOutTag   <= bufferData(0).tag;
			blockOutIndex <= bufferData(0).index;
			
			dequeueLoop : for i in 0 to bufferLength-2 loop
				bufferData(i) <= bufferData(i+1);	
			end loop dequeueLoop;								 
			bufferData(bufferLength-1) <= buffer_row_cleared;
		end if;
		-------------------------------------------------------------------------------------------------------
		--Queue AND Dequeue juntos
		if(dequeueEnable'event and dequeueEnable = '1' and queueEnable'event and queueEnable = '1') then
			
			blockOut      <= bufferData(0).data;	  
			blockOutTag   <= bufferData(0).tag;
			blockOutIndex <= bufferData(0).index;
			
			dequeueLoop2 : for i in 0 to bufferLength-2 loop
				bufferData(i) <= bufferData(i+1);	
			end loop dequeueLoop2;								 
			bufferData(bufferLength-1) <= buffer_row_cleared;
		
			if(isEmpty = '0') then
				stopQueuing := 0;
					queueLoop2 : for i in 1 to bufferLength-1 loop	
						if(bufferData(i) = buffer_row_cleared and stopQueuing = 0 and isEmpty = '0') then
							bufferData(i-1).data  <= blockIn;
							bufferData(i-1).tag   <= blockInTag;
							bufferData(i-1).index <= blockInIndex;
							bufferData(i-1).valid <= '1';
							stopQueuing := 1;
						end if;
					end loop queueLoop2;
			else   
				bufferData(0).data  <= blockIn;
				bufferData(0).tag   <= blockInTag;
				bufferData(0).index <= blockInIndex;
				bufferData(0).valid <= '1';
			end if;
		end if; 
	end process;
	
end archi;