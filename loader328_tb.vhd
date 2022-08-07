-- manchester_main testbanch

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

ENTITY loader328_tb IS
END loader328_tb;

architecture tb OF loader328_tb IS
    SIGNAL clock, reset, fetch, ready : STD_LOGIC := '0' ;  --inputs
    SIGNAL bits8 : STD_LOGIC_VECTOR(7 DOWNTO 0) ;
    SIGNAL bits32 : STD_LOGIC_VECTOR(31 DOWNTO 0) ;  --output
    
begin

    UUT : ENTITY WORK.loader32_to_8 PORT MAP (
        bits8 => bits8, clock => clock, reset => reset, fetch => fetch,
        bits32 => bits32, ready => ready
    );
    
    reset <= '1' AFTER 1 ns, '0' AFTER 9 ns ;
    fetch <= '1' AFTER 10 ns, '0' AFTER 60 ns, '1' AFTER 80 ns ; 
    bits32 <= x"D45ABFE1" AFTER 10 ns, x"3ADB1803" AFTER 30 ns, x"5ED91A0F" AFTER 70 ns ;
    
    CLK: PROCESS
    BEGIN
        FOR i IN 0 TO 150 LOOP
            clock <= NOT clock ;
            WAIT FOR 5 ns ;
        END LOOP;
        WAIT ;
    END PROCESS;
    
END tb;