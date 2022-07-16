
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY clock_divider IS
    port (
        clock_100MHz    :   IN std_logic;
        clock_1Hz       :   OUT std_logic
    );
END clock_divider;


ARCHITECTURE clock_architecture of clock_divider IS
    SIGNAL line_1Hz:    std_logic := '0';
BEGIN
    clock_1Hz <= line_1Hz;
    
FREQ_1Hz:       PROCESS(clock_100MHz, line_1Hz)
        VARIABLE count_100000000:   UNSIGNED (25 DOWNTO 0)  := "10111110101111000010000000";  -- 1Hz clock : I have updated this to be a value of 50,000,000 rahter THEN 100,000,000 - Archie [NEW].
        VARIABLE counter_100000000: UNSIGNED (25 DOWNTO 0)  := "00000000000000000000000000";        
    BEGIN
        IF (rising_edge(clock_100MHz)) THEN
            IF (counter_100000000 = count_100000000) THEN            
                line_1Hz <= not line_1Hz;
                counter_100000000 := "00000000000000000000000000";
            END IF;
            counter_100000000 := counter_100000000 + 1;
        END IF;
    END PROCESS;
        
END clock_architecture;
