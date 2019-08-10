--------------------------------------------------------------------------------
--! @file mux2to1.vhdl
--! @author balbertini@usp.br
--! @date 20160310
--! @brief Universal mux2to1 adapted to polileg usage.
--------------------------------------------------------------------------------

entity mux2to1 is
	generic(ws: natural := 4); -- word size
	port(
		s:    in  bit; -- selection: 0=a, 1=b
		a, b: in	bit_vector(ws-1 downto 0); -- inputs
		o:  	out	bit_vector(ws-1 downto 0)  -- output
	);
end mux2to1;

architecture whenelse of mux2to1 is
begin
	o <= b when s='1' else a;
end whenelse;

architecture withselect of mux2to1 is
begin
	with s select o <=
		b when '1',
		a when others;
end withselect;

-- This architecture is not generic
architecture struct of mux2to1 is
	signal sel: bit_vector(2 downto 0);
begin
	sel <= s&a(0)&b(0);
	assert ws=3
		report "This architecture is only valid for wordsize=3."
		severity failure;
	o(0) <= (a(0) and not(s)) or (b(0) and s);
	o(1) <= (a(1) and not(s)) or (b(1) and s);
	o(2) <= (a(2) and not(s)) or (b(2) and s);
end struct;

architecture structvec of mux2to1 is
	signal s_v: bit_vector(ws-1 downto 0);
begin
	s_v <= (others=> s);
	o <= (a and not(s_v)) or (b and s_v);
end structvec;


architecture structgen of mux2to1 is
begin
	st: for i in 0 to (ws-1) generate
		o(i) <= (a(i) and not(s)) or (b(i) and s);
	end generate;
end structgen;

 -- Do not use this architecture, it is not recommended to
 -- use a process to describe combinational logic
architecture proccase of mux2to1 is
begin
	process(s,a,b)
	begin
		case s is
			when '0' => o <= a;
			when '1' => o <= b;
			when others => o <= a;
		end case;
	end process;
end proccase;

-- Do not use this architecture, it is not recommended to
-- use a process to describe combinational logic
architecture procif of mux2to1 is
begin
	process(s,a,b)
	begin
		if s='0'then
			o <= a;
		else
			o <= b;
		end if;
	end process;
end procif;
