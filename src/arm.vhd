library ieee;
use ieee.std_logic_1164.ALL;

entity top_level is
	port(
		clk			: in bit;
		reset			: in bit;
		instruction : in bit_vector (31 downto 0)
	);
end top_level;

architecture toplevel of top_level is 

component controlModules is
	generic(ws: natural := 4); -- word size
	port(
		clk						: in bit;
		reset						: in bit;
		instruction31to21 	: in bit_vector (10 downto 0);
		zero						: in bit;
		
		reg2Loc			: out bit;
		uncondBranch	: out bit;
		branch			: out bit;
		memToReg			: out bit;
		memRead			: out bit;
		memWrite			: out bit;
		aluCtl			: out bit_vector (3 downto 0);
		aluSrc			: out bit;
		regWrite			: out bit
	);
end component;

component datapath is

  port(

    clock : in bit;
    reset : in bit;
    reg2Loc : in bit;
    uncondBranch : in bit;
    branch: in bit;
    memRead: in bit;
    memToReg: in bit;
    aluCtl: in bit_vector(3 downto 0);
    memWrite: in bit;
    aluSrc: in bit;
    regWrite: in bit;
    instruction31to21: out bit_vector(10 downto 0);
    zero: out bit

  );

end component;

signal iInstruction31to21 	: bit_vector (10 downto 0);
signal iZero						:  bit;	
signal iReg2Loc			:  bit;
signal iUncondBranch	:  bit;
signal iBranch			:  bit;
signal iMemToReg			:  bit;
signal iMemRead			:  bit;
signal iMemWrite			:  bit;
signal iAluCtl			:  bit_vector (3 downto 0);
signal iAluSrc			:  bit;
signal iRegWrite			:  bit;

begin



unidadde_controle : controlModules port map (
		clk,						
		reset,
		iInstruction31to21,
		iZero,
		iReg2Loc,			
		iUncondBranch,	
		iBranch,			
		iMemToReg,			
		iMemRead,			
		iMemWrite,			
		iAluCtl,
		iAluSrc,
		iRegWrite
);


fluxo_de_dados 	: datapath port map(
		clk,
		reset,
		iReg2Loc,
		iUncondBranch,
		iBranch,
		iMemRead,
		iMemToReg,
		iAluCtl,
		iMemWrite,
		iAluSrc,
		iRegWrite,
		iInstruction31to21,
		iZero
		
);

end toplevel;