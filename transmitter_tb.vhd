-- manchester_main testbanch

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;


ENTITY mantx_tb IS
END mantx_tb;

architecture tb of mantx_tb is
    SIGNAL start_tx, reset : STD_LOGIC ;  --inputs
    SIGNAL data_bus : STD_LOGIC_VECTOR(31 DOWNTO 0) ;
    SIGNAL clock_100, clock_1 : STD_LOGIC := '0' ;  --inputs
    SIGNAL man1_out, man2_out, led_idle, overload : STD_LOGIC ;  --outputs   
    
begin

    UUT : ENTITY WORK.mantx PORT MAP (
        clock_100MHz => clock_100, start_tx => start_tx, reset => reset,
        clock_1p3615MHz => clock_1, data_bus => data_bus,  
        man1_out => man1_out, man2_out => man2_out, 
        led_idle => led_idle, overload => overload
    );
    
    start_tx <= '1' AFTER 200 ns, '0' AFTER 230 ns ;
    data_bus <= x"00000000" AFTER 10 ns,  x"345FE20A" AFTER 100 ns ;   --Arbitrary number
    reset <= '1' AFTER 1 ns, '0' AFTER 9 ns ;
    

    CLK100: PROCESS
    BEGIN
        FOR i IN 0 TO 100_000_000 LOOP
            clock_100 <= NOT clock_100 ;
            WAIT FOR 10 ns ;
        END LOOP;
        WAIT ;
    END PROCESS;
    
    CLK1 : PROCESS
    BEGIN
        FOR i in 0 TO 100_000_000 LOOP
            clock_1 <= NOT clock_1 ;
            WAIT FOR 734 ns ;
        END LOOP ;
        WAIT ;
    END PROCESS; 
END tb;