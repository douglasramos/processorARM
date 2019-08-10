-- PCS3412 - Organizacao e Arquitetura de Computadores II
-- PicoMIPS
-- Authors: Douglas Ramos , Rafael Higa ...
-- Processador ARM 
--
-- Description:
--     Fluxo de dados do processador ARM

library IEEE;
use IEEE.std_logic_1164.all;


entity datapath is

  port(

    clock :             in bit;
    reset :   		      in bit;
    reg2loc :           in bit;
    uncondBranch :      in bit;
    branch:             in bit;
    memRead:            in bit;
    memToReg:           in bit;
    aluCtl:             in bit_vector(3 downto 0);
    memWrite:           in bit;
    aluSrc:             in bit;
    regWrite:           in bit;
    instruction31to21 : out bit_vector(10 downto 0);
    zero: out bit

  );

end entity datapath;

architecture datapath_arch of datapath is 

------------------------------------------------------------
------------------------ ALU ---------------------------
component alu is
  port (
    A, B : in  signed(63 downto 0); -- inputs
    F    : out signed(63 downto 0); -- output
    S    : in  bit_vector (3 downto 0); -- op selection
    Z    : out bit -- zero flag
    );
end component;

------------------------------------------------------------
------------------------ MUX2to1 ---------------------------
component mux2to1 is
	generic(ws: natural := 32); -- word size
	port(
		s:    in  bit; -- selection: 0=a, 1=b
		a, b: in	bit_vector(ws-1 downto 0); -- inputs
		o:  	out	bit_vector(ws-1 downto 0)  -- output
	);
end component;

------------------------------------------------------------
------------------------ ram ---------------------------
component ram is
  generic (
    addressSize : natural := 64;
    wordSize    : natural := 64
  );
  port (
    ck, wr : in  bit;
    addr   : in  bit_vector(addressSize-1 downto 0);
    data_i : in  bit_vector(wordSize-1 downto 0);
    data_o : out bit_vector(wordSize-1 downto 0)
  );
end component;

------------------------------------------------------------
------------------------ reg ---------------------------
component reg is
	generic(wordSize: natural :=64);
	port(
		clock:    in 	bit; --! entrada de clock
		reset:	 in 	bit; --! clear assíncrono
		load:     in 	bit; --! write enable (carga paralela)
		d:   		 in	bit_vector(wordSize-1 downto 0); --! entrada
		q:  		 out	bit_vector(wordSize-1 downto 0) --! saída
	);
end component;

------------------------------------------------------------
------------------------ rom ---------------------------
component rom is
  generic (
    addressSize : natural := 64;
    wordSize    : natural := 32;
    mifFileName : string  := "rom.dat"
  );
  port (
    addr : in  bit_vector(addressSize-1 downto 0);
    data : out bit_vector(wordSize-1 downto 0)
  );
end component;

------------------------------------------------------------
------------------------ shiftlef2 ---------------------------
component shiftleft2 is
	generic(
		ws: natural := 64); -- word size
	port(
		i: in	 bit_vector(ws-1 downto 0); -- input
		o: out bit_vector(ws-1 downto 0)  -- output
	);
end component;

------------------------------------------------------------
------------------------ signExtend ---------------------------
component signExtend is
	-- Size of output is expected to be greater than input
	generic(
	  ws_in:  natural := 32; -- input word size
		ws_out: natural := 64); -- output word size
	port(
		i: in	 bit_vector(ws_in-1  downto 0); -- input
		o: out bit_vector(ws_out-1 downto 0)  -- output
	);
end component;




--- sinais de ligacao entre controle do cache e o fluxo de dados do mesmo
signal i_write_options: std_logic_vector(1 downto 0);
signal i_mem_write: std_logic;
signal i_hit: std_logic;
signal i_update_info: std_logic;
signal i_dirty_bit: std_logic;

--- sinais de memoria (deveriam vir de fora)
signal i_mem_ready: std_logic;
signal i_mem_rw: std_logic;
signal i_mem_enable: std_logic;

signal i_mem_block_in: word_vector_type(15 downto 0);
signal i_mem_addr: std_logic_vector(15 downto 0);
signal i_mem_block_out: word_vector_type(15 downto 0);

--- sinais de blevers
signal iPcIn: bit_vector(31 downto 0);
signal iPcOut: bit_vector(31 downto 0);

--- sinais de blevers 2
signal iInstruction: bit_vector(31 downto 0);

signal
------------------------------------------------------------

begin			

	
pc: reg port map (clock, reset, clock, iPcIn, iPCOut);

instructionMemory: rom port map (iPCOut, iInstruction);

mux1: mux2to1 port map(reg2loc, iInstruction(20 downto 16), iInstruction(4 downto 0));

dataMemory: ram port map (iPCOut,);

signExtend: 
												  

--- Saidas

instruction31to21 <= iInstruction(31 downto 21);												  
												  
												  
												  
end datapath_arch;