
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY clock_divider IS
    PORT (
        clock_100MHz    :   IN STD_lOGIC;
        clock_50MHz : OUT STD_LOGIC ;
        clock_1Hz       :   OUT STD_lOGIC
    );
END clock_divider;


ARCHITECTURE clock_architecture OF clock_divider IS
    SIGNAL line_1Hz :   STD_LOGIC := '0' ;
    SIGNAL line_50MHz : STD_LOGIC := '0' ;
BEGIN
    clock_1Hz <= line_1Hz ;
    clock_50MHz <= line_50MHz ;
   
    
FREQ_1Hz:       PROCESS(clock_100MHz, line_1Hz)
        VARIABLE count_100000000:   UNSIGNED (25 DOWNTO 0)  := "10111110101111000010000000";  -- 1Hz clock : I have updated this to be a value of 50,000,000 rahter THEN 100,000,000 - Archie [NEW].
        VARIABLE counter_100000000: UNSIGNED (25 DOWNTO 0)  := "00000000000000000000000000";        
    BEGIN
        IF (RISING_EDGE(clock_100MHz)) THEN
            IF (counter_100000000 = count_100000000) THEN            
                line_1Hz <= NOT line_1Hz;
                counter_100000000 := "00000000000000000000000000";
            END IF;
            counter_100000000 := counter_100000000 + 1;
        END IF;
    END PROCESS;


FREQ_50MHz: PROCESS(clock_100MHz, line_50MHz)
        VARIABLE count_50000000 : UNSIGNED(1 DOWNTO 0) := "10" ; 
        VARIABLE counter_50000000 : UNSIGNED(1 DOWNTO 0) := "00" ;   
    BEGIN
        IF RISING_EDGE(clock_100MHz) THEN
            IF (counter_50000000 = count_50000000) THEN
                line_50MHz <= not line_50MHz ;
                counter_50000000 := "00" ;
            END IF ;
            counter_50000000 := counter_50000000 + 1 ;
        END IF ;
    END PROCESS ;
    
END clock_architecture;
