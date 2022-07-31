
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY clock_divider IS
    PORT (
        clock_100MHz    :   IN STD_lOGIC;
        clock_50MHz : OUT STD_LOGIC ;
        clock_10MHz : OUT STD_LOGIC ;
        clock_1Hz:   OUT STD_lOGIC
    );
END clock_divider;


ARCHITECTURE clock_architecture OF clock_divider IS
    SIGNAL line_1Hz :   STD_LOGIC := '0' ;
    SIGNAL line_50MHz : STD_LOGIC := '0' ;
    SIGNAL line_10MHz : STD_LOGIC := '0' ;
BEGIN
    clock_1Hz <= line_1Hz ;
    clock_50MHz <= line_50MHz ;
    clock_10MHz <= line_10MHz ;
   
    
FREQ_1Hz:       PROCESS(clock_100MHz)
        VARIABLE count_100000000: INTEGER RANGE 0 TO 50000000 := 50000000 ;  -- 1Hz clock : I have updated this to be a value of 50,000,000 rahter THEN 100,000,000 - Archie [NEW].
        VARIABLE counter_100000000: INTEGER RANGE 0 TO 50000000  := 0 ;        
    BEGIN
        IF (clock_100MHz'EVENT AND clock_100MHz='1') THEN
            IF (counter_100000000 = (count_100000000 - 1)) THEN            
                line_1Hz <= NOT line_1Hz;
                counter_100000000 := 0 ;
            END IF;
            counter_100000000 := counter_100000000 + 1;
        END IF;
    END PROCESS;


FREQ_50MHz: PROCESS(clock_100MHz)
        VARIABLE count_50000000 : INTEGER RANGE 0 TO 2 := 2 ; -- 0 to 1 DEC 
        VARIABLE counter_50000000 : INTEGER RANGE 0 TO 2 := 0 ;   
    BEGIN
        IF (clock_100MHz'EVENT AND clock_100MHz='1') THEN
            IF (counter_50000000 = (count_50000000 - 1)) THEN
                line_50MHz <= not line_50MHz ;
                counter_50000000 := 0 ;
            END IF ;
            counter_50000000 := counter_50000000 + 1 ;
        END IF ;
    END PROCESS ;
    
    
FREQ_10MHz: PROCESS(clock_100MHz)
            VARIABLE count_10_000_000 : INTEGER RANGE 0 TO 10 := 9 ; -- 0 to 9 DEC
            VARIABLE counter_10_000_000 : INTEGER RANGE 0 TO 10 := 0 ;   
        BEGIN
            IF (clock_100MHz'EVENT AND clock_100MHz='1') THEN
                IF (counter_10_000_000 = (count_10_000_000 - 1)) THEN
                    line_10MHz <= not line_10MHz ;
                    counter_10_000_000 := 0 ;
                END IF ;
                counter_10_000_000 := counter_10_000_000 + 1 ;
            END IF ;
        END PROCESS ;    
END clock_architecture;
