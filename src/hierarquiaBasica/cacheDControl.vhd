-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Cache de dados (Unidade de controle)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto

use types.all;


entity cacheDControl is
    generic (
        accessTime: in time := 5 ns
    );
    port (

		-- I/O relacionados ao stage MEM
		clk:            in  bit;
		clkPipeline:    in  bit;
        cpuWrite:       in  bit;
		cpuAddr:        in  bit_vector(9 downto 0);
		stall:          out bit := '0';

		-- I/O relacionados ao cache
		dirtyBit:      in  bit;
		hitSignal:     in  bit;
		writeOptions:  out bit_vector(1 downto 0) := "00";
		updateInfo:    out bit := '0';

        -- I/O relacionados a Memoria princial
		memReady:      in  bit;
		memRW:         out bit := '0';  --- '1' write e '0' read
        memEnable:     out bit := '0'

    );
end entity cacheDControl;

architecture cacheDControl_arch of cacheDControl is

	-- Definicao de estados
    type states is (INIT, READY, CTAG, WRITE, MWRITE, CTAG2, HIT, MISS, MREADY, MWRITEBF);
    signal state: states := INIT;

begin
	process (clk, clkPipeline, cpuAddr)
	begin
		if rising_edge(clk) or cpuAddr'event then -- talvez precise do rising_edge do clk pipeline
			case state is

				--- estado inicial
				when INIT =>
					state <= READY;

				--- estado Ready
				when READY =>
                    if cpuAddr'event then
                        state <= CTAG;
                    end if;

				--- estado Compare Tag
				when CTAG =>
					if cpuWrite = '0' then	  -- Leitura
						if hitSignal = '1' then
					   		state <= HIT;

						else -- Miss
							if dirtyBit = '1' then
								state <= MWRITEBF;
							else
								state <= MISS;
							end if;
                		end if;

					elsif cpuWrite = '1' and clkPipeline = '1' then -- Escrita no primeiro ciclo
						if dirtyBit = '1' then
							state <= MWRITE;	-- precisa colocar dado atual na Memoria primeiro
						elsif dirtyBit = '0' then
						 	state <= WRITE; -- pode ja escrever no cache
						end if;
                	end if;

				--- estado Write
				when WRITE =>
				   state <= READY;

				--- estado Memory Write
				when MWRITE =>
					if memReady = '1' then
						state <= READY;
					elsif memReady = '0' then
						state <= MWRITE;
					end if;


				--- estado Compare Tag2
				--- (segunda comparacao apos MISS)
				when CTAG2 =>
					if hitSignal = '1' then
					   state <= HIT;

					else -- Miss
						state <= MISS;

                    end if;

				--- estado Hit
				when HIT =>
					state <= READY;

				--- estado Miss
				when MISS =>
					if memReady = '1' then
						state <= MREADY;
					end if;

				--- estado Memory Write Before Read
				--- caso em que o memory read sobrescreveria um bloco com dirtybit
				when MWRITEBF =>
					if memReady = '1' then
						state <= MISS;
					elsif memReady = '0' then
						state <= MWRITEBF;
					end if;

				--- estado Memory Ready
				when MREADY =>
					state <= CTAG2;

				when others =>
					state <= INIT;
			end case;
		end if;
	end process;

	--- saidas ---

	-- stall -- trava pipeline
	stall <= '1' when state = MISS   or
					  state = MREADY or
					  state = CTAG2  or
					  state = MWRITE else '0';

	-- writeOptions
	writeOptions <=  "01" when state = MREADY  else
        	         "10" when state = WRITE   else
		             "00";

	-- updateInfo
	updateInfo <= '1' when state = MREADY else '0';

    -- memory
	memEnable <= '1' when state = MISS   else '0';
	memRW     <= '1' when state = MWRITE else '0';


end architecture cacheDControl_arch;