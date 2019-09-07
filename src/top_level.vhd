library ieee;
use ieee.std_logic_1164.ALL;

entity top_level is
	port(
		clk			    : in bit;
		reset			: in bit;
		instruction     : in bit_vector (31 downto 0)
	);
end top_level;

architecture toplevel of top_level is 

component controlModules is
  port (  
  	 clk			   : in  bit; 
  	 reset			   : in  bit;
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
end component;
													
component datapath is
  port(
    clock             : in  bit;
    reset   		  : in  bit;
    reg2loc           : in  bit;
    uncondBranch      : in  bit;
    branch            : in  bit;
    memRead           : in  bit;
    memToReg          : in  bit;
    aluCtl            : in  bit_vector(3 downto 0);
    memWrite          : in  bit;
    aluSrc            : in  bit;
    regWrite          : in  bit;
    instruction31to21 : out bit_vector(10 downto 0);
    zero              : out bit
  );

end component;


signal instruction31to21 														   		 : bit_vector(10 downto 0);
signal aluop 			 														   		 : bit_vector(1 downto 0);
signal aluCtl																	   	     : bit_vector(3 downto 0);
signal reg2loc, uncondBranch, branch, memRead,memToReg, memWrite, aluSrc, regWrite, zero : bit;	 


begin

unidades_controle : controlModules port map (clk, reset, instruction31to21, reg2loc, uncondBranch, branch, memRead, memToReg, memWrite, aluSrc, regWrite, aluCtl);

fluxo_de_dados 	: datapath port map(clk, reset, reg2loc, uncondBranch, branch, memRead, memToReg, aluCtl, memWrite, aluSrc, regWrite, instruction31to21, zero);

--OBS: Notar que as portas lógicas em azul no desenho do fluxo de dados tiveram que ser implementadas no fluxo de dados
--e não na UC ou no top level, caso contrário, deveria haver um sinal SEL para o multiplexador 3 (vide datapath.vhd)
--como "in bit" na interface da entity do fluxo de dados. Para não comprometer essa definição, dada no enunciado do problema
--proposto, optou-se por implementar as portas no fluxo de dados mesmo!

end toplevel;