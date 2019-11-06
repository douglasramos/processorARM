-- PCS3412 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Cache de dados (Unidade de controle)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto

use types.all;


entity ControlCacheL2 is
    generic (
        accessTime: in time := 50 ns
    );
    port (			  
        
        -- I/O pipeline?
        clk:           in  bit;

		-- I/O relacionado ao victim buffer
		vbDataIn:      in word_vector_type(1 downto 0) := (others => word_vector_init);
		vbAddr:        in  bit_vector(9 downto 0);
		vbReady:       out bit;

		-- I/O relacionado ao cache de dados
		cdRW:          in  bit;
		cdEnable:      in  bit;
		-- I/O cacheD e datapath do L2
		cdL2Hit:       out bit := '0';

		-- I/O relacionado ao cache de instruções
		ciRW:          in  bit;
		ciEnable:      in  bit;
		-- I/O cachel e datapath do L2
		ciL2Hit:       out bit := '0';

		-- I/O relacionados ao cache L2
		dirtyBit:      in  bit;
		hitSignal:     in  bit;
		writeOptions:  out bit_vector(1 downto 0) := "00";
		addrOptions:   out bit_vector(1 downto 0) := "00";
		updateInfo:    out bit := '0';
		
        -- I/O relacionados a Memoria princial
		memReady:      in  bit;
		memRW:         out bit := '0';  --- '1' write e '0' read
        memEnable:     out bit := '0'
        
    );
end entity ControlCacheL2;

architecture ControlCacheL2_arch of ControlCacheL2 is	 	  
							  
	-- Definicao de estados
    type states is (INIT, READY, REQ, ICTAG, IMISSMWRITE, IHIT, IMISS, IMREADY, ICTAG2, DCTAG, DMISSMWRITE, DHIT, DMISS, DMREADY, DCTAG2, CHECKVB, VBCDIRTY, VBWRITE, VBMWRITE);
    signal state: states := INIT; 

    
begin 


	process (clk, cdEnable, ciEnable, vbDataIn, vbAddr)
	
	-- detecta alteração na saída do victim buffer
	variable vbChange : natural := 0;
	
	begin
		-- Fluxo: 
		--	- Primeiro verifica se ocorreu alguma alteracao na interface com Victim Buffer (CHECKVB), se mudou tem dados a ser persistido em L2
		--	- Feito isso analisa se ocorreu alguma socilitacao de dado por parte dos caches L1 (READY).
		--	- Cache de instrucao tem prioridade na busca pelo dado (REQ).
		--	- No estado de Hit do CacheI (IHIT) se não houver socilitacao da CacheD, a maquina de estados volta para CHECKVB, se houver socilitação faza busca.
		--	- Ao fim da analisa da socilitacacao, a maquina de estados volta obrigatoriamente para (CHECKVB)
		
		--- se ocorreu alguma mudanca no IO do victim buffer, ativa a variavel vbChange
		if (vbDataIn'event or vbAddr'event) then
			vbChange := 1;
		end if;

		if (rising_edge(clk) or cdEnable'event or ciEnable'event) then
			case state is 
				--- estado inicial
				when INIT =>
					state <= READY;	
				
				--- estado Ready
				when READY =>
                    if (ciEnable = '1' or cdEnable = '1' or vbChange = 1) then
                        state <= REQ;
					end if;
	
				--- estado Requisicoes
				when REQ =>
					if ciEnable = '1' then
						state <= ICTAG;
					elsif cdEnable = '1' then
						state <= DCTAG;
					else
						state <= CHECKVB;
					end if;
				
				--- compare tag para instrucoes
				when ICTAG =>
					if hitSignal = '1' then
						state <= IHIT;
					-- MISS
					elsif hitSignal = '0' then
						-- primeiro analisa se bloco em questão e "sujo"
						if dirtyBit = '1' then
							state <= IMISSMWRITE;	-- precisa colocar dado atual na Memoria primeiro
						elsif dirtyBit = '0' then
							state <= IMISS; -- pode tratar miss normalmente
						end if;	
					end if;
				
				--- estado Instruction Miss Memory Write
				when IMISSMWRITE =>
					if memReady = '1' then
						state <= IMISS; -- se já salvou na memoria, pode continuar miss
					elsif memReady = '0' then
						state <= IMISSMWRITE; -- espera salvar na memoria
					end if;

				--- estado Hit instrução
				when IHIT =>
					if cdEnable = '1' then
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
						-- primeiro analisa se bloco em questão e "sujo"
						if dirtyBit = '1' then
							state <= DMISSMWRITE;	-- precisa colocar dado atual na Memoria primeiro
						elsif dirtyBit = '0' then
							state <= DMISS; -- pode tratar miss normalmente
						end if;
					end if;

				--- estado Instruction Miss Memory Write
				when DMISSMWRITE =>
					if memReady = '1' then
						state <= DMISS; -- se ja salvou na memoria, pode continuar miss
					elsif memReady = '0' then
						state <= DMISSMWRITE; -- espera salvar na memoria
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
						state <= VBCDIRTY;
						vbChange := 0;
					else
						state <= READY;
					end if;

				--- compare VB dirty bit
				when VBCDIRTY =>
					if dirtyBit = '1' then
						state <= VBMWRITE;	-- precisa colocar dado atual na Memoria primeiro
					elsif dirtyBit = '0' then
							state <= VBWRITE; -- pode ja escrever no cache
					end if;
				
				--- estado VB Write
				when VBWRITE =>
				   state <= READY;
				
				--- estado VB Memory Write
				when VBMWRITE =>
					if memReady = '1' then
						state <= VBWRITE; -- se já salvou na memória, pode escrever dado na cache
					elsif memReady = '0' then
						state <= VBMWRITE; -- espera salvar na memória
					end if;

				when others =>
					state <= INIT;
			end case;
		end if;
	end process;
	
	--- saidas ---
	
	-- cdL2Hit => informa pra cache L1 que ocorreu um Hit de dados
	cdL2Hit <= '1' when state = DHIT else '0';

	-- ciL2Hit => informa pra cache L1 que ocorreu um Hit de instruções
	ciL2Hit <= '1' when state = IHIT else '0';
	
	-- addrOptions
	addrOptions <= "01" when (state = ICTAG or state = IMISSMWRITE or state = IHIT or state = IMISS or state = IMREADY or state = ICTAG2) else
				   "10" when (state = DCTAG or state = DMISSMWRITE or state = DHIT or state = DMISS or state = DMREADY or state = DCTAG2) else
				   "11" when (state = CHECKVB or state = VBCDIRTY or state = VBWRITE or state = VBMWRITE) else
				   "00";
	
	-- writeOptions
	writeOptions <= "01" when (state = IMREADY or state = DMREADY) else
        	        "10" when state = VBWRITE else 
		            "00";
	         		 
	-- updateInfo
	updateInfo <= '1' when (state = IMREADY or state = DMREADY or state = VBWRITE) else '0';
	         	   				  
    -- memory		
	memEnable <= '1' when (state = IMISS or state = DMISS or state = IMISSMWRITE or state = DMISSMWRITE) else '0';
	memRW     <= '1' when (state = VBMWRITE or state = IMISSMWRITE or state = DMISSMWRITE)  else '0';
	

end architecture ControlCacheL2_arch;