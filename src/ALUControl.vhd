library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;


entity ALUControl is
  port (  
  		instruction31to21  : in  bit_vector(10 downto 0);
  		aluop			   : in  bit_vector(1 downto 0);
		aluCtl			   : out bit_vector(3 downto 0)  
  );
end ALUControl;

architecture ALUControl of ALUControl is

begin

	
	aluCtl <= "0010" when aluop = "10" and instruction31to21 = "10001011000" else
			  "0110" when aluop = "10" and instruction31to21 = "11001011000" else
			  "0000" when aluop = "10" and instruction31to21 = "10001010000" else
			  "0001" when aluop = "10" and instruction31to21 = "10101010000" else
			  "0010" when aluop = "00" else
			  "0111" when aluop = "01" else
			  "0000";  
	   
	
end ALUControl;
