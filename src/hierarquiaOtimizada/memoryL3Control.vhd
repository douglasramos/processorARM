-- PCS3412 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Memoria (Unidade de controle)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto
library arm;
use arm.types.all;


entity MemoryL3Control is
    generic (
        accessTime: in time := 200 ns
    );
    port (

        clk:        in  bit;

        -- I/O relacionados a memoria
        cRead:     in  bit;
		cWrite:    in  bit;
        RW:        out bit_vector(1 downto 0) := "00";

		-- I/O relacionados cache L2
		enable:    in  bit;
        memRw:     in  bit; --- '1' write e '0' read
        memReady:  out bit := '0' 

    );
end entity MemoryL3Control;

architecture MemoryL3Control_arch of MemoryL3Control is

	-- Definicao de estados
    type states is (INIT, READY, WRITE, READ);
    signal state: states := INIT;

begin
	process (clk, enable, memRw)
    begin

        if (rising_edge(clk) or enable'event or cRead'event or cWrite'event)  then

            case state is
                --- estado inicial
                when INIT =>
                    state <= READY;

                --- estado Ready
                when READY =>
                    if (enable = '1' and memRw = '0') then
                        state <= READ;
                    elsif (enable = '1' and memRw = '1') then
                        state <= WRITE;
                    end if;
            
                --- estadao Read
                when READ =>
                    if cRead = '1' then
                        state <= READY;
                    end if;

                --- estado Write
                when WRITE =>
                    if cWrite = '1' then
                        state <= READY;
                    end if;


                when others =>
                    state <= INIT;
            end case;

        end if;
	end process;

	--- saidas ---
    
    --- RW
    -- 01 => Read
    -- 10 => Write
    -- 00 => Idle
    RW <= "01" when (state = READ) else
          "10" when (state = WRITE) else
          "00";
    
    memReady <= '1' when (state = READY) else '0';


end architecture MemoryL3Control_arch;