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
        --ppm_in:     IN STD_LOGIC;
        --man_in:     IN STD_LOGIC
    );
END main;

ARCHITECTURE monarch OF main is
    COMPONENT Manchester IS
        PORT (
            clk16x :    IN STD_LOGIC;
            srst :      IN STD_LOGIC;
            rxd :       IN STD_LOGIC;
            rx_data :   OUT STD_LOGIC_VECTOR (15 downto 0);
            rx_stb :    OUT STD_LOGIC;
            rx_idle :   OUT STD_LOGIC;
            fm_err :    OUT STD_LOGIC;
            txd :       OUT STD_LOGIC;
            tx_data :   IN STD_LOGIC_VECTOR (15 downto 0);
            tx_stb :    IN STD_LOGIC;
            tx_idle :   OUT STD_LOGIC;
            or_err :    OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT ascii_gen IS
        GENERIC (
            data_bus_width  :   NATURAL     --defined IN top module
        ); 
        PORT (
            rand:   OUT std_logic_vector(data_bus_width-1 DOWNTO 0);
            clock:  IN STD_LOGIC
        );
    END COMPONENT;

    COMPONENT clock_divider IS
        PORT (
            clock_100MHz    :   IN STD_lOGIC;
            clock_1Hz       :   OUT STD_lOGIC
        );
    END COMPONENT;

    SIGNAL data_bus_line_for_randomgen:         STD_LOGIC_VECTOR(ascii_gen_bus_width-1 DOWNTO 0);    --allow 0 - 255 random numbers only
    SIGNAL data_bus_line_for_transmission:      STD_LOGIC_VECTOR(data_bus_width-1 DOWNTO 0);     

    SIGNAL transmit_interval_line:          STD_LOGIC;  --send data whenever this clock changes              

    SIGNAL manchester_transmit_data_line:   STD_LOGIC_VECTOR(data_bus_width-1 DOWNTO 0);

    SIGNAL begin_manchester_transmission:       STD_LOGIC   := '0';    


BEGIN
    
    data_bus_line_for_transmission(data_bus_width-1 DOWNTO ascii_gen_bus_width) <= (others => '0');

    manchester_transmit_data_line <= data_bus_line_for_transmission;

    PROCESS(clock, data_bus_line_for_randomgen)
    BEGIN
        data_bus_line_for_transmission(ascii_gen_bus_width-1 DOWNTO 0) <= data_bus_line_for_randomgen;
    END PROCESS;



-------------------------------------------------------------------------------------------------------
-------------------------------------  PORT MAPS ------------------------------------------------------
-------------------------------------------------------------------------------------------------------

CLOCKDIV: clock_divider
PORT MAP (
    clock_100MHz => clock,
    clock_1Hz => transmit_interval_line
);

DATASRC: ascii_gen
GENERIC MAP ( data_bus_width => ascii_gen_bus_width )
PORT MAP (
    rand => data_bus_line_for_randomgen,
    clock => transmit_interval_line
);

MANSTER: Manchester
PORT MAP (
    clk16x => clock,
    srst => reset,
    rxd => 'U',
    rx_data => OPEN,
    rx_stb => OPEN,
    rx_idle => OPEN,
    fm_err => OPEN,
    txd => man_out,
    tx_data => manchester_transmit_data_line,
    tx_stb => begin_manchester_transmission,
    tx_idle => OPEN,
    or_err => OPEN
);

END monarch;