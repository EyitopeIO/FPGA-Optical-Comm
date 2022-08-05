LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY srom IS
    PORT (
        data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) ; --make a process sensitive to this
        querry :IN STD_LOGIC ;
        clock : IN STD_LOGIC ;
        reset : IN STD_lOGIC    --keep high to prevent data read
    );
END srom;



ARCHITECTURE srarch OF srom IS

    COMPONENT rom IS
    PORT (
        data_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) ;
        addr: IN STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
    END COMPONENT;

    SIGNAL address_bus : STD_LOGIC_VECTOR(3 DOWNTO 0) ; --Address bus dependent on variable cnt. Don't initialise this
    SIGNAL data_bus : STD_LOGIC_VECTOR(31 DOWNTO 0) ;
            
BEGIN

ROMSOURCING: PROCESS(clock)
        VARIABLE cnt : INTEGER RANGE 0 TO 12 := 0 ;
    BEGIN 
    
        address_bus <= STD_LOGIC_VECTOR(TO_UNSIGNED(cnt, 4)) ;
         
        IF (reset = '1') THEN  
            data <= x"00000000" ;
            cnt := 0 ;
                   
        ELSIF (clock'EVENT AND clock='1') THEN
            IF (querry='1') THEN
                data <= data_bus ;
                IF (cnt < 12) THEN  -- address above 11 causes FF... on data bus
                    cnt := cnt + 1 ;
                END IF;
            END IF;
        END IF;
    END PROCESS;

MEMORYR: rom
PORT MAP(data_out => data_bus, addr => address_bus) ;

END srarch;