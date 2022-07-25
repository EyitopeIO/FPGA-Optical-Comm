LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY main IS
    GENERIC(
        master_clock        :   NATURAL     := 100_000_000;
        data_bus_width      :   NATURAL     := 16;
        ascii_gen_bus_width :   NATURAL     := 8;   --ideally should by related to data_bus_width by formula
        uart_baud_rate      :   INTEGER     := 9600
    );
    
    PORT (
        clock:      IN STD_LOGIC;
        reset:      IN STD_LOGIC;
        --ppm_out:    OUT STD_LOGIC;
        man_out:    OUT STD_LOGIC
        ---ppm_in:     IN STD_LOGIC;
        --man_in:     IN STD_LOGIC
    );
END main;


ARCHITECTURE monarch OF main IS

    COMPONENT ascii_gen IS
        GENERIC (
            data_bus_width  :   NATURAL     --defined IN top module
        ); 
        PORT (
            rand:   OUT std_logic_vector(data_bus_width-1 DOWNTO 0);
            clock:  IN STD_LOGIC
        );
    END COMPONENT;

    COMPONENT encode IS 
    Port (
        clk16x : in STD_LOGIC;
        srst : in STD_LOGIC;
        tx_data : in STD_LOGIC_VECTOR (15 downto 0);
        tx_stb : in STD_LOGIC;
        txd : out STD_LOGIC;
        or_err : out STD_LOGIC;
        tx_idle : out STD_LOGIC
      );
    END COMPONENT;

    SIGNAL global_reset_line : STD_LOGIC ;
    
    SIGNAL data_bus_line_for_randomgen:         STD_LOGIC_VECTOR(ascii_gen_bus_width-1 DOWNTO 0);    --allow 0 - 255 random numbers only

    SIGNAL manchester_write_control :    STD_LOGIC := '0';
    SIGNAL manchester_ready_for_data_on_din : STD_LOGIC;
    SIGNAL data_bus_line_for_transmission:  STD_LOGIC_VECTOR(data_bus_width-1 DOWNTO 0);     

BEGIN

    global_reset_line <= reset ;
    data_bus_line_for_transmission(data_bus_width-1 DOWNTO ascii_gen_bus_width) <= "00000000";

    PROCESS(clock)  --Continuous transmission so long as encoder is ready ;
    BEGIN
        IF (manchester_ready_for_data_on_din='1') THEN
            manchester_write_control <= '1' ;
            data_bus_line_for_transmission(ascii_gen_bus_width-1 DOWNTO 0) <= data_bus_line_for_randomgen ;
        ELSE
            manchester_write_control <= '0' ;
        END IF ;
    END PROCESS ;

-------------------------------------------------------------------------------------------------------
-------------------------------------  PORT MAPS ------------------------------------------------------
-------------------------------------------------------------------------------------------------------

DATASRC: ascii_gen
GENERIC MAP ( data_bus_width => ascii_gen_bus_width )
PORT MAP (rand=>data_bus_line_for_randomgen, clock=>clock) ;

MANENCODE: encode
PORT MAP (
    clk16x=>clock,
    srst=>global_reset_line,
    tx_data=>data_bus_line_for_transmission,
    tx_stb=>manchester_write_control,
    txd=>man_out,
    or_err=>OPEN,
    tx_idle=>manchester_ready_for_data_on_din
) ;

END monarch;