library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity banco_regs is
  port(
    outA        : out bit_vector(63 downto 0);
    outB        : out bit_vector(63 downto 0);
    regWData    : in  bit_vector(63 downto 0);
    writeEnable : in  bit;
    regASel     : in  bit_vector(4 downto 0);
    regBSel     : in  bit_vector(4 downto 0);
    regWSel     : in  bit_vector(4 downto 0);
    clk         : in  bit
    );
end banco_regs;


architecture banco_regs of banco_regs is
  type registerFile is array(0 to 31) of bit_vector(63 downto 0);
  signal registers : registerFile := ((others=> (others=>'0')));
begin
 
  outA <= registers(to_integer(unsigned(to_stdlogicvector(regASel))));
  outB <= registers(to_integer(unsigned(to_stdlogicvector(regBSel))));
	
  process (clk)
    begin	
      --- falling edge
      if (clk='0' and clk'event) then
       -- Write
        if writeEnable = '1' then
          registers(to_integer(unsigned(to_stdlogicvector(regWSel)))) <= regWData;  -- Write
        end if;
      end if;	  
  end process;

end banco_regs;
