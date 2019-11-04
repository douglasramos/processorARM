-- PCS3412 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Cache de dados (Unidade de controle)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto
library arm;
use arm.types.all;


entity ControlCacheL2 is
    generic (
        accessTime: in time := 5 ns
    );
    port (			  
        
        -- I/O pipeline?
        clk            in  bit;

		-- I/O relacionado ao victim buffer
		vbDataIn:      in word_vector_type(31 downto 0) := (others => word_vector_init);
		vbAddr:        in  bit_vector(63 downto 0);
		vbReady        out bit;

		-- I/O relacionado ao cache de dados
		cdRW           in  bit;
		cdEnable       in  bit;
		cdL2Ready      out bit;

		-- I/O relacionado ao cache de instruções
		ciRW           in  bit;
		ciEnable       in  bit;
		ciL2Ready      out bit;

		-- I/O relacionados ao cache L2
		dirtyBit:      in  bit;
		hitSignal:     in  bit;
		writeOptions:  out bit_vector(1 downto 0) := "00";
		updateInfo:    out bit := '0';
		addrCacheD     out bit := '0';
		
        -- I/O relacionados a Memoria princial
		memReady:      in  bit;
		memRW:         out bit := '0';  --- '1' write e '0' read
        memEnable:     out bit := '0'
        
    );
end entity ControlCacheL2;

architecture ControlCacheL2_arch of ControlCacheL2 is	 	  
							  
	-- Definicao de estados
    type states is (INIT, READY, REQ, ICTAG, ICTAG2, IHIT, IMISS, IMREADY, DCTAG, DCTAG2, DHIT, DMISS, DMREADY);
    signal state: states := INIT; 

    -- Sinais internos
	signal enable: bit;
    
begin 

    -- enable geral
    enable <= ciEnable or cdEnable;
    -- Write signal geral

	process (clk, enable, vbDataIn, vbAddr)
	
	-- detecta alteração na saída do victim buffer
	variable vbChange : natural := 0;
	
	begin
		--- se ocorreu alguma mudança no IO do victim buffer, ativa a variavel
		if (vbDataIn'event or vbAddr'event) then
			vbChange := 1;
		end if;

		if (rising_edge(clk) or enable'event) then
			
			-- Fluxo: 
			--	- Primeiro verifica se ocorreu alguma alteração na interface com Victim Buffer (CHECKVB), se mudou tem dados a ser persistido em L2
			--	- Feito isso analisa se ocorreu alguma socilitação de dado por parte dos caches L1 (READY).
			--	- Cache de instrução tem prioridade na busca pelo dado (REQ).
			--	- No estado de Hit do CacheI (IHIT) se não houver socilitação da CacheD, a maquina de estados volta para CHECKVB, se houver socilitação faza busca.
			--	- Ao fim da analisa da socilitacação, a maquina de estados volta obrigatoriamente para (CHECKVB)

			case state is 
				--- estado inicial
				when INIT =>
					state <= CHECKVB;	
				
				--- estado Ready
				when READY =>
                    if enable'event then
                        state <= REQ;
					end if;
	
				--- estado Requisições
				when REQ =>
					if ciEnable = '1' then
						state <= ICTAG;
					elsif cdEnable = '1' then
						state <= DCTAG;
					end if;
				
				--- compare tag para instruções
				when ICTAG =>
					if hitSignal = '1' then
						state <= IHIT;
					elsif hitSignal = '0' then
						state < IMISS;
					end if;
				
				--- estado Hit instrução
				when IHIT =>
					if cdEnable=1 then
						state <= DCTAG;
					else
						state <= CHECKVB;
					end if;
				
				--- estado Miss Instrução
				when IMISS =>
					if memReady = '1' then
						state <= IMREADY;
                    end if;
				
				--- estado Instrução Memory Ready
				when IMREADY =>
					state <= ICTAG2;
				
				--- compare tag 2 para instrução
				when ICTAG2 =>
					if hitSignal = '1' then 
					   state <= IHIT;

					else -- Miss
						state <= IMISS;								
					end if;
					
				--- compare tag para dados
				when DCTAG =>
					if hitSignal = '1' then
						state <= DHIT;
					elsif hitSignal = '0' then
						state < DMISS;
					end if;

				--- estado Hit dados
				when DHIT =>
					state <= CHECKVB;
				
				--- estado Miss dados
				when DMISS =>
					if memReady = '1' then
						state <= DMREADY;
                    end if;
				
				--- estado dados Memory Ready
				when DMREADY =>
					state <= DCTAG2;
				
				--- compare tag 2 para dados
				when DCTAG2 =>
					if hitSignal = '1' then 
					   state <= DHIT;

					else -- Miss
						state <= DMISS;	
					end if;							
				

				--- check Victim Buffer
				when CHECKVB =>
					if vbChange = 1 then
						state <= VBCTAG;
						vbChange := 0;
					end if;
				
				
					
				when others =>
					state <= INIT;
			end case;
		end if;
	end process;
	
	--- saidas ---

	-- cdL2Ready
	cdL2Ready <= '1' when state = DHIT else '0';

	-- ciL2Ready
	ciL2Ready <= '1' when state = IHIT else '0';
	
	-- addrCacheD
	addrCacheD <= '1' when (state = DCTAG or state = DCTAG2 or state = DHIT or state = DMISS or state = DMREADY)
							else '0';
	
	-- writeOptions
	writeOptions <= "01" when (state = IMREADY or state = DMREADY) else
        	        -- "10" when state = WRITE else 
		             "00";
	         		 
	-- updateInfo
	updateInfo <= '1' when (state = IMREADY or state = DMREADY) else '0';
	         	   				  
    -- memory		
	memEnable <= '1' when (state = IMISS or state = DMISS ) else '0';
	memRW     <= '1' when state = MWRITE else '0';
	

end architecture ControlCacheL2_arch;