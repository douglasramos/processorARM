-- PCS3422 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Cache de instrucoes (Unidade de controle)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto
library arm;
use arm.types.all;


entity cacheIControl is
    generic (
        accessTime: in time := 5 ns
    );
    port (

		-- I/O relacionados ao stage IF
		clk:    in  bit;
        stall:  out bit := '0';
		pc:     in  bit_vector(9 downto 0);

		-- I/O relacionados ao cache
		hitSignal:      in  bit;
		writeOptions:   out bit := '0';
		updateInfo:     out bit := '0';

        -- I/O relacionados a Memoria principal
		memReady:      in  bit;
		memRW:         out bit := '0';  --- '1' write e '0' read
        memEnable:     out bit := '0'

    );
end entity cacheIControl;

architecture cacheIControl_arch of cacheIControl is

	-- Definicao de estados
    type states is (INIT, READY, CTAG, CTAG2, HIT, MISS, MEM);
    signal state: states := INIT;

	-- debug
    signal state_d: bit_vector(2 downto 0);

begin
	process (clk, pc)


	begin
		if rising_edge(clk) then
			case state is

				--- estado inicial
				when INIT =>
					state <= READY;

				--- estado Ready
				when READY =>
                    if pc'event then
                        state <= CTAG;
                    end if;

				--- estado Compare Tag
				when CTAG =>
					if hitSignal = '1' then
					   state <= HIT;

					else -- Miss
						state <= MISS;

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
						state <= MEM;
                    else
						state <= MISS;
					end if;

				--- estado Memory Ready
				when MEM =>
					state <= CTAG2;

				when others =>
					state <= INIT;
			end case;
		end if;
	end process;

	--- saidas ---

	-- memRW
	memRW <= '0'; -- sempre leitra

	-- stall -- trava pipeline
	stall <= '1' after accessTime when state = MISS  or
									   state = MEM   or
									   state = CTAG2 else '0';

	-- compare_tag
	writeOptions <= '1' when state = MEM else '0';

	-- updateInfo
	updateInfo <= '1' when state = MEM else '0';

    -- memEnable
	memEnable <= '1' when state = MISS else '0';

end architecture cacheIControl_arch;