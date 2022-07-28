LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY srom IS
    PORT (
        data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) ; --make a process sensitive to this
        readme : OUT STD_LOGIC ;
        clock : IN STD_LOGIC ;
        reset : IN STD_lOGIC    --keep high to prevent data read
    );
END srom;



ARCHITECTURE srarch OF srom IS

    COMPONENT rom IS
    PORT (
        data_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) ;
        addr: IN STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
    END COMPONENT;

    SIGNAL address_bus : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL small_data_bus : STD_LOGIC_VECTOR(7 DOWNTO 0) ;
    
    SIGNAL temp_out : STD_LOGIC_VECTOR(31 DOWNTO 0) ;
    
    SIGNAL init_line : STD_LOGIC := '0' ;
            
BEGIN

--ADDRBUS: PROCESS(address_bus)
--    BEGIN
--        address_bus <= STD_LOGIC_VECTOR(idx) ;
--    END PROCESS;  
    
ROMSOURCING: PROCESS(clock)
        VARIABLE idx : UNSIGNED(2 DOWNTO 0) := "000" ;    --update idx_trigger anywhere this variable is changed
        VARIABLE cnt : INTEGER RANGE 0 TO 50 := 0 ;
    BEGIN
    
        address_bus <= STD_LOGIC_VECTOR(TO_UNSIGNED(cnt, 8)) ;
        
        IF (init_line='0') THEN
            data <= x"00000000" ;
            readme <= '0' ;
            init_line <= '1';
            
        ELSIF (reset = '1') THEN
            idx := "000" ;
            readme <= '1' ;
            data <= x"00000000" ;
            readme <= '0' ;
                     
        ELSIF (clock'EVENT AND clock='1' AND reset='0') THEN
            CASE idx IS
                WHEN "000" =>
                    temp_out(31 DOWNTO 24) <= small_data_bus ;
                    idx := "001" ;
                    cnt := cnt + 1 ;
                    readme <= '0' ;
                WHEN "001" =>
                    temp_out(23 DOWNTO 16) <= small_data_bus ;
                    idx := "010" ;
                    cnt := cnt + 1 ;
                    readme <= '0' ;
                WHEN "010" =>
                    temp_out(15 DOWNTO 8) <= small_data_bus ;
                    idx := "011" ;
                    cnt := cnt + 1 ;
                    readme <= '0' ;
                WHEN "011" =>
                    temp_out(7 DOWNTO 0) <= small_data_bus ;
                    idx := "100" ;
                    cnt := cnt + 1 ;
                    readme <= '0' ;
                WHEN "100" =>
                    data <= temp_out ;
                    readme <= '1' ;
                    cnt := cnt + 1 ;
                    idx := "000" ;
                WHEN "101" => --the remainder bytes
                    temp_out <= (
                        31=>small_data_bus(7), 
                        30=>small_data_bus(6),
                        29=>small_data_bus(5),
                        28=>small_data_bus(4),
                        27=>small_data_bus(3),
                        26=>small_data_bus(2),
                        25=>small_data_bus(1),
                        24=>small_data_bus(0),
                        others=>'0'
                    );
                    readme <= '1' ;
                    idx := "111" ;
                WHEN OTHERS =>
                    temp_out <= x"FFFFFFFF" ;   --end of data
                    readme <= '1' ;
                    data <= temp_out ;
            END CASE;
            
            IF (cnt = 45) THEN
                idx := "101" ;
                readme <= '1' ;
            END IF;
            
        END IF;
  
    END PROCESS;

MEMORYR: rom
PORT MAP(data_out => small_data_bus, addr => address_bus) ;

END srarch;