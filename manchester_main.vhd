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
        clock_sel:  IN STD_LOGIC;
        man1_out:   OUT STD_LOGIC;
        man2_out:   OUT STD_LOGIC
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

    COMPONENT clock_divider IS
    PORT (
        clock_100MHz : IN STD_lOGIC;
        clock_50MHz : OUT STD_LOGIC ;
        clock_1Hz : OUT STD_lOGIC
    );
    END COMPONENT ;
    
    SIGNAL global_reset_line : STD_LOGIC ;
    SIGNAL master_clock_line : STD_LOGIC ;
    SIGNAL clock_50MHz_line : STD_LOGIC ;
    SIGNAL clock_1Hz_line : STD_LOGIC ;
    
    SIGNAL data_bus_line_for_randomgen1:         STD_LOGIC_VECTOR(ascii_gen_bus_width-1 DOWNTO 0);    --allow 0 - 255 random numbers only

    SIGNAL manchester1_write_control :    STD_LOGIC := '0' ;
    SIGNAL manchester2_write_control :    STD_LOGIC := '0' ;
    
    SIGNAL manchester1_ready_for_data_on_din : STD_LOGIC ;
    SIGNAL manchester2_ready_for_data_on_din : STD_LOGIC ;
    
    SIGNAL manchester1_overrun_error : STD_LOGIC ;
    SIGNAL manchester2_overrun_error : STD_LOGIC ;
    
    SIGNAL data_bus_line_for_man1_transmission:  STD_LOGIC_VECTOR(data_bus_width-1 DOWNTO 0);
    SIGNAL data_bus_line_for_man2_transmission:  STD_LOGIC_VECTOR(data_bus_width-1 DOWNTO 0);     

    SIGNAL main_data_bus_line_for_all : STD_LOGIC_VECTOR(31 DOWNTO 0) := "01010101010101010100111010101011" ; --arbitrary number
    
    SIGNAL data_bus_for_asciigen : STD_LOGIC_VECTOR(ascii_gen_bus_width-1 DOWNTO 0) ;
    
    TYPE BYTESEL IS (ZERO, ONE, TWO, THREE) ;
    SIGNAL BYTE : BYTESEL := ZERO ;

BEGIN

CLOCK_SELECT:    PROCESS(master_clock_line, clock_50MHz_line, clock_1Hz_line)
    BEGIN
        IF clock_sel = '1' THEN
            master_clock_line <= clock_50MHz_line ;
        ELSE
            master_clock_line <= clock_1Hz_line ;
        END IF ;
    END PROCESS ;
      
TRANSMISSION1:    PROCESS(master_clock_line, main_data_bus_line_for_all)
    BEGIN
        IF RISING_EDGE(master_clock_line) THEN
            IF manchester1_ready_for_data_on_din = '1' AND manchester1_overrun_error = '0' THEN
                manchester1_write_control <= '1' ; 
                data_bus_line_for_man1_transmission <= main_data_bus_line_for_all(31 DOWNTO 16) ;
            ELSE
                manchester1_write_control <= '0' ;
            END IF ;
        END IF ;
    END PROCESS ;

TRANSMISSION2:  PROCESS(master_clock_line, main_data_bus_line_for_all)
    BEGIN
        IF RISING_EDGE(master_clock_line) THEN
            IF manchester2_ready_for_data_on_din = '1' AND manchester2_overrun_error = '0' THEN
                manchester2_write_control <= '1' ; 
                data_bus_line_for_man2_transmission <= main_data_bus_line_for_all(15 DOWNTO 0) ;
            ELSE
                manchester2_write_control <= '0' ;
            END IF ;
        END IF ;
    END PROCESS ;   

DATABUS_LOADING: PROCESS (master_clock_line, data_bus_for_asciigen)
    BEGIN
        IF RISING_EDGE(master_clock_line) THEN
            CASE BYTE IS
                WHEN ZERO =>
                    main_data_bus_line_for_all(7 DOWNTO 0) <= data_bus_for_asciigen;
                    BYTE <= ONE ;
                WHEN ONE =>
                    main_data_bus_line_for_all(15 DOWNTO 8) <= data_bus_for_asciigen;
                    BYTE <= TWO ;  
                WHEN TWO =>
                    main_data_bus_line_for_all(23 DOWNTO 16) <= data_bus_for_asciigen;
                    BYTE <= THREE ;
                WHEN THREE =>
                    main_data_bus_line_for_all(31 DOWNTO 24) <= data_bus_for_asciigen;
                    BYTE <= ZERO ;
            END CASE ;
        END IF ;
    END PROCESS;
      
    
-------------------------------------------------------------------------------------------------------
-------------------------------------  PORT MAPS ------------------------------------------------------
-------------------------------------------------------------------------------------------------------

CLOCKDIV: clock_divider
PORT MAP (clock_100MHz => clock, clock_50MHz => clock_50MHz_line, clock_1Hz => clock_1Hz_line) ;

DATASRC: ascii_gen
GENERIC MAP ( data_bus_width => ascii_gen_bus_width )
PORT MAP (rand=>data_bus_for_asciigen, clock=>master_clock_line) ;


MANENCODE1: encode
PORT MAP (
    clk16x=>master_clock_line,
    srst=>reset,
    tx_data=>data_bus_line_for_man1_transmission,
    tx_stb=>manchester1_write_control,
    txd=>man1_out,
    or_err=> manchester1_overrun_error,
    tx_idle=>manchester1_ready_for_data_on_din
);

MANENCODE2: encode
PORT MAP (
    clk16x=>master_clock_line,
    srst=>reset,
    tx_data=>data_bus_line_for_man2_transmission,
    tx_stb=>manchester2_write_control,
    txd=>man2_out,
    or_err=> manchester2_overrun_error,
    tx_idle=>manchester2_ready_for_data_on_din
);

END monarch;