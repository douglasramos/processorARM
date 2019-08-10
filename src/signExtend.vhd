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
begin
	lsb: for idx in 0 to (i'length-1) generate
		o(idx) <= i(idx);
	end generate;
	msb: for idx in (i'length) to (o'length-1) generate
		o(idx) <= i(i'length-1);
	end generate;
end combinational;
