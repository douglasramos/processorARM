--------------------------------------------------------------------------------
-- PCS3412 - Organização e Arquitetura de Computadores II
--
-- Authors: Grupo A - Rafael Higa
-- Processador ARM
--
-- Description:
--		Fluxo de dados com Pipeline
-- Conteúdo
--	-Entity "datapath": pipeline inteiro
--	-Entity "IFID"    : Buffer IF/ID
--	-Entity "IDEX"    :	Buffer ID/EX
--  -Entity "EXMEM"   : Buffer EX/MEM
--  -Entity "MEMWB"   : Buffer MEM/WB	
--------------------------------------------------------------------------------

--=============================================================================================================================

--------------------------------------------------------------------------------------------------------------------Datapath
--==============================================================================  									==========
--Datapath
--==============================================================================
--------------------------------------------------------------------------------
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

--===========================================================================================
--===========================================================================================
--Declaração de components
--===========================================================================================
--===========================================================================================

------------------------------------------------------------
--------------------------- ALU ----------------------------
	component alu is
  	port (
	    A, B   : in  signed(63 downto 0); -- inputs
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
    	ck, wr     : in  bit;
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
    	reset  : in  bit; -- clear assÃ­ncrono
    	load   : in  bit; -- write enable (carga paralela)
    	d      : in  bit_vector(wordSize-1 downto 0); -- entrada
	    q      : out bit_vector(wordSize-1 downto 0) -- saÃ­da
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

------------------------------------------------------------
---------------------- buffer IF/ID ------------------------

	component IFID is
  	port(				
	  	clk					   : in  bit;
	  	reset				   : in  bit;
  		In_currentPC 		   : in  bit_vector(31 downto 0);
	  	In_fetchedInstruction  : in  bit_vector(31 downto 0);
		Out_currentPC 		   : out bit_vector(31 downto 0);
		Out_fetchedInstruction : out bit_vector(31 downto 0)
  	);
	end component;

------------------------------------------------------------
---------------------- buffer ID/EX ------------------------

	component IDEX is
  	port(
  		clk 					 : in  bit;
	  	reset 					 : in  bit;
  		In_uncondbranch 		 : in  bit;
  		In_branch 				 : in  bit;
  		In_memRead 			 	 : in  bit;
  		In_memToReg 			 : in  bit;
  		In_memWrite 		 	 : in  bit;
  		In_aluSrc 			 	 : in  bit;
  		In_regWrite 			 : in  bit;				 
		In_aluCtl				 : in  bit_vector(3 downto 0);
  		In_currentPC 			 : in  bit_vector(31 downto 0);
  		In_ReadData1			 : in  bit_vector(63 downto 0);
  		In_ReadData2			 : in  bit_vector(63 downto 0);
  		In_SignExtend			 : in  bit_vector(63 downto 0);
  		In_Instruction31to21     : in  bit_vector(10 downto 0);
  		In_Instruction4to0	 	 : in  bit_vector (4 downto 0);
  		Out_uncondbranch 		 : out bit;
  		Out_branch 				 : out bit;
  		Out_memRead 			 : out bit;
  		Out_memToReg 			 : out bit;
  		Out_memWrite 			 : out bit;
  		Out_aluSrc 			 	 : out bit;
  		Out_regWrite 			 : out bit;
  		Out_aluCtl				 : out bit_vector(3 downto 0);
		Out_currentPC			 : out bit_vector(31 downto 0);
  		Out_ReadData1			 : out bit_vector(63 downto 0);
  		Out_ReadData2            : out bit_vector(63 downto 0);
  		Out_SignExtend		 	 : out bit_vector(63 downto 0);
  		Out_Instruction31to21  	 : out bit_vector(10 downto 0);
  		Out_Instruction4to0	 	 : out bit_vector (4 downto 0)
  		);
  
end component;

------------------------------------------------------------
---------------------- buffer EX/MEM -----------------------

	component EXMEM is
	  port(
  		clk 				     : in  bit;
  		reset 				     : in  bit;
  		In_uncondbranch 		 : in  bit;
  		In_branch 			     : in  bit;
  		In_memRead 			     : in  bit;
  		In_memToReg 			 : in  bit;
  		In_memWrite 		 	 : in  bit;
  		In_regWrite 			 : in  bit;	
		In_isCBNZ				 : in  bit;
  		In_PcSum				 : in  bit_vector (63 downto 0);	
  		In_ZeroFlag			     : in  bit;
  		In_AluResult			 : in  bit_vector (63 downto 0);
  		In_ReadData2			 : in  bit_vector (63 downto 0);
  		In_Instruction4to0       : in  bit_vector(4 downto 0);
  		Out_uncondbranch 		 : out bit;
  		Out_branch 			     : out bit;
  		Out_memRead 			 : out bit;
  		Out_memToReg 			 : out bit;
  		Out_memWrite 		 	 : out bit;
  		Out_regWrite 			 : out bit;
		Out_isCBNZ				 : out bit;
  		Out_PcSum				 : out bit_vector (63 downto 0);
  		Out_ZeroFlag			 : out bit;
  		Out_AluResult			 : out bit_vector (63 downto 0);
  		Out_ReadData2			 : out bit_vector (63 downto 0);
  		Out_Instruction4to0      : out bit_vector(4 downto 0)
  		);
		end component;

------------------------------------------------------------
---------------------- buffer MEM/WB -----------------------
	component MEMWB is
  	port(
  	clk 		   		  : in  bit;
  	reset  	   		  	  : in  bit;
  	In_regWrite  		  : in  bit;	 
  	In_memToReg  		  : in  bit;
  	In_ReadData  		  : in  bit_vector (63 downto 0);
  	In_Address		  	  : in  bit_vector (63 downto 0);
  	In_Instruction4to0    : in  bit_vector (4 downto 0);
  	Out_regWrite 		  : out bit;	 
  	Out_memToReg 		  : out bit;
  	Out_ReadData          : out bit_vector (63 downto 0);
  	Out_Address		      : out bit_vector (63 downto 0);
  	Out_Instruction4to0   : out bit_vector (4 downto 0)
  	);					 
	end component;

--===========================================================================================
--===========================================================================================
--Declaração de Signals
--===========================================================================================
--===========================================================================================


--- sinais instructionMemory
--- sinais banco de registradores
--- sinais do signal extended
--- siinais do shift
--- sinais do add2	
--- sinais dos muxs	 
--- sinais da ula	 
--- sinais do dataMemory

------------------------------------------------------------
--Estágio IF
	signal PCSrc 				   : bit;
	signal iAdd1OutSigned_32	   : bit_vector(31 downto 0);	 
	signal PC_De_longe_trocar_nome : bit_vector(31 downto 0);	 
	signal iPcIn				   : bit_vector(31 downto 0);
	signal iPCOut  		   		   : bit_vector(31 downto 0);
	signal iPcOutExtended		   : bit_vector(63 downto 0);
	signal iAdd1OutSigned		   : signed(63 downto 0);
	signal iZeroFlagAdd1		   : bit;
	signal iInstruction			   : bit_vector(31 downto 0);
	signal branchAdd			   : bit_vector (31 downto 0);
	
------------------------------------------------------------
--Buffer IF/ID
	signal  O_IFID_Instruction 		   : bit_vector(31 downto 0);		  
	signal  O_IFID_PcOut			   : bit_vector(31 downto 0);	
	
------------------------------------------------------------
--Estágio ID
	signal iReadRegister2		   : bit_vector(4  downto 0);
	signal iReadData1			   : bit_vector(63 downto 0);
	signal iReadData2			   : bit_vector(63 downto 0);
	signal iSignalExtended		   : bit_vector(63 downto 0);
	signal IDInstruction31to21 	   : bit_vector(31 downto 21);
	signal IDInstruction4to0 	   : bit_vector(4  downto 0);

------------------------------------------------------------
--Buffer ID/EX

	signal O_IDEX_uncondbranch, O_IDEX_branch, O_IDEX_memRead, O_IDEX_memWrite : bit;
	signal O_IDEX_aluSrc, O_IDEX_regWrite, O_IDEX_memToReg	   				   : bit;	  
	signal O_IDEX_currentPC													   : bit_vector(31 downto 0);
	signal O_IDEX_ReadData1			 										   : bit_vector(63 downto 0);
  	signal O_IDEX_ReadData2         										   : bit_vector(63 downto 0);
	signal O_IDEX_SignExtend 												   : bit_vector(63 downto 0);
	signal O_IDEX_Instruction31to21 									       : bit_vector(10 downto 0);
	signal O_IDEX_Instruction4to0 											   : bit_vector(4 downto 0);	
	signal O_IDEX_aluCtl													   : bit_vector(3 downto 0);
------------------------------------------------------------
--Estágio EX
 	signal PcToAdd 			: bit_vector(63 downto 0);
	signal iShiftleft2Out	: bit_vector(63 downto 0);
	signal iAdd2OutSigned	: signed(63 downto 0);
   	signal iMux2Out			: bit_vector(63 downto 0);
	signal iAluResultSigned	: signed(63 downto 0);
	signal isCBNZ 			: bit;
	signal iZeroFlagUla		: bit;
		
------------------------------------------------------------
--Buffer EX/MEM
	signal Oexmem_PcSum 														: bit_vector(63 downto 0);
	signal Oexmem_AluResult 												  	: bit_vector(63 downto 0);  
	signal Oexmem_Instruction4to0 												: bit_vector(4 downto 0);
	signal Oexmem_branch, Oexmem_memRead, Oexmem_memToReg, Oexmem_memWrite 		: bit;
	signal Oexmem_regWrite, Oexmem_isCBNZ, Oexmem_ZeroFlag, Oexmem_uncondbranch : bit;
	signal Oexmem_ReadData2 													: bit_vector(63 downto 0);

------------------------------------------------------------
--Estágio MEM
	signal iDataMemoryOut : bit_vector(63 downto 0);
	signal ZeroBranch 	  : bit;	 
	signal rwxor		  : bit;

------------------------------------------------------------
--Buffer MEM/WB

	signal Omemwb_regWrite, Omemwb_memToReg : bit;
	signal Omemwb_ReadData, Omemwb_Address 	: bit_vector(63 downto 0);
	signal Omemwb_Instruction4to0 			: bit_vector(4 downto 0);
	
------------------------------------------------------------
--Estágio WB
	signal iMux4Out: bit_vector(63 downto 0);


--===========================================================================================
--===========================================================================================
--begin
--===========================================================================================
--===========================================================================================

	begin																					
	
-------------------------------------------------------------------------------------------------------
--Estágio IF
-------------------------------------------------------------------------------------------------------

		iAdd1OutSigned_32 <= bit_vector(iAdd1OutSigned(31 downto 0));
		iPcOutExtended    <= "00000000000000000000000000000000" & iPcOut;
		branchAdd <= Oexmem_PcSum(31 downto 0);
		
		
		mux1_IF			 : mux2to1 generic map(32) port map(PCSrc, iAdd1OutSigned_32, branchAdd, iPcIn);

		pc				 : reg port map (clock, reset, '1', iPcIn, iPCOut);												   
		add1			 : alu port map (signed(iPcOutExtended), signed(x"0000000000000004"), iAdd1OutSigned, "0010", iZeroFlagAdd1);
		instructionMemory: rom port map (iPCOut, iInstruction);																 

-------------------------------------------------------------------------------------------------------
--Buffer IF/ID
-------------------------------------------------------------------------------------------------------

		buffer_IFID : IFID port map(clock, reset, iPCOut, iInstruction, O_IFID_PCOut, O_IFID_Instruction);	

-------------------------------------------------------------------------------------------------------
--Estágio ID
-------------------------------------------------------------------------------------------------------

		mux1: mux2to1 generic map(5) port map(reg2loc,  O_IFID_Instruction(20 downto 16),  O_IFID_Instruction(4 downto 0), iReadRegister2);
		regBank: registerBank port map(clock, Omemwb_regWrite,  O_IFID_Instruction(9 downto 5), iReadRegister2, Omemwb_Instruction4to0, iMux4Out, iReadData1, iReadData2);
		signalExtend: signExtend port map(O_IFID_Instruction, iSignalExtended);
							   
		IDInstruction31to21 <=  O_IFID_Instruction(31 downto 21);
		IDInstruction4to0   <=  O_IFID_Instruction(4  downto  0);
		
-------------------------------------------------------------------------------------------------------
--Buffer ID/EX
-------------------------------------------------------------------------------------------------------

		buffer_IDEX : IDEX port map(clock, reset, uncondbranch, branch, memRead, memToReg, memWrite, aluSrc, regWrite, aluCtl,  
							O_IFID_PCOut, iReadData1, iReadData2, iSignalExtended, IDInstruction31to21, IDInstruction4to0, 
							O_IDEX_uncondbranch, O_IDEX_branch, O_IDEX_memRead, O_IDEX_memToReg, O_IDEX_memWrite, O_IDEX_aluSrc, 
							O_IDEX_regWrite, O_IDEX_aluCtl, O_IDEX_currentPC, O_IDEX_ReadData1, O_IDEX_ReadData2, O_IDEX_SignExtend, 
							O_IDEX_Instruction31to21, O_IDEX_Instruction4to0);
  							   
-------------------------------------------------------------------------------------------------------
--Estágio EX
-------------------------------------------------------------------------------------------------------
		isCBNZ <= '1' when O_IDEX_Instruction31to21(10 downto 3) = "01011010" else '0';

		PcToAdd <= "00000000000000000000000000000000" & O_IDEX_currentPC;
		
		shift: shiftleft2 port map (O_IDEX_SignExtend,iShiftleft2Out);
		add2: alu port map (signed(PcToAdd), signed(iShiftleft2Out), iAdd2OutSigned,"0010", open);
		mux2: mux2to1 generic map(64) port map(O_IDEX_aluSrc, O_IDEX_ReadData2, O_IDEX_SignExtend, iMux2Out);
		aluEx: alu port map (signed(O_IDEX_ReadData1), signed(iMux2Out), iAluResultSigned, O_IDEX_aluCtl, iZeroFlagUla);
	
-------------------------------------------------------------------------------------------------------
--Buffer EX/MEM
-------------------------------------------------------------------------------------------------------
																													 	
		buffer_EXMEM : EXMEM port map(clock, reset, O_IDEX_uncondbranch, O_IDEX_branch, O_IDEX_memRead, O_IDEX_memToReg, 
									  O_IDEX_memWrite, O_IDEX_regWrite, isCBNZ, bit_vector(iAdd2OutSigned), iZeroFlagUla, 
									  bit_vector(iAluResultSigned), O_IDEX_ReadData2, 
								  	  O_IDEX_Instruction4to0,Oexmem_uncondbranch, Oexmem_branch, Oexmem_memRead, Oexmem_memToReg,
								  	  Oexmem_memWrite, Oexmem_regWrite, Oexmem_isCBNZ, Oexmem_PcSum, Oexmem_ZeroFlag, Oexmem_AluResult, 
								  	  Oexmem_ReadData2,	Oexmem_Instruction4to0
								  	  );

-------------------------------------------------------------------------------------------------------
--Estágio MEM
-------------------------------------------------------------------------------------------------------
		rwxor <= Oexmem_memWrite xor Oexmem_memRead;
		dataMemory: ram port map(clock, rwxor, Oexmem_AluResult, Oexmem_ReadData2, iDataMemoryOut);
	
		PCSrc <= (ZeroBranch and Oexmem_branch) or Oexmem_uncondBranch;
		ZeroBranch <= Oexmem_ZeroFlag xor Oexmem_isCBNZ;
		
	
-------------------------------------------------------------------------------------------------------
--Buffer MEM/WB
-------------------------------------------------------------------------------------------------------

		buffer_MEMWB : MEMWB port map(clock, reset, Oexmem_regWrite, Oexmem_memToReg, iDataMemoryOut, Oexmem_AluResult, Oexmem_Instruction4to0, 
							  Omemwb_regWrite, Omemwb_memToReg, Omemwb_ReadData, Omemwb_Address, Omemwb_Instruction4to0);
						
-------------------------------------------------------------------------------------------------------
--Estágio WB
-------------------------------------------------------------------------------------------------------

		mux4: mux2to1 generic map(64) port map(Omemwb_memToReg, Omemwb_Address, Omemwb_ReadData, iMux4Out);



-----------------------------------------------------------------------------------------------------------

--- Saidas
	instruction31to21 <= IDInstruction31to21;
	zero <= ZeroBranch;

end datapath_arch;

-----------------------------------------------------------------------------------------------------------------------------
--===========================================================================================================================
--Buffer IF/ID
--===========================================================================================================================
-----------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_bit.all;

entity IFID is
  port(				
  	clk					   : in  bit;
  	reset				   : in  bit;
  	In_currentPC 		   : in  bit_vector(31 downto 0);
  	In_fetchedInstruction  : in  bit_vector(31 downto 0);
	Out_currentPC 		   : out bit_vector(31 downto 0);
	Out_fetchedInstruction : out bit_vector(31 downto 0)
  );

end entity IFID;

architecture IFIDArchi of IFID is
-------------------------------------------------------------------------------
--reg
-------------------------------------------------------------------------------
component reg is
  generic(wordSize: natural := 32);
  port(
    clock  : in  bit; -- entrada de clock
    reset  : in  bit; -- clear assÃ­ncrono
    load   : in  bit; -- write enable (carga paralela)
    d      : in  bit_vector(wordSize-1 downto 0); -- entrada
    q      : out bit_vector(wordSize-1 downto 0) -- saÃ­da
  );
end component;


begin 
	
reg1 : reg port map(clk, reset, '1', In_currentPC, Out_currentPC);
reg2 : reg port map(clk, reset, '1', In_fetchedInstruction, Out_fetchedInstruction);
	
end IFIDArchi;
-----------------------------------------------------------------------------------------------------------------------------
--===========================================================================================================================
--Buffer ID/EX
--===========================================================================================================================
-----------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_bit.all;

entity IDEX is
  port(
  clk 					 : in  bit;
  reset 				 : in  bit;
  In_uncondbranch 		 : in  bit;
  In_branch 			 : in  bit;
  In_memRead 			 : in  bit;
  In_memToReg 			 : in  bit;
  In_memWrite 		 	 : in  bit;
  In_aluSrc 		 	 : in  bit;
  In_regWrite 			 : in  bit;
  In_aluCtl				 : in  bit_vector(3 downto 0);
  In_currentPC 			 : in  bit_vector(31 downto 0);
  In_ReadData1			 : in  bit_vector(63 downto 0);
  In_ReadData2			 : in  bit_vector(63 downto 0);
  In_SignExtend			 : in  bit_vector(63 downto 0);
  In_Instruction31to21   : in  bit_vector(10 downto 0);
  In_Instruction4to0	 : in  bit_vector (4 downto 0);
  Out_uncondbranch 		 : out bit;
  Out_branch 			 : out bit;
  Out_memRead 			 : out bit;
  Out_memToReg 			 : out bit;
  Out_memWrite 			 : out bit;
  Out_aluSrc 			 : out bit;
  Out_regWrite 			 : out bit;
  Out_aluCtl			 : out bit_vector(3 downto 0);
  Out_currentPC			 : out bit_vector(31 downto 0);
  Out_ReadData1			 : out bit_vector(63 downto 0);
  Out_ReadData2          : out bit_vector(63 downto 0);
  Out_SignExtend		 : out bit_vector(63 downto 0);
  Out_Instruction31to21  : out bit_vector(10 downto 0);
  Out_Instruction4to0	 : out bit_vector (4 downto 0)
  );
  
end entity IDEX;

architecture IDEXArchi of IDEX is
-------------------------------------------------------------------------------
--reg
-------------------------------------------------------------------------------
component reg is
  generic(wordSize: natural := 64);
  port(
    clock  : in  bit; -- entrada de clock
    reset  : in  bit; -- clear assÃ­ncrono
    load   : in  bit; -- write enable (carga paralela)
    d      : in  bit_vector(wordSize-1 downto 0); -- entrada
    q      : out bit_vector(wordSize-1 downto 0) -- saÃ­da
  );
end component;

signal In_controlSignals : bit_vector(6 downto 0);
signal Out_controlSignals : bit_vector(6 downto 0);								


begin																								  	

	reg1 : reg generic map(7)  port map(clk, reset, '1', In_controlSignals,    Out_controlSignals);
	reg2 : reg generic map(4)  port map(clk, reset, '1', In_aluCtl,            Out_aluCtl);
	reg3 : reg generic map(31) port map(clk, reset, '1', In_currentPC,         Out_currentPC);
	reg4 : reg generic map(64) port map(clk, reset, '1', In_ReadData1,         Out_ReadData1);
	reg5 : reg generic map(64) port map(clk, reset, '1', In_ReadData2,         Out_ReadData2);
	reg6 : reg generic map(64) port map(clk, reset, '1', In_SignExtend,        Out_SignExtend);
	reg7 : reg generic map(11) port map(clk, reset, '1', In_Instruction31to21, Out_Instruction31to21);
	reg8 : reg generic map(5)  port map(clk, reset, '1', In_Instruction4to0,   Out_Instruction4to0);

	In_controlSignals(0) <= In_uncondbranch;
	In_controlSignals(1) <= In_branch;
	In_controlSignals(2) <= In_memRead;
	In_controlSignals(3) <= In_memToReg;
	In_controlSignals(4) <= In_memWrite;
	In_controlSignals(5) <= In_aluSrc;
	In_controlSignals(6) <= In_regWrite;
	Out_uncondbranch 	 <= Out_controlSignals(0);
	Out_branch 			 <= Out_controlSignals(1);
	Out_memRead 		 <= Out_controlSignals(2);
	Out_memToReg 		 <= Out_controlSignals(3);
	Out_memWrite 		 <= Out_controlSignals(4);
	Out_aluSrc 		     <= Out_controlSignals(5);
	Out_regWrite		 <= Out_controlSignals(6);
	
end IDEXArchi;

-----------------------------------------------------------------------------------------------------------------------------
--===========================================================================================================================
--Buffer EX/MEM
--===========================================================================================================================
-----------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_bit.all;

entity EXMEM is
  port(
  clk 				     : in  bit;
  reset 				 : in  bit;
  In_uncondbranch 		 : in  bit;
  In_branch 			 : in  bit;
  In_memRead 			 : in  bit;
  In_memToReg 			 : in  bit;
  In_memWrite 		 	 : in  bit;
  In_regWrite 			 : in  bit;
  In_isCBNZ				 : in  bit;
  In_PcSum				 : in  bit_vector (63 downto 0);	
  In_ZeroFlag			 : in  bit;
  In_AluResult			 : in  bit_vector (63 downto 0);
  In_ReadData2			 : in  bit_vector (63 downto 0);
  In_Instruction4to0     : in  bit_vector(4 downto 0);
  Out_uncondbranch 		 : out bit;
  Out_branch 			 : out bit;
  Out_memRead 			 : out bit;
  Out_memToReg 			 : out bit;
  Out_memWrite 		 	 : out bit;
  Out_regWrite 			 : out bit;
  Out_isCBNZ			 : out bit;
  Out_PcSum				 : out bit_vector (63 downto 0);
  Out_ZeroFlag			 : out bit;
  Out_AluResult			 : out bit_vector (63 downto 0);
  Out_ReadData2			 : out bit_vector (63 downto 0);
  Out_Instruction4to0    : out bit_vector(4 downto 0)
  );
  
  									  
  

end entity EXMEM;

architecture EXMEMArchi of EXMEM is
-------------------------------------------------------------------------------
--reg
-------------------------------------------------------------------------------
component reg is
  generic(wordSize: natural := 64);
  port(
    clock  : in  bit; -- entrada de clock
    reset  : in  bit; -- clear assÃ­ncrono
    load   : in  bit; -- write enable (carga paralela)
    d      : in  bit_vector(wordSize-1 downto 0); -- entrada
    q      : out bit_vector(wordSize-1 downto 0) -- saÃ­da
  );
end component;
signal In_controlSignals : bit_vector(7 downto 0);
signal Out_controlSignals : bit_vector(7 downto 0);
begin
	
	reg1 : reg generic map(8)  port map(clk, reset, '1', In_controlSignals, Out_controlSignals);	
	reg2 : reg generic map(64) port map(clk, reset, '1', In_PcSum          , Out_PcSum);	
  	reg3 : reg generic map(64) port map(clk, reset, '1', In_AluResult      , Out_AluResult);	
	reg4 : reg generic map(64) port map(clk, reset, '1', In_ReadData2      , Out_ReadData2);	
	reg5 : reg generic map(5)  port map(clk, reset, '1', In_Instruction4to0, Out_Instruction4to0);	
  	
	
	In_controlSignals(0) <= In_uncondbranch;
	In_controlSignals(1) <= In_branch;
	In_controlSignals(2) <= In_memRead;
	In_controlSignals(3) <= In_memToReg;
	In_controlSignals(4) <= In_memWrite;
	In_controlSignals(5) <= In_regWrite;
	In_controlSignals(6) <= In_isCBNZ;
	In_controlSignals(7) <= In_ZeroFlag;
	
	Out_uncondbranch <= Out_controlSignals(0);
	Out_branch       <= Out_controlSignals(1);
	Out_memRead		 <= Out_controlSignals(2);
	Out_memToReg 	 <= Out_controlSignals(3);
	Out_memWrite	 <= Out_controlSignals(4);
	Out_regWrite	 <= Out_controlSignals(5);
	Out_isCBNZ		 <= Out_controlSignals(6);
	Out_ZeroFlag	 <= Out_controlSignals(7);
	
end EXMEMArchi;

-----------------------------------------------------------------------------------------------------------------------------
--===========================================================================================================================
--Buffer MEM/WB
--===========================================================================================================================
-----------------------------------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_bit.all;

entity MEMWB is
  port(
  clk 		   		  : in bit;
  reset  	   		  : in bit;
  In_regWrite  		  : in bit;	 
  In_memToReg  		  : in bit;
  In_ReadData  		  : in bit_vector (63 downto 0);
  In_Address		  : in bit_vector (63 downto 0);
  In_Instruction4to0  : in bit_vector (4 downto 0);
  Out_regWrite 		  : out bit;	 
  Out_memToReg 		  : out bit;
  Out_ReadData        : out bit_vector (63 downto 0);
  Out_Address		  : out bit_vector (63 downto 0);
  Out_Instruction4to0 : out bit_vector (4 downto 0)
  );					 

end entity MEMWB;

architecture MEMWBArchi of MEMWB is

-------------------------------------------------------------------------------
--reg
-------------------------------------------------------------------------------
component reg is
  generic(wordSize: natural := 64);
  port(
    clock  : in  bit; -- entrada de clock
    reset  : in  bit; -- clear assÃ­ncrono
    load   : in  bit; -- write enable (carga paralela)
    d      : in  bit_vector(wordSize-1 downto 0); -- entrada
    q      : out bit_vector(wordSize-1 downto 0) -- saÃ­da
  );
end component;

signal In_controlSignals  : bit_vector(1 downto 0);
signal Out_controlSignals : bit_vector(1 downto 0);	 


begin
	
	
	reg1 : reg generic map(2)  port map(clk, reset, '1', In_controlSignals , Out_controlSignals);
	reg2 : reg generic map(64) port map(clk, reset, '1', In_ReadData	   , Out_ReadData);
	reg3 : reg generic map(64) port map(clk, reset, '1', In_Address		   , Out_Address);
	reg4 : reg generic map(5)  port map(clk, reset, '1', In_Instruction4to0, Out_Instruction4to0);
	
	In_controlSignals(0) <= In_regwrite;
	In_controlSignals(1) <= In_memToReg;
	Out_regwrite <= Out_controlSignals(0);
	Out_memToReg <= Out_controlSignals(1);		 
	
	
end MEMWBArchi;


-----------------------------------------------------------------------------------------------------------------------------
--===========================================================================================================================
--registerBank
--===========================================================================================================================
-----------------------------------------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity registerBank is
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
end registerBank;


architecture registerBank_arch of registerBank is
  type registerFile is array(0 to 31) of bit_vector(63 downto 0);
  signal registers : registerFile := ((others=> (others=>'0')));
begin

  readData1 <= registers(to_integer(unsigned(to_stdlogicvector(readReg1Sel))));
  readData2 <= registers(to_integer(unsigned(to_stdlogicvector(readReg2Sel))));

  process (clk)
    begin
      --- falling edge
      if (clk='0' and clk'event) then
       -- Write
        if writeEnable = '1' then
          registers(to_integer(unsigned(to_stdlogicvector(writeRegSel)))) <= writeDateReg;  -- Write
        end if ;
      end if ;
  end process;

end registerBank_arch;
