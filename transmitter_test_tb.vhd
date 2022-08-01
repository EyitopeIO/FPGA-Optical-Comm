-- manchester_main testbanch

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;


ENTITY monarch_tb IS
END monarch_tb;

architecture tb of monarch_tb is
    SIGNAL start_tx, reset : STD_LOGIC ;  --inputs
    SIGNAL clock : STD_LOGIC := '0' ;  --inputs
    SIGNAL man1_out, man2_out, led_idle, tx_mode : STD_LOGIC ;  --outputs   
    SIGNAL test_tout : STD_LOGIC_VECTOR(31 DOWNTO 0) ;
    
    SIGNAL test_man1 : STD_LOGIC;
    SIGNAL test_man2 : STD_LOGIC;
    SIGNAL test_querry : STD_LOGIC;
    SIGNAL test_manbeg : STD_LOGIC; 
begin

    UUT : ENTITY WORK.main PORT MAP (
        clock => clock, start_tx => start_tx, reset => reset,
        man1_out => man1_out, man2_out => man2_out, test_tout => test_tout,
        test_man1 => test_man1,
        test_man2 => test_man2, 
        test_querry => test_querry,
        led_idle => led_idle,
        tx_mode => tx_mode,
        test_manbeg => test_manbeg 
    );
    
    tx_Mode <= '0' after 5 ns, '1' after 10 ns ;
    start_tx <= '1' after 100 ns ;
    reset <= '0' after 50 ns ;

    CLK: PROCESS
    BEGIN
        FOR i IN 0 TO 10_000_000 LOOP
            clock <= not clock ;
            wait for 10 ns ;
        END LOOP;
        WAIT;
    END PROCESS;
END tb;