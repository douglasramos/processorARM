-- PCS3412 - Organizacao e Arquitetura de Computadores II
-- ARM
--
-- Description:
--     Cache de dados (Unidade de controle)

library ieee;
use ieee.numeric_bit.all;

-- importa os types do projeto

use types.all;


entity cacheL2Control is
    generic (
        accessTime: in time := 50 ns
    );
    port (

        clk:           in  bit;

		-- I/O relacionado ao victim buffer
		vbDataIn:      in word_vector_type(1 downto 0) := (others => word_vector_init);
		vbAddr:        in  bit_vector(9 downto 0);
		vbReady:       out bit := '0';

		-- I/O relacionado ao cache de dados
		cdEnable:      in  bit;
		-- I/O cacheD e datapath do L2
		cdL2Hit:       out bit := '0';

		-- I/O relacionado ao cache de instruções
		ciEnable:      in  bit;

		-- I/O cachel e datapath do L2
		ciL2Hit:       out bit := '0';

		-- I/O relacionados ao cache L2
		dirtyBit:      in  bit;
		hitSignal:     in  bit;
		vbWriteL2:       in  bit;
		writeOptions:  out bit_vector(1 downto 0) := "00";
		addrOptions:   out bit_vector(1 downto 0) := "00";
		updateInfo:    out bit := '0';
		delete:        out bit := '0';

        -- I/O relacionados a Memoria princial
		memReady:      in  bit;
		memRW:         out bit := '0';  --- '1' write e '0' read
        memEnable:     out bit := '0'

    );
end entity cacheL2Control;

architecture cacheL2Control_arch of cacheL2Control is

	-- Definicao de estados
    type states is (INIT, READY, REQ, ICTAG, IMISSMWRITE, IHIT, IMISS, IMREADY, ICTAG2, DCTAG, DMISSMWRITE, DHIT, DMISS, DMREADY, DCTAG2, CHECKVB, VBCDIRTY, VBWRITE, VBMWRITE);
    signal state_L2: states := INIT;


begin


	process (clk, vbDataIn, vbAddr)

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

		if (rising_edge(clk)) then
			case state_L2 is
				--- estado inicial
				when INIT =>
					state_L2 <= READY;

				--- estado Ready
				when READY =>
                    if (ciEnable = '1' or cdEnable = '1' or vbChange = 1) then
                        state_L2 <= REQ;
					end if;

				--- estado Requisicoes
				when REQ =>
					if ciEnable = '1' then
						state_L2 <= ICTAG;
					elsif cdEnable = '1' then
						state_L2 <= DCTAG;
					else
						state_L2 <= CHECKVB;
					end if;

				--- compare tag para instrucoes
				when ICTAG =>
					if hitSignal = '1' then
						state_L2 <= IHIT;
					-- MISS
					elsif hitSignal = '0' then
						-- primeiro analisa se bloco em questão e "sujo"
						if dirtyBit = '1' then
							state_L2 <= IMISSMWRITE;	-- precisa colocar dado atual na Memoria primeiro
						elsif dirtyBit = '0' then
							state_L2 <= IMISS; -- pode tratar miss normalmente
						end if;
					end if;

				--- estado Instruction Miss Memory Write
				when IMISSMWRITE =>
					if memReady = '1' then
						state_L2 <= IMISS; -- se já salvou na memoria, pode continuar miss
					elsif memReady = '0' then
						state_L2 <= IMISSMWRITE; -- espera salvar na memoria
					end if;

				--- estado Hit instrução
				when IHIT =>
					if cdEnable = '1' then
						state_L2 <= DCTAG;
					else
						state_L2 <= CHECKVB;
					end if;

				--- estado Miss Instrução
				when IMISS =>
					if memReady = '1' then
						state_L2 <= IMREADY;
					end if;

				--- estado Instrução Memory Ready
				when IMREADY =>
					state_L2 <= ICTAG2;

				--- compare tag 2 para instrução
				when ICTAG2 =>
					if hitSignal = '1' then
					   state_L2 <= IHIT;

					else -- Miss
						state_L2 <= IMISS;
					end if;

				--- compare tag para dados
				when DCTAG =>
					if hitSignal = '1' then
						state_L2 <= DHIT;
					elsif hitSignal = '0' then
						-- primeiro analisa se bloco em questão e "sujo"
						if dirtyBit = '1' then
							state_L2 <= DMISSMWRITE;	-- precisa colocar dado atual na Memoria primeiro
						elsif dirtyBit = '0' then
							state_L2 <= DMISS; -- pode tratar miss normalmente
						end if;
					end if;

				--- estado Instruction Miss Memory Write
				when DMISSMWRITE =>
					if memReady = '1' then
						state_L2 <= DMISS; -- se ja salvou na memoria, pode continuar miss
					elsif memReady = '0' then
						state_L2 <= DMISSMWRITE; -- espera salvar na memoria
					end if;

				--- estado Hit dados
				when DHIT =>
					state_L2 <= CHECKVB;

				--- estado Miss dados
				when DMISS =>
					if memReady = '1' then
						state_L2 <= DMREADY;
                    end if;

				--- estado dados Memory Ready
				when DMREADY =>
					state_L2 <= DCTAG2;

				--- compare tag 2 para dados
				when DCTAG2 =>
					if hitSignal = '1' then
					   state_L2 <= DHIT;

					else -- Miss
						state_L2 <= DMISS;
					end if;


				--- check Victim Buffer
				when CHECKVB =>
					if vbChange = 1 then
						state_L2 <= VBCDIRTY;
						vbChange := 0;
					else
						state_L2 <= READY;
					end if;

				--- compare VB dirty bit
				when VBCDIRTY =>
					if dirtyBit = '1' then
						state_L2 <= VBMWRITE;	-- precisa colocar dado atual na Memoria primeiro
					elsif dirtyBit = '0' then
							state_L2 <= VBWRITE; -- pode ja escrever no cache
					end if;

				--- estado VB Write
				when VBWRITE =>
					if (vbWriteL2 = '1') then
						state_L2 <= READY;
					end if;

				--- estado VB Memory Write
				when VBMWRITE =>
					if memReady = '1' then
						state_L2 <= VBWRITE; -- se já salvou na memória, pode escrever dado na cache
					elsif memReady = '0' then
						state_L2 <= VBMWRITE; -- espera salvar na memória
					end if;

				when others =>
					state_L2 <= INIT;
			end case;
		end if;
	end process;

	--- saidas ---

	-- vbReady
	vbReady <= vbWriteL2;

	-- cdL2Hit => informa pra cache L1 que ocorreu um Hit de dados
	cdL2Hit <= '1' when state_L2 = DHIT else '0';

	-- ciL2Hit => informa pra cache L1 que ocorreu um Hit de instruções
	ciL2Hit <= '1' when state_L2 = IHIT else '0';

	-- addrOptions
	addrOptions <= "01" when (state_L2 = ICTAG or state_L2 = IMISSMWRITE or state_L2 = IHIT or state_L2 = IMISS or state_L2 = IMREADY or state_L2 = ICTAG2) else
				   "10" when (state_L2 = DCTAG or state_L2 = DMISSMWRITE or state_L2 = DHIT or state_L2 = DMISS or state_L2 = DMREADY or state_L2 = DCTAG2) else
				   "11" when (state_L2 = CHECKVB or state_L2 = VBCDIRTY or state_L2 = VBWRITE or state_L2 = VBMWRITE) else
				   "00";

	-- writeOptions
	writeOptions <= "01" when (state_L2 = IMREADY or state_L2 = DMREADY) else
        	        "10" when state_L2 = VBWRITE else
		            "00";

	-- updateInfo
	updateInfo <= '1' when (state_L2 = IMREADY or state_L2 = DMREADY or state_L2 = VBWRITE) else '0';

    -- memory
	memEnable <= '1' when (state_L2 = IMISS or state_L2 = DMISS or state_L2 = IMISSMWRITE or state_L2 = DMISSMWRITE) else '0';
	memRW     <= '1' when (state_L2 = VBMWRITE or state_L2 = IMISSMWRITE or state_L2 = DMISSMWRITE)  else '0';

	-- delete (lógica associada a otimização exclusion)
	delete <= '1' when (state_L2 = IHIT or state_L2 = DHIT) else
			  '0';


end architecture cacheL2Control_arch;