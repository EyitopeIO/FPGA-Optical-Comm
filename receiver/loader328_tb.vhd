-- manchester_main testbanch

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;

ENTITY loader328_tb IS
END loader328_tb;

architecture tb OF loader328_tb IS
    SIGNAL clock, reset, trigger : STD_LOGIC := '0' ;  --inputs
    SIGNAL bits32 : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000" ;  --output
    SIGNAL  uart_tx, busy, txena, txb : STD_lOGIC;
    SIGNAL ubus : STD_LOGIC_VECTOR(7 DOWNTO 0) ;
    SIGNAl uart_rx : STD_LOGIC := '1' ;
    SIGNAL txbyten : STD_LOGIC_VECTOR(2 DOWNTO 0) ;
    
begin

    UUT : ENTITY WORK.loader32_to_8 PORT MAP (
        clock => clock, reset => reset, busy => busy, trigger => trigger,
        bits32 => bits32,  ubus => ubus,  uart_rx => uart_rx, uart_tx => uart_tx,
        txbyten => txbyten, txena => txena, txb => txb
    );
    
    reset <= '1' AFTER 1 ns, '0' AFTER 9 ns ;   --It's ready at 10ns mark
    bits32 <= x"12345678" AFTER 10 ns, x"EF45120F" AFTER 5000 us, x"FD7A12CE" AFTER 10000 us; 
    trigger <= '0' AFTER 1 ns, '1' AFTER 30 ns, '0' AFTER 100 us, '1' AFTER  5 ms, '0' AFTER 10 ms;
     
    CLK: PROCESS
    BEGIN
        FOR i IN 0 TO 100_000_000 LOOP
            clock <= NOT clock ;
            WAIT FOR 5 ns ;
        END LOOP;
        WAIT ;
    END PROCESS;
    
END tb;