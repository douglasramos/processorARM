-------------------------------------------------------
--! @file signExtend.vhdl
--! @author balbertini@usp.br
--! @date 20180730
--! @brief 2-complement sign extension used on polileg.
-------------------------------------------------------
entity signExtend is
	-- Size of output is expected to be greater than input
	generic(
	  ws_in:  natural := 32; -- input word size
		ws_out: natural := 64); -- output word size
	port(												
		i: in	 bit_vector(ws_in-1  downto 0); -- input
		o: out bit_vector(ws_out-1 downto 0)  -- output
	);
end signExtend;

architecture combinational of signExtend is
signal AllInstruction : bit_vector(31 downto 0);
signal instru31to21   : bit_vector(10 downto 0);
signal BZero		  : bit_vector(18 downto 0);
signal LwSwExtend 	  : bit_vector(8 downto 0);
signal oLS			  : bit_vector(63 downto 0);
signal oCBZ			  : bit_vector(63 downto 0);
begin	
	AllInstruction <= i;		  
	
	instru31to21 <= AllInstruction(31 downto 21);
	
	LwSwExtend <= AllInstruction(20 downto 12);
	BZero <= AllInstruction(23 downto 5);
	
	
	-------------------------------------------------------------------
	--Extend dos 9 bits: load store
	-------------------------------------------------------------------
	
	lsbLS: for idxLS in 0 to (LwSwExtend'length-1) generate
		oLS(idxLS) <= LwSwExtend(idxLS);
	end generate;
	msbLS: for idxLS in (LwSwExtend'length) to (oLS'length-1) generate
		oLS(idxLS) <= LwSwExtend(LwSwExtend'length-1);
	end generate;
	
	-------------------------------------------------------------------
	--Extend dos 19 bits: CBZ (Branch on Zero)
	-------------------------------------------------------------------
	
	lsbCBZ: for idxCBZ in 0 to (BZero'length-1) generate
		oCBZ(idxCBZ) <= BZero(idxCBZ);
	end generate; 
	msbCBZ: for idxCBZ in (BZero'length) to (oCBZ'length-1) generate
		oCBZ(idxCBZ) <= BZero(BZero'length-1);
	end generate;		
	
	-------------------------------------------------------------------
	--Escolha final do output
	-------------------------------------------------------------------
	
	o <= oLS  when instru31to21 = "11111000010" or instru31to21 = "11111000000" else
		 oCBZ when instru31to21(10 downto 3) = "10110100";
		 
end combinational;
