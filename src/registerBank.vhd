library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity registerBank is
  port(
    clk          : in  bit;
    writeEnable  : in  bit;
    readReg1Sel  : in  bit_vector(4 downto 0);
    readReg2Sel  : in  bit_vector(4 downto 0);
    writeRegSel  : in  bit_vector(4 downto 0);
    writeDateReg : in  bit_vector(63 downto 0);
    readData1    : out bit_vector(63 downto 0);
    readData2    : out bit_vector(63 downto 0)
  );
end registerBank;


architecture registerBank_arch of registerBank is
  type registerFile is array(0 to 31) of bit_vector(63 downto 0);
  signal registers : registerFile := ((others=> (others=>'0')));
begin

  readData1 <= registers(to_integer(unsigned(to_stdlogicvector(readReg1Sel))));
  readData2 <= registers(to_integer(unsigned(to_stdlogicvector(readReg2Sel))));

  process (clk)
    begin
      --- falling edge
      if (clk='0' and clk'event) then
       -- Write
        if writeEnable = '1' then
          registers(to_integer(unsigned(to_stdlogicvector(writeRegSel)))) <= writeDateReg;  -- Write
        end if ;
      end if ;
  end process;

end registerBank_arch;
