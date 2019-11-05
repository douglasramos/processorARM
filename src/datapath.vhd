-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- PicoMIPS
-- Authors: Douglas Ramos , Rafael Higa ...
-- Processador ARM
--
-- Description:
--     Fluxo de dados do processador ARM

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_bit.all;

entity datapath is

  port(

    clock             : in bit;
    reset   		  : in bit;
    reg2loc           : in bit;
    uncondBranch      : in bit;
    branch            : in bit;
    memRead           : in bit;
    memToReg          : in bit;
    aluCtl            : in bit_vector(3 downto 0);
    memWrite          : in bit;
    aluSrc            : in bit;
    regWrite          : in bit;
    instruction31to21 : out bit_vector(10 downto 0);
    zero              : out bit

  );

end entity datapath;

architecture datapath_arch of datapath is

------------------------------------------------------------
--------------------------- ALU ----------------------------
component alu is
  port (
    A, B   : in  signed(63 downto 0); -- inputs
  	isCBNZ : in bit;
    F      : out signed(63 downto 0); -- output
    S      : in  bit_vector (3 downto 0); -- op selection
    Z      : out bit -- zero flag
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
-------------------------- ram -----------------------------
component ram is
  generic (
    addressSize : natural := 64;
    wordSize    : natural := 64
  );
  port (
    ck, wr, rd : in  bit;
    addr   	   : in  bit_vector(addressSize-1 downto 0);
    data_i     : in  bit_vector(wordSize-1 downto 0);
    data_o     : out bit_vector(wordSize-1 downto 0)
  );
end component;

------------------------------------------------------------
---------------------------- reg ---------------------------
component reg is
  generic(wordSize: natural := 64);
  port(
    clock  : in  bit; -- entrada de clock
    reset  : in  bit; -- clear assíncrono
    load   : in  bit; -- write enable (carga paralela)
    d      : in  bit_vector(wordSize-1 downto 0); -- entrada
    q      : out bit_vector(wordSize-1 downto 0) -- saída
  );
end component;

------------------------------------------------------------
--------------------------- rom ----------------------------
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
------------------------ shiftlef2 -------------------------
component shiftleft2 is
  generic(
    ws : natural := 64); -- word size
  port(
    i : in	 bit_vector(ws-1 downto 0); -- input
    o : out  bit_vector(ws-1 downto 0)  -- output
  );
end component;

------------------------------------------------------------
------------------------ signExtend ------------------------
component signExtend is
  -- Size of output is expected to be greater than input
  generic(
    ws_in  : natural := 32; -- input word size
    ws_out : natural := 64); -- output word size
  port(
    i: in	 bit_vector(ws_in-1  downto 0); -- input
    o: out bit_vector(ws_out-1 downto 0)  -- output
  );
end component;

------------------------------------------------------------
---------------------- registerBank ------------------------
component registerBank is
  port(
    clk          : in  bit;
    writeEnable  : in  bit;
    readReg1Sel  : in  bit_vector(4 downto 0);
    readReg2Sel  : in  bit_vector(4 downto 0);
    writeRegSel  : in  bit_vector(4 downto 0);
    writeDateReg : in  bit_vector(63 downto 0);
    readData1    : out bit_vector(63 downto 0);
    readData2    : out bit_vector(63 downto 0)
  );
end component;



--- sinais do registrador pc
signal iPcIn: bit_vector(63 downto 0);
signal iPcOut: bit_vector(63 downto 0);

--- sinais do add1
signal iAdd1Out: bit_vector(63 downto 0);
signal iAdd1OutSigned: signed(63 downto 0);
signal iZeroFlagAdd1: bit;

--- sinais instructionMemory
signal iInstruction: bit_vector(31 downto 0);

--- sinais banco de registradores
signal iReadRegister2:  bit_vector(4 downto 0);
signal iReadData1: bit_vector(63 downto 0);
signal iReadData2: bit_vector(63 downto 0);

--- sinais do signal extended
signal iSignalExtended: bit_vector(63 downto 0);

--- siinais do shift
signal iShiftleft2Out: bit_vector(63 downto 0);

--- sinais do add2
signal iAdd2Out: bit_vector(63 downto 0);
signal iAdd2OutSigned: signed(63 downto 0);
signal iZeroFlagAdd2: bit;


--- sinais dos muxs
signal iMux1Out: bit_vector(63 downto 0);
signal iMux2Out: bit_vector(63 downto 0);
signal iMux4Out: bit_vector(63 downto 0);

--- sinais da ula
signal iZeroFlagUla: bit;
signal iAluResult: bit_vector(63 downto 0);
signal iAluResultSigned: signed(63 downto 0);

--- sinais do dataMemory
signal iDataMemoryOut: bit_vector(63 downto 0);


signal mux3Sel : bit;
signal ZeroBranch : bit;
signal isCBNZ : bit;
signal Instru3121 : bit_vector(10 downto 0);
------------------------------------------------------------

begin

pc: reg port map (clock, reset, '1', iPcIn, iPCOut);

add1: alu port map (signed(iPcOut), signed(x"0000000000000004"), '0', iAdd1OutSigned, "0010", iZeroFlagAdd1);

instructionMemory: rom port map (iPCOut, iInstruction);

regBank: registerBank port map(clock, regWrite, iInstruction(9 downto 5), iReadRegister2, iInstruction(4 downto 0), iMux4Out, iReadData1, iReadData2);

mux1: mux2to1 generic map(5) port map(reg2loc, iInstruction(20 downto 16), iInstruction(4 downto 0), iReadRegister2);

signalExtend: signExtend port map (iInstruction, iSignalExtended);

shift: shiftleft2 port map (iSignalExtended,iShiftleft2Out);

add2: alu port map (signed(iPcOut), signed(iShiftleft2Out), '0', iAdd2OutSigned,"0010", iZeroFlagAdd2);

mux2: mux2to1 generic map(64) port map(aluSrc, iReadData1, iSignalExtended, iMux2Out);

aluEx: alu port map (signed(iDataMemoryOut), signed(iMux2Out), isCBNZ, iAluResultSigned, aluCtl, iZeroFlagUla);

dataMemory: ram port map(clock, memWrite, memRead, iAluResult, iDataMemoryOut);

--- TODO
------------------------------------------------------------------------------------------------------------
--Mux 3
mux3Sel <= (branch and ZeroBranch) or uncondBranch;
mux3: mux2to1 generic map(64) port map(mux3Sel, iAdd1Out, iAdd2Out, iPcIn);

isCBNZ <= '1' when Instru3121(10 downto 3) = "01011010" else '0';
ZeroBranch <= iZeroFlagUla xor isCBNZ;

--OBS: Notar que essas portas l�gicas tiveram de
--ser implementadas AQUI, e n�o na UC ou no top level, pois sen�o
--deveria haver um signal "in bit" na interface do FD como SEL do mux3 aqui representado. Como isso n�o foi definido, optou-se por implementar as portas no fluxo de dados mesmo!

------------------------------------------------------------------------------------------------------------
--Mux 4
mux4: mux2to1 generic map(64) port map(memToReg, iAluResult, iDataMemoryOut, iMux4Out);

------------------------------------------------------------------------------------------------------------

--- Conversao de signed to bit_vector
iAdd1Out <= bit_vector(iAdd1OutSigned);
iAdd2Out <= bit_vector(iAdd2OutSigned);
iAluResult <= bit_vector(iAluResultSigned);

--- Saidas
Instru3121 <= iInstruction(31 downto 21);
instruction31to21 <= Instru3121;
zero <= ZeroBranch;

end datapath_arch;