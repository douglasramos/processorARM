-------------------------------------------------------
--! @file shiftleft2.vhdl
--! @author balbertini@usp.br
--! @date 20180730
--! @brief Shift input left 2 bits, used on polileg.
-------------------------------------------------------

entity shiftleft2 is
	generic(
		ws: natural := 64); -- word size
	port(
		i: in	 bit_vector(ws-1 downto 0); -- input
		o: out bit_vector(ws-1 downto 0)  -- output
	);
end shiftleft2;

architecture structural of shiftleft2 is
begin
	-- LSB is zero
	o(1 downto 0) <= "00";
	-- remaining is copied but shifted by 2 positions
	o(ws-1 downto 2) <= i(ws-3 downto 0);
end structural;
