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
        ciMemReady:    out bit := '1';
        
        -- I/O relacionados cache dados
		cdEnable:      in  bit;
        cdMemRw:       in  bit; --- '1' write e '0' read
        -- I/O cacheD e datapath da memoria
        cdMemReady:    out bit := '1' 
 

    );
end entity MemoryL2Control;

architecture MemoryL2Control_arch of MemoryL2Control is

	-- Definicao de estados
    type states is (INIT, READY, DWRITE, IREAD, DREAD, IREADYDRPEND, DRREADYIPEND, IREADYDWPEND, DWREADYIPEND);
    signal state: states := INIT;

begin
    process (clk)

    begin

        if (rising_edge(clk)) then

            case state is
                --- estado inicial
                when INIT =>
                    state <= READY;

                --- estado Ready
                when READY =>
                    -- read I
                    if (ciEnable = '1' and ciMemRw = '0') then
                        state <= IREAD;
                    -- Read D
                    elsif (cdEnable = '1' and cdMemRw = '0') then
                        state <= DREAD;
                    -- Write D
                    elsif (cdEnable = '1' and cdMemRw = '1') then
                        state <= DWRITE;
                    else
                        state <= READY;
                    end if;
            
                --- estado Read I
                when IREAD =>
                    if cRead = '1' then
                        -- Read de dado pendente
                        if (cdEnable = '1' and cdMemRw = '0') then
                            state <= IREADYDRPEND;
                        -- Write de dado pendente
                        elsif (cdEnable = '1' and cdMemRw = '1') then
                            state <= IREADYDWPEND;
                        -- Ready
                        else
                            state <= READY;
                        end if;
                    end if;

                --- estado I Ready Data Read Pend
                when IREADYDRPEND =>
                    state <= DREAD;
    
                --- estado Data Read Ready I Pend
                when DRREADYIPEND =>
                    state <= IREAD;

                --- estadao Read I
                when DREAD =>
                    if cRead = '1' then
                        -- Read de instrucao pendente
                        if (ciEnable = '1' and ciMemRw = '0') then
                            state <= DRREADYIPEND;
                        -- Ready
                        else
                            state <= READY;
                        end if;
                    end if;
                
                --- estado I Ready Data Write Pend
                when IREADYDWPEND =>
                    state <= DWRITE;
                
                --- estado Data Write Ready I Pend
                when DWREADYIPEND =>
                    state <= IREAD;

                --- estado Write D
                when DWRITE =>
                    if cWrite = '1' then
                        -- Read de instrucao pendente
                        if (ciEnable = '1' and ciMemRw = '0') then
                            state <= DWREADYIPEND;
                        -- Ready
                        else
                            state <= READY;
                        end if;
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
    
    -- Ready condicionado ao estado
    ciMemReady <= '1' when (state = READY or state = IREADYDRPEND or state = IREADYDWPEND) else '0';
    cdMemReady <= '1' when (state = READY or state = DRREADYIPEND or state = DWREADYIPEND) else '0';



end architecture MemoryL2Control_arch;