LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY main IS

    GENERIC(
        master_clock   :   NATURAL := 100_000_000 ;
        uart_baud_rate :   INTEGER := 19200 ;
        uart_d_width   :   NATURAL := 8
    );
    
    PORT (
        man1_out : OUT STD_LOGIC ;
        man2_out : OUT STD_LOGIC ;

        uart_tx : OUT STD_LOGIC ;
        uart_rx : IN STD_LOGIC ;

        clock : IN STD_LOGIC ;
        reset : IN STD_LOGIC ; 

        led_idle : OUT STD_LOGIC ;
        overrun : OUT STD_LOGIC ;
        
        Anode_Activate : OUT STD_LOGIC_VECTOR (3 DOWNTO 0) ;
        LED_out : OUT STD_LOGIC_VECTOR (6 DOWNTO 0)     
    );
    
END main;


ARCHITECTURE jumpstart OF main IS

    COMPONENT mantx IS
    --GENERIC (data_bus_width : NATURAL := 32 );
    PORT (
        clock_100MHz : IN STD_LOGIC ;
        clock_1p3615MHz : IN STD_LOGIC ;

        data_bus : STD_LOGIC_VECTOR(31 DOWNTO 0) ;

        man1_out : OUT STD_LOGIC ;     
        man2_out : OUT STD_LOGIC ;
        
        start_tx : IN STD_LOGIC ;
        reset :      IN STD_LOGIC ; 
        
        overload : OUT STD_LOGIC ;
        led_idle : OUT STD_LOGIC  
    );
    END COMPONENT;
    ----------------------------------------------
    ----------------------------------------------
    COMPONENT lcdbox IS
    PORT (
        rst :            IN STD_LOGIC ;         
        number :         IN STD_LOGIC_VECTOR(15 DOWNTO 0) ;
        LED_out :        OUT STD_LOGIC_VECTOR (6 DOWNTO 0) ; 
        clock_100Mhz :   IN STD_LOGIC ;
        Anode_Activate : OUT STD_LOGIC_VECTOR (3 DOWNTO 0)
    );
    END COMPONENT;
    ---------------------------------------------
    ---------------------------------------------
    COMPONENT clock_divider IS
    PORT (
        clock_100MHz :    IN STD_lOGIC ;
        clock_1p3615MHz : OUT STD_LOGIC ;
        clock_1Hz :       OUT STD_lOGIC
    );
    END COMPONENT ;
    ----------------------------------------------
    ----------------------------------------------
    COMPONENT uart IS
    GENERIC(
          clk_freq  :  INTEGER ; 
          baud_rate :  INTEGER ;     
          d_width   :  INTEGER         
    );
    PORT(
        clk      :  IN   STD_LOGIC;                             
        tx_ena   :  IN   STD_LOGIC;                             
        tx_data  :  IN   STD_LOGIC_VECTOR(uart_d_width-1 DOWNTO 0);  
        rx       :  IN   STD_LOGIC;                          
        rx_busy  :  OUT  STD_LOGIC;                           
        rx_error :  OUT  STD_LOGIC;                             
        rx_data  :  OUT  STD_LOGIC_VECTOR(uart_d_width-1 DOWNTO 0); 
        tx_busy  :  OUT  STD_LOGIC;                           
        tx       :  OUT  STD_LOGIC                          
    );
    END COMPONENT;
    --------------------------------------------- 
    ---------------------------------------------
    COMPONENT loader8_to_32 IS
    PORT (
        bits8 :  IN STD_LOGIC_VECTOR(7 DOWNTO 0) ;
        clock :  IN STD_LOGIC ;
        reset :  IN STD_LOGIC ;
        ready :  OUT STD_LOGIC ;
        load :   IN STD_LOGIC ;
        bits32 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)        
    );
    END COMPONENT;
    
    ----------------------------------------------------------
    ----------------------- SIGNALS AND DEFS ------------------
    --------------------------------------------------------

    SIGNAL reset_line : STD_LOGIC := '0' ;
    SIGNAL ground_line : STD_LOGIC := '0' ;
    
    SIGNAL fpga_clock : STD_LOGIC ;
    SIGNAL manchester_clock : STD_LOGIC ;
    SIGNAL standby_clock : STD_LOGIC ;
    
    SIGNAL man1_temp_output : STD_LOGIC ;
    SIGNAL man2_temp_output : STD_LOGIC ;
    SIGNAL man_overload : STD_LOGIC ;
    SIGNAL man_idle : STD_LOGIC ;
    
    SIGNAL e_choke : STD_LOGIC ;     --Flag a bottle neck somewhere in the pipeline

    SIGNAL uart_rx_error : STD_LOGIC ;
    SIGNAL uart_rx_busy : STD_LOGIC ;
    SIGNAL begin_transmission : STD_LOGIC := '0' ;

    SIGNAL main_data_bus : STD_LOGIC_VECTOR(31 DOWNTO 0) ;
    SIGNAL uart_data_bus : STD_LOGIC_VECTOR(uart_d_width-1 DOWNTO 0) ;

    SIGNAL loader_is_ready : STD_LOGIC ; 
    SIGNAL loader_activate : STD_LOGIC ;

BEGIN

    -- To drive 5V logic with 3.3V FPGA output using logic shifter with NPN transistor
    man1_out <= not man1_temp_output ;
    man2_out <= not man2_temp_output ;

    fpga_clock <= clock ;
    reset_line <= reset ; 

    
MAIN: PROCESS(clock, reset)
    BEGIN
    END PROCESS;          


STANDBY: PROCESS(standby_clock)
    BEGIN
    END PROCESS;

-------------------------------------------------------------------------------------------------------
-------------------------------------  PORT MAPS ------------------------------------------------------
-------------------------------------------------------------------------------------------------------

PCCONN: uart
GENERIC MAP (clk_freq => master_clock, baud_rate => uart_baud_rate, d_width => uart_d_width)
PORT MAP (
    clk => fpga_clock,  
    tx_ena => ground_line, 
    tx_data => (OTHERS=>'0'),
    rx => uart_rx, 
    rx_busy => uart_rx_busy, 
    rx_error => uart_rx_error, 
    rx_data => uart_data_bus,
    tx_busy => OPEN,
    tx => uart_tx
);                           

CLOCKDIV: clock_divider
PORT MAP (
    clock_100MHz => fpga_clock,    
    clock_1p3615MHz => manchester_clock,
    clock_1Hz => standby_clock  
);

TRANSMITTER: mantx
PORT MAP (
    clock_100MHz => fpga_clock,
    clock_1p3615MHz => manchester_clock, 
    data_bus => main_data_bus, 
    man1_out => man1_out,
    man2_out => man2_out, 
    start_tx => begin_transmission, 
    reset => reset_line,   
    overload => man_overload, 
    led_idle => man_idle
);

BITCONN: loader8_to_32
PORT MAP (
    bits8 => uart_data_bus, 
    clock => fpga_clock, 
    reset => reset_line,
    ready => loader_is_ready,
    load => loader_activate, 
    bits32 => main_data_bus        
);

END jumpstart;