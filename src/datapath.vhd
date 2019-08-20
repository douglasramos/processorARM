-- PCS3412 - Organizacao e Arquitetura de Computadores II
-- PicoMIPS
-- Authors: Douglas Ramos , Rafael Higa ...
-- Processador ARM
--
-- Description:
--     Fluxo de dados do processador ARM

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_bit.all;


entity datapath is

  port(

    clock :             in bit;
    reset :   		    in bit;
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



--- sinais internos
signal iPcIn: bit_vector(63 downto 0);
signal iPcOut: bit_vector(63 downto 0);
signal iInstruction: bit_vector(31 downto 0);
signal iSignalExtended: bit_vector(63 downto 0);
signal iShiftleft2Out: bit_vector(63 downto 0);


--- sinais do add2	  
signal iAdd1Out: bit_vector(63 downto 0);
signal iAdd2Out: bit_vector(63 downto 0);
signal iAdd1OutSigned: signed(63 downto 0);
signal iAdd2OutSigned: signed(63 downto 0);
signal iZeroFlagAdd2: bit;
signal iZeroFlagAdd1: bit;
signal iZeroFlagUla: bit;

signal iReadData1: bit_vector(63 downto 0);
signal iMux1Out: bit_vector(63 downto 0);
signal iAluResult: bit_vector(63 downto 0);
signal iAluResultSigned: signed(63 downto 0);
signal iReadRegister2:  bit_vector(5 downto 0);
signal iReadData2: bit_vector(63 downto 0);
signal iDataMemoryOut: bit_vector(63 downto 0);
signal iWriteData: bit_vector(63 downto 0);

------------------------------------------------------------

begin


pc: reg port map (clock, reset, clock, iPcIn, iPCOut);

instructionMemory: rom port map (iPCOut, iInstruction);

mux1: mux2to1 generic map(5) port map(reg2loc, iInstruction(20 downto 16), iInstruction(4 downto 0), iReadRegister2);

dataMemory: ram port map(clock, memWrite, iAluResult, iDataMemoryOut);

signalExtend: signExtend port map (iInstruction, iSignalExtended);

shift: shiftleft2 port map (iSignalExtended,iShiftleft2Out);

add1: alu port map (signed(iPcOut), signed(x"0000000000000004"), iAdd1OutSigned, "0010", iZeroFlagAdd1);

add2: alu port map (signed(iPcOut), signed(iShiftleft2Out), iAdd2OutSigned,"0010", iZeroFlagAdd2);

mux2: mux2to1 generic map(64) port map(branch, iAluResult, iAdd2Out, iPcIn);

mux3: mux2to1 generic map(64) port map(memToReg, iAdd1Out, iDataMemoryOut, iWriteData);

aluEx: alu port map (signed(iDataMemoryOut), signed(iMux1Out), iAluResultSigned, aluCtl, iZeroFlagUla);


-- TODO: Testar e converter de volta os sinais signed

--- Saidas

instruction31to21 <= iInstruction(31 downto 21);


end datapath_arch;