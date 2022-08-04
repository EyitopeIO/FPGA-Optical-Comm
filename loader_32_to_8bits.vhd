
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY loader32_to_8 IS
    PORT (
        bits8 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) ;
        clock : IN STD_LOGIC ;
        reset : IN STD_LOGIC ;
        ready : OUT STD_LOGIC ;
        fetch : IN STD_LOGIC ;
        bits32 : IN STD_LOGIC_VECTOR(31 DOWNTO 0)        
    );
END loader32_to_8;

ARCHITECTURE loader328 OF loader32_to_8 IS
    SIGNAL input_line : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000" ;
    SIGNAL byten : UNSIGNED(2 DOWNTO 0) := "111" ;
BEGIN

MAIN: PROCESS(clock, reset)
    BEGIN
        IF (reset='1') THEN
            bits8 <= x"00" ;
            ready <= '0' ;
            byten <= "111" ;

        ELSIF RISING_EDGE(clock) THEN
            IF (fetch='1') THEN      

                CASE byten IS
                
                    WHEN "111" =>
                        input_line <= bits32 ;
                        byten <= "000" ;
                    WHEN "000" =>       --The first byte in 32bits
                        ready <= '1' ;
                        bits8 <= input_line(31 DOWNTO 24) ;
                        byten <= "001" ;                    
                    WHEN "001" =>
                        ready <= '0' ;
                        bits8 <= input_line(23 DOWNTO 16) ;
                        byten <= "010" ;
                    WHEN "010" =>
                        bits8 <= input_line(15 DOWNTO 8) ; 
                        byten <= "011" ;
                    WHEN "011" =>
                        bits8 <= input_line(7 DOWNTO 0) ;
                        byten <= "111" ;
                    WHEN OTHERS =>  --Never happening
                        ready <= '0' ;
                END CASE;
            END IF;
        END IF;
        
    END PROCESS;
END loader328;