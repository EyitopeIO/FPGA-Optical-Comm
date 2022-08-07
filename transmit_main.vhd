LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY main IS

    GENERIC(
        master_clock   :   NATURAL := 100_000_000 ;
        uart_baud_rate :   INTEGER := 9600 ;
        uart_d_width   :   NATURAL := 8
    );
    
    PORT (
        manchester1 : OUT STD_LOGIC ;
        manchester2 : OUT STD_LOGIC ;

        uart_tx : OUT STD_LOGIC ;
        uart_rx : IN STD_LOGIC ;

        clock : IN STD_LOGIC ;
        reset : IN STD_LOGIC ; 

        standby : OUT STD_LOGIC ;

        uart_error : OUT STD_LOGIC ;
        manc_error : OUT STD_LOGIC ;
        
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
    signal init_line : STD_LOGIC := '0' ;
    
    SIGNAL fpga_clock : STD_LOGIC ;
    SIGNAL manchester_clock : STD_LOGIC ;
    SIGNAL standby_clock : STD_LOGIC ;
    
    SIGNAL man_overload : STD_LOGIC ;
    SIGNAL man_idle : STD_LOGIC ;
    
    SIGNAL e_choke : STD_LOGIC ;     --Flag a bottle neck somewhere in the pipeline

    SIGNAL uart_rx_error : STD_LOGIC ;
    SIGNAL uart_rx_busy : STD_LOGIC ;
    SIGNAL uart_tx_busy : STD_LOGIC ;
    SIGNAL uart_tx_ena : STD_LOGIC := '0' ;
    SIGNAL uart_data_bus_rx : STD_LOGIC_VECTOR(uart_d_width-1 DOWNTO 0) ;
    SIGNAL uart_data_bus_tx : STD_LOGIC_VECTOR(uart_d_width-1 DOWNTO 0) ;
    SIGNAL uart_data_next : STD_LOGIC_VECTOR(uart_d_width-1 DOWNTO 0) ;
    SIGNAL uart_tx_pending : STD_LOGIC := '0' ;

    SIGNAL begin_transmission : STD_LOGIC := '0' ;

    SIGNAL main_data_bus : STD_LOGIC_VECTOR(31 DOWNTO 0) ;

    SIGNAL loader_is_ready : STD_LOGIC ; 
    SIGNAL loader_activate : STD_LOGIC ;
    
    SIGNAL txstate : UNSIGNED(2 DOWNTO 0) := "000" ;

    --SIGNAL dnumber : UNSIGNED(15 DOWNTO 0) := x"0000" ;
    SIGNAL vnumber : STD_LOGIC_VECTOR(15 DOWNTO 0) ;
    
        
BEGIN

    fpga_clock <= clock ;

    uart_error <= '1' WHEN uart_rx_error='1' ELSE '0' ;
    manc_error <= '1' WHEN man_overload='1' ELSE '0' ;
    standby <= standby_clock WHEN man_idle='1' ELSE '1' ;  
    
MAIN: PROCESS(fpga_clock, reset)
    BEGIN
        IF (init_line='0') THEN         --One-time setup here
            reset_line <= '0' ;
            init_line <= '1' ;
            
        ELSIF (reset='1') THEN 
            reset_line <= '1' ;
            reset_line <= '1' ;
            
        ELSIF (RISING_EDGE(fpga_clock)) THEN
           reset_line <= '0' ;
           
           CASE txstate IS
--------------------------------------------------------------           
            WHEN "000" =>       --Waiting for receive activity
                IF (uart_rx_busy='1') THEN
                    txstate <= "001" ;
                END IF;
 -------------------------------------------------------------                                 
            WHEN "001" =>       --Waiting for UART to receive 8 bits
                IF (uart_rx_busy='0') THEN      --8 bits ready on bus

                    uart_tx_pending <= '1' ;

                    loader_activate <= '1' ;
                    txstate <= "010" ;

                    IF (loader_is_ready='1' AND man_idle='1') THEN
                        begin_transmission <= '1' ;
                    END IF;
                END IF;

 ------------------------------------------------------------                              
            WHEN "010" =>       --Return to waiting state
                uart_tx_pending <= '0' ;
                loader_activate <= '0' ;
                begin_transmission <= '0' ;
                txstate <= "000" ;
 -----------------------------------------------------------               
            WHEN "011" =>       --Initiate transmission
            WHEN "100" =>       --End
            WHEN OTHERS =>
           END CASE;
        END IF;
    END PROCESS;          


FBTX: PROCESS(fpga_clock)
    BEGIN
        IF (uart_tx_pending='1') THEN  
            uart_data_bus_tx <= uart_data_bus_rx ;           
            uart_tx_ena <= '1' ;
        ELSE
            uart_tx_ena <= '0' ;
        END IF;
    END PROCESS;


-------------------------------------------------------------------------------------------------------
-----------------------------------(--  PORT MAPS ------------------------------------------------------
-------------------------------------------------------------------------------------------------------

PCCONN: uart
GENERIC MAP (clk_freq => master_clock, baud_rate => uart_baud_rate, d_width => uart_d_width)
PORT MAP (
    clk => fpga_clock,  
    tx_ena => uart_tx_ena, 
    tx_data => uart_data_bus_tx,
    rx => uart_rx, 
    rx_busy => uart_rx_busy, 
    rx_error => uart_rx_error, 
    rx_data => uart_data_bus_rx,
    tx_busy => uart_tx_busy,
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
    man1_out => manchester1,
    man2_out => manchester2, 
    start_tx => begin_transmission, 
    reset => reset_line,   
    overload => man_overload, 
    led_idle => man_idle
);

BITCONN: loader8_to_32
PORT MAP (
    bits8 => uart_data_bus_rx, 
    clock => fpga_clock, 
    reset => reset_line,
    ready => loader_is_ready,
    load => loader_activate, 
    bits32 => main_data_bus        
);

DISPLAY: lcdbox
PORT MAP (
    rst => reset_line,       
    number => vnumber,
    LED_out => LED_out, 
    clock_100Mhz => fpga_clock,
    Anode_Activate => Anode_Activate
);

END jumpstart;