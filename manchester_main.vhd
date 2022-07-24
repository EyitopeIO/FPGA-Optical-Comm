LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY main IS
    GENERIC(
        master_clock        :   NATURAL     := 100_000_000;
        data_bus_width      :   NATURAL     := 8;
        ascii_gen_bus_width :   NATURAL     := 8;   --ideally should by related to data_bus_width by formula
        uart_baud_rate      :   INTEGER     := 9600
    );
    
    PORT (
        clock:      IN STD_LOGIC;
        reset:      IN STD_LOGIC;
        --ppm_out:    OUT STD_LOGIC;
        man_out:    OUT STD_LOGIC;
        ---ppm_in:     IN STD_LOGIC;
        --man_in:     IN STD_LOGIC
    );
END main;


ARCHITECTURE monarch OF main is

    COMPONENT ascii_gen IS
        GENERIC (
            data_bus_width  :   NATURAL     --defined IN top module
        ); 
        PORT (
            rand:   OUT std_logic_vector(data_bus_width-1 DOWNTO 0);
            clock:  IN STD_LOGIC
        );
    END COMPONENT;

    COMPONENT me IS 
        PORT (
            rst, clk16x, wrn : STD_LOGIC;
            din : IN STD_LOGIC_VECTOR(ascii_gen_bus_width-1 DOWNTO 0) ;
            tbre : OUT STD_LOGIC;
            mdo : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL data_bus_line_for_randomgen:         STD_LOGIC_VECTOR(ascii_gen_bus_width-1 DOWNTO 0);    --allow 0 - 255 random numbers only

    SIGNAL manchester_write_control :    STD_LOGIC := '0';
    SIGNAL manchester_ready_for_data_on_din : STD_LOGIC;
    SIGNAL data_bus_line_for_transmission:  STD_LOGIC_VECTOR(data_bus_width-1 DOWNTO 0);     

BEGIN

    PROCESS(clock, data_bus_line_for_randomgen)  --Continuous transmission so long as encoder is ready.
        VARIABLE clock_count : UNSIGNED (data_bus_width-1 DOWNTO 0) := 0 ;
    BEGIN
        IF reset = '0' THEN

            IF manchester_ready_for_data_on_din = '1' THEN
                clock_count <= 100 ;
                manchester_write_control <= '1' ;            
                data_bus_line_for_transmission <= STD_LOGIC_VECTOR(clock_count) ;
            ELSE
                manchester_write_control <= '0' ;
                clock_count <= 0 ;            
            END IF ;
    
        END IF ;
    END PROCESS ;



-------------------------------------------------------------------------------------------------------
-------------------------------------  PORT MAPS ------------------------------------------------------
-------------------------------------------------------------------------------------------------------


DATASRC: ascii_gen
GENERIC MAP ( data_bus_width => ascii_gen_bus_width )
PORT MAP (rand=>data_bus_line_for_randomgen, clock=>clock) ;

MANENCODE: me
PORT MAP (rst=>reset, clk16x=>clock, wrn=>manchester_write_control, din=>data_bus_line_for_transmission, tbre=>manchester_ready_for_data_on_dout, mdo=>man_out) ;


END monarch;