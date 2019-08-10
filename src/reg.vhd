-------------------------------------------------------
--! @file register.vhdl
--! @author balbertini@usp.br
--! @date 20160310
--! @brief Universal register adapted to polileg usage.
-------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

--! Este registrador possui um parametro usado para controlar a largura da
--! saída. Há somente entrada e saída paralela, controlada por um enable
--! síncrono, e o registrador é sensível a borda de subida.
entity reg is
	generic(wordSize: natural :=4);
	port(
		clock:    in 	bit; --! entrada de clock
		reset:	  in 	bit; --! clear assíncrono
		load:     in 	bit; --! write enable (carga paralela)
		d:   			in	bit_vector(wordSize-1 downto 0); --! entrada
		q:  			out	bit_vector(wordSize-1 downto 0) --! saída
	);
end reg;

--! @brief Arquitetura comportamental do registrador
--! @details O único processo é responsável por amostrar ou não a entrada em um
--! sinal interno, que será sintetizado como flip-flops.
architecture flipflop of reg is
	--! sinal que armazenará a entrada
	signal internal: bit_vector(wordSize-1 downto 0);
	begin
		--! Este estilo de registrador utiliza um sinal intermediário, que é
		--! utilizado para armazenar a entrada na borda de clock. Note que não é
		--! especificado amostragem caso não estejamos em uma borda de subida e o
		--! sinal de carregamento seja alto, o que indica ao sintetizador que esta
		--! estrutura é um registrador implementado com flip-flops.
		registra: process(clock, reset)
		begin
			if reset='1' then
				internal <= (others=>'0');
			elsif clock='1' and clock'event then
				if load = '1' then
					internal <= d;
			  end if;
			end if;
		end process; -- registra
		q <= internal;
end flipflop;
