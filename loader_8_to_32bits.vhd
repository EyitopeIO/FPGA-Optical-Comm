
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY loader8_to_32 IS
    PORT (
        bits8 : IN STD_LOGIC_VECTOR(7 DOWNTO 0) ;
        clock : IN STD_LOGIC ;
        reset : IN STD_LOGIC ;
        ready : OUT STD_LOGIC ;
        load : IN STD_LOGIC ;
        bits32 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)        
    );
END loader8_to_32;

ARCHITECTURE loader832 OF loader8_to_32 IS
    SIGNAL output_line : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000" ;
    SIGNAL byten : UNSIGNED(2 DOWNTO 0) := "000" ;
BEGIN

    bits32 <= output_line ;

MAIN: PROCESS(clock, reset)
    BEGIN
        IF (reset='1') THEN
            output_line <= x"00000000" ;
            ready <= '0' ;
            byten <= "000" ;

        ELSIF RISING_EDGE(clock) THEN
            IF (load='1') THEN
                CASE byten IS
                    WHEN "000" =>
                        ready <= '0' ;
                        output_line(31 DOWNTO 24) <= bits8 ;
                        byten <= "001" ;                    
                    WHEN "001" =>
                        output_line(23 DOWNTO 16) <= bits8 ;
                        byten <= "010" ;
                    WHEN "010" =>
                        output_line(15 DOWNTO 8) <= bits8 ; 
                        byten <= "011" ;
                    WHEN "011" =>
                        output_line(7 DOWNTO 0) <= bits8 ;
                        byten <= "100" ;
                    WHEN "100" =>
                        ready <= '1' ;
                        byten <= "000" ;
                    WHEN OTHERS =>      --Not gonna happen
                        ready <= '1' ;
                END CASE;
            END IF;
        END IF;     
    END PROCESS;
END loader832;