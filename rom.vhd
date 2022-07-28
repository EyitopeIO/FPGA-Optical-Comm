LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY rom IS
    PORT (
        data_out : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) ;  --32 bits
        addr: IN STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END rom;


ARCHITECTURE romarch OF rom IS
    TYPE ro_memory IS ARRAY (0 TO 45) OF STD_LOGIC_VECTOR(7 DOWNTO 0) ;
    CONSTANT bytesel : ro_memory := (  
        --{'RPM':35,'NMD':2900,'SPD':120,'HLS':5,'BP':7}  
        x"7B", x"27", x"52", x"50", x"4D", x"27", x"3A", x"33", x"35",
        x"2C", x"27", x"4E", x"4D", x"44", x"27", x"3A", x"32", x"39",       
        x"30", x"30", x"2C", x"27", x"53", x"50", x"44", x"27", x"3A",   
        x"31", x"32", x"30", x"2C", x"27", x"48", x"4C", x"53", x"27",
        x"3A", x"35", x"2C", x"27", x"42", x"50", x"27", x"3A", x"37",
        x"7D"
    );
BEGIN
    data_out <= bytesel(TO_INTEGER(UNSIGNED(addr))) ;
END romarch ;
                            

