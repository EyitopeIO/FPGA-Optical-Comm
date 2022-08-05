LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY rom IS
    PORT (
        data_out : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) ;  --32 bits
        addr: IN STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END rom;


ARCHITECTURE romarch OF rom IS
    TYPE ro_memory IS ARRAY (0 TO 11) OF STD_LOGIC_VECTOR(31 DOWNTO 0) ;
    CONSTANT bytesel : ro_memory := (  

        --{'RPM':35,'NMD':2900,'SPD':120,'HLS':5,'BP':7} 

        x"7B275250", x"4D273A33", x"352C274E", x"4D44273A", x"32393030",
        x"2C275350", x"44273A31", x"32302C27", x"484C5327", x"3A352C27", 
        x"4250273A", x"377D0000"
    );
BEGIN
    data_out <= bytesel(TO_INTEGER(UNSIGNED(addr))) WHEN UNSIGNED(addr) < 12 ELSE x"FFFFFFFF" ;
END romarch ;
                            

