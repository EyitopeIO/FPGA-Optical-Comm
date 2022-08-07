-- manchester_main testbanch

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

ENTITY loader832_tb IS
END loader832_tb;

architecture tb OF loader832_tb IS
    SIGNAL clock, reset, load, ready : STD_LOGIC := '0' ;  --inputs
    SIGNAL bits8 : STD_LOGIC_VECTOR(7 DOWNTO 0) ;
    SIGNAL bits32 : STD_LOGIC_VECTOR(31 DOWNTO 0) ;  --output
    
begin

    UUT : ENTITY WORK.loader8_to_32 PORT MAP (
        bits8 => bits8, clock => clock, reset => reset, load => load,
        bits32 => bits32, ready => ready
    );
    
    reset <= '1' AFTER 1 ns, '0' AFTER 9 ns ;
    load <= '1' AFTER 5 ns, '0' AFTER 60 ns, '1' AFTER 73 ns ; 
    bits8 <= x"4E" AFTER 10 ns, x"1A" AFTER 20 ns, x"BC" AFTER 30 ns, x"FF" AFTER 40 ns, x"01" AFTER 50 ns ;
    
    CLK: PROCESS
    BEGIN
        FOR i IN 0 TO 100 LOOP
            clock <= NOT clock ;
            WAIT FOR 5 ns ;
        END LOOP;
        WAIT ;
    END PROCESS;
    
END tb;