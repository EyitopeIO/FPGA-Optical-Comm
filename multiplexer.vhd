LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY mux is
    GENERIC (
        data_bus_width   :   NATURAL := 32
    );
    PORT (
        sel :   IN STD_LOGIC;
        a   :   IN  STD_LOGIC_VECTOR (data_bus_width-1 DOWNTO 0);
        b   :   IN STD_LOGIC_VECTOR (data_bus_width-1 DOWNTO 0);
        x   :   OUT STD_LOGIC_VECTOR (data_bus_width-1 DOWNTO 0)
    );
END mux;

ARCHITECTURE muxarch OF mux IS
BEGIN
    x <= a WHEN (sel = '1') ELSE b ;
END muxarch;