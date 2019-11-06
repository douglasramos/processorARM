-- PCS3412 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Memoria (Unidade de controle)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto

use types.all;


entity MemoryL2Control is
    generic (
        accessTime: in time := 200 ns
    );
    port (

        clk:         in  bit;

        -- I/O relacionados a memoria
        cRead:         in  bit;
		cWrite:        in  bit;
        writeOptions:  out bit_vector(1 downto 0) := "00";

		-- I/O relacionados cache instrucao
		ciEnable:      in  bit;
        ciMemRw:       in  bit; --- '1' write e '0' read
        -- I/O cacheI e datapath da memoria
        ciMemReady:    out bit := '0';
        
        -- I/O relacionados cache dados
		cdEnable:      in  bit;
        cdMemRw:       in  bit; --- '1' write e '0' read
        -- I/O cacheD e datapath da memoria
        cdMemReady:    out bit := '0' 
 

    );
end entity MemoryL2Control;

architecture MemoryL2Control_arch of MemoryL2Control is

	-- Definicao de estados
    type states is (INIT, READY, DWRITE, IREAD, DREAD);
    signal state: states := INIT;

    signal sReady: bit;

begin
	process (clk, ciEnable, cdEnable, cRead, cWrite)
    begin

        if (rising_edge(clk) or ciEnable'event or cdEnable'event or cRead'event or cWrite'event) then

            case state is
                --- estado inicial
                when INIT =>
                    state <= READY;

                --- estado Ready
                when READY =>
                    -- read I
                    if (ciEnable = '1' and memRw = '0') then
                        state <= IREAD;
                    -- Read D
                    elsif (cdEnable = '1' and memRw = '0') then
                        state <= DREAD;
                    -- Write D
                    elsif (cdEnable = '1' and memRw = '1') then
                        state <= DWRITE;
                    else
                        state <= READY;
                    end if;
            
                --- estadao Read I
                when IREAD =>
                    if cRead = '1' then
                        state <= READY;
                    end if;

                --- estadao Read I
                when DREAD =>
                    if cRead = '1' then
                        state <= READY;
                    end if;

                --- estado Write D
                when DWRITE =>
                    if cWrite = '1' then
                        state <= READY;
                    end if;


                when others =>
                    state <= INIT;
            end case;

        end if;
	end process;

    --- saidas ---
    
    writeOptions <= "01" when (state = IREAD) else
                    "10" when (state = DREAD) else
                    "11" when (state = DWRITE) else
                    "00";
    
    sReady <= '1' when state = READY else '0';
    
    -- saídas diferentes, mas o comportamento deve ser o mesmo (é a mesma memória)
    ciMemReady <= sReady;
    cdMemReady <= sReady;



end architecture MemoryL2Control_arch;