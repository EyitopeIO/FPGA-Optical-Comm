
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY clock_divider IS
    PORT (
        clock_100MHz    :   IN STD_lOGIC;
        clock_1p3615MHz : OUT STD_LOGIC ;
        clock_1Hz:   OUT STD_lOGIC
    );
END clock_divider;


ARCHITECTURE clock_architecture OF clock_divider IS
    SIGNAL line_1Hz :   STD_LOGIC := '0' ;
    SIGNAL line_1p3615MHz : STD_LOGIC := '0' ;
BEGIN
    clock_1Hz <= line_1Hz ;
    clock_1p3615MHz <= line_1p3615MHz ;
   
    
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
    
    -- Clock for something around (not accurate) 1.3615MHz. The manchester encoder used requires an input clock of 19.45 * output data clock 
FREQ_1p3615MHz: PROCESS(clock_100MHz)
            VARIABLE count_1p3615MHz : INTEGER RANGE 0 TO 45 := 45 ; -- 0 to 9 DEC 73 dev. 2 ~~ 36, but using 45
            VARIABLE counter_1p3615MHz : INTEGER RANGE 0 TO 45 := 0 ;   
        BEGIN
            IF (clock_100MHz'EVENT AND clock_100MHz='1') THEN
                IF (counter_1p3615MHz = (count_1p3615MHz - 1)) THEN
                    line_1p3615MHz <= not line_1p3615MHz ;
                    counter_1p3615MHz := 0 ;
                END IF ;
                counter_1p3615MHz := counter_1p3615MHz + 1 ;
            END IF ;
        END PROCESS ;    
END clock_architecture;
