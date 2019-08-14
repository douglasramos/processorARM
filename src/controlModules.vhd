------------------------------------------------------------------------------------------------------
--UC do monociclo
------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;


entity controlUnit is
  port (  
  	 instruction31to21 : in  bit_vector(10 downto 0);
     reg2loc 	 	   : out bit;	 
     uncondBranch 	   : out bit;								 
     branch		  	   : out bit;					  
     memRead	  	   : out bit;			  
     memToReg	  	   : out bit;	  
     memWrite	  	   : out bit;				  
     aluSrc		  	   : out bit;	  
     regWrite	  	   : out bit;
	 aluop			   : out bit_vector(1 downto 0)
  );
end controlUnit;

architecture controlUnit of controlUnit is
signal Rinst     : bit;	 
signal LDUR      : bit;
signal STUR      : bit;
signal CBZ       : bit;
signal I         : bit_vector(10 downto 0);
signal B, BL, BR : bit;

begin
	I <= instruction31to21;
	
	Rinst    <= I(10) and (not I(7)) and I(6) and (not I(5)) and I(4) and (not I(2)) and (not I(1)) and (not I(0));
	LDUR     <= '1' when I = "11111000010" 			 else '0';
	STUR     <= '1' when I = "11111000000" 			 else '0';
	CBZ      <= '1' when I(10 downto 3) = "10110100" else '0';
	B        <= '1' when I(10 downto 5) = "000101"   else '0';
	BL       <= '1' when I(10 downto 5) = "100101"   else '0';
	BR       <= '1' when I = "11010110000"			 else '0';
		
	reg2loc 	 <= '1' when STUR  = '1' or CBZ = '1'  		   else '0';
	uncondBranch <= '1' when B = '1' or BL = '1' or BR = '1'   else '0';
	branch       <= '1' when CBZ   = '1'                 	   else '0';
	memRead		 <= '1' when LDUR  = '1' 			   		   else '0'; 
	memToReg	 <= '1' when LDUR  = '1' 			   		   else '0'; 
	memWrite	 <= '1' when STUR  = '1' 			   		   else '0';
	aluSrc  	 <= '1' when LDUR  = '1' or STUR = '1' 		   else '0';
	regWrite	 <= '1' when Rinst = '1' or LDUR = '1' 		   else '0';
	aluop(1)     <= '1' when Rinst = '1' 			   		   else '0';
	aluop(0)     <= '1' when CBZ   = '1' 			           else '0';
		
	
end controlUnit;

------------------------------------------------------------------------------------------------------
--UC da ULA
------------------------------------------------------------------------------------------------------
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
signal I : bit_vector(10 downto 0);

begin

	
	process(I,aluop)
	begin
		if(aluop = "10") then
			if(I = "10001011000") then 	   --add
				aluCtl <= "0010";
			elsif(I = "11001011000") then  --sub
				aluCtl <= "0110";
			elsif(I = "10001010000") then  --and
				aluCtl <= "0000";
			elsif(I = "10101010000") then  --or
				aluCtl <= "0001";
			end if;				 
		elsif(aluop = "00") then
			aluCtl <= "0010";
		elsif(aluop = "01") then
			aluCtl <= "0111";
		else
			aluCtl <= "0000";
		end if;
		
	end process;

	I <= instruction31to21;	   
	
end ALUControl;


------------------------------------------------------------------------------------------------------
--entity que instancia os dois
------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;


entity controlModules is
  port (  
  	 instruction31to21 : in  bit_vector(10 downto 0);
     reg2loc 	 	   : out bit;	 
     uncondBranch 	   : out bit;								 
     branch		  	   : out bit;					  
     memRead	  	   : out bit;			  
     memToReg	  	   : out bit;	  
     memWrite	  	   : out bit;				  
     aluSrc		  	   : out bit;	  
     regWrite	  	   : out bit;
	 aluCtl			   : out bit_vector(3 downto 0) 
  );
end controlModules;

architecture controlModules of controlModules is

component controlUnit is
  port (  
  	 instruction31to21 : in  bit_vector(10 downto 0);
     reg2loc 	 	   : out bit;	 
     uncondBranch 	   : out bit;								 
     branch		  	   : out bit;					  
     memRead	  	   : out bit;			  
     memToReg	  	   : out bit;	  
     memWrite	  	   : out bit;				  
     aluSrc		  	   : out bit;	  
     regWrite	  	   : out bit;
	 aluop			   : out bit_vector(1 downto 0)
  );
end component;

component ALUControl is
  port (  
  		instruction31to21  : in  bit_vector(10 downto 0);
  		aluop			   : in  bit_vector(1 downto 0);
		aluCtl			   : out bit_vector(3 downto 0)  
  );
end component;

signal aluop : bit_vector(1 downto 0);

begin															
	
	UC : controlUnit port map(instruction31to21, reg2loc, uncondBranch, branch, memRead, memToReg, memWrite, aluSrc, regWrite, aluop);
	
	
	UCULA : ALUControl port map(instruction31to21, aluop, aluCtl);
	
	
end controlModules;	