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
		valid:         in  bit;
        writeOptions:  out bit_vector(1 downto 0) := "00";
		updateInfo:    out bit := '0';
		updateLRU:     out bit := '1';

        -- I/O relacionados ao L2
		L2Ready:      in  bit;
        L2Enable:     out bit := '0';

        -- I/O relacionados ao victim buffer
		isVBFull:   in  bit;
        vbEnable:   out bit

    );
end entity cacheDControl;

architecture cacheDControl_arch of cacheDControl is

	-- Definicao de estados
    type states is (INIT, READY, CTAG, WRITE, CTAG2, HIT, MISS, LREADY, WRITEVB, MWRITEBF);
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
							if valid = '1' then
								state <= WRITEVB;
							else
								state <= MISS;
							end if;
                		end if;

					elsif cpuWrite = '1' and clkPipeline = '1' then -- Escrita no primeiro ciclo
						state <= WRITEVB;	-- precisa colocar dado atual na Memoria primeiro
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
				--- estado Miss
				when MISS =>
					if L2Ready = '1'  then
						state <= LREADY;
					else
						state <= MISS;
					end if;

                --- estado Write para o VB
				when WRITEVB =>
					if isVBFull = '1' then
						state <= WRITEVB;
					else
						state <= MISS;
                    end if;

				--- estado Memory Write Before Read
				--- caso em que o memory read sobrescreveria um bloco com dirtybit
				when MWRITEBF =>
					if L2Ready = '1' then
						state <= MISS;
					elsif L2Ready = '0' then
						state <= MWRITEBF;
					end if;

				--- estado Memory Ready
				when LREADY =>
					state <= CTAG2;

				when others =>
					state <= INIT;
			end case;
		end if;
	end process;

	--- saidas ---

	-- stall -- trava pipeline
	stall <= '1' when state = MISS   or
					  state = LREADY or
					  state = CTAG2
					  else '0';

	-- writeOptions
	writeOptions <=  "01" when state = LREADY  else
        	         "10" when state = WRITE   else
		             "00";

	-- updateInfo
	updateInfo <= '1' when state = LREADY else '0';

    -- memory
	L2Enable <= '1' when state = MISS   else '0';

    -- vbEnable
	vbEnable <= '1' when state = WRITEVB else '0';

	-- update LRU
	updateLRU <= '1' when state = HIT else '0';

end architecture cacheDControl_arch;