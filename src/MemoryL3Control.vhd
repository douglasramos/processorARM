-- PCS3412 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Memória (Unidade de controle)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto
library arm;
use arm.types.all;


entity MemoryL3Control is
    generic (
        accessTime: in time := 40 ns
    );
    port (

        clk        in  bit;

        -- I/O relacionados a memória
        RW         out bit := '0';

		-- I/O relacionados cache L2
		enable:    in  bit;
        memRw:     in  bit; --- '1' write e '0' read
        memReady:  out bit := '0' 

    );
end entity MemoryL3Control;

architecture MemoryL3Control_arch of MemoryL3Control is

	-- Definicao de estados
    type states is (INIT, READY, CTAG, WRITE, READ);
    signal state: states := INIT;

begin
	process (clk, enable, memRw)
    begin

        if (rising_edge(clk) or enable'event or memRw'event) then

            case state is
                --- estado inicial
                when INIT =>
                    state <= READY;

                --- estado Ready
                when READY =>
                    if (enable = '1' and memRw = '0') then
                        state <= READ;
                    elsif (enable = '1' and memRw = '1') then
                        state < = WRITE;
                    end if;
            
                --- estadao Read
                when READ =>
                    state <= READY after acesstime;

                --- estado Write
                when WRITE =>
                    state <= READY after acesstime;


                when others =>
                    state <= INIT;
            end case;

        end if;
	end process;

	--- saidas ---
    
    RW <= '0' when (state = READ) else
          '1' when (state = WRITE);
    
    memReady <= '0' when (state = READ or state = WRITE) else '1';


end architecture MemoryL3Control_arch;