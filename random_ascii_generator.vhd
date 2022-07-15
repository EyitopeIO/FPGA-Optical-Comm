library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


ENTITY ascii_gen IS
    GENERIC (
        data_bus_width  :   NATURAL     --defined in top module
    ); 
    PORT (
        rand:   OUT std_logic_vector(data_bus_width DOWNTO 0);
        clock:  IN std_logic
    );
END ascii_gen;

ARCHITECTURE ascii_gen_arch OF ascii_gen IS
    SIGNAL state_now, state_next:   std_logic_vector(data_bus_width DOWNTO 0) := "10101011";
    SIGNAL feedback:                std_logic;
    SIGNAL clock_line:              std_logic;           
BEGIN
    PROCESS(clock_line, state_now, state_next)
    BEGIN
        IF rising_edge(clock_line) THEN
            state_now <= state_next;
        END IF;
    END PROCESS;
    rand <= state_now;
    clock_line <= clock;
    feedback <= state_now(7) XOR state_now(1);
    state_next <= feedback & state_now(7 DOWNTO 1);
    
END ascii_gen_arch;