LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY mainR IS
    GENERIC(
        master_clock        :   NATURAL     := 100_000_000;
        data_bus_width      :   NATURAL     := 16;
        uart_d_width        :   NATURAL     := 8;
        uart_baud_rate      :   INTEGER     := 115200;
        memory_size         :   INTEGER     := 403
    );
    
    PORT (
        clock:      IN STD_LOGIC;
        man1_in:   IN STD_LOGIC; --connect to high speed port
        man2_in:   IN STD_LOGIC;        
        reset :      IN STD_LOGIC;
        rx_mode : IN STD_LOGIC ;

        uart_rx : IN STD_LOGIC ;
        uart_tx : OUT STD_LOGIC ;
        
        led_idle : OUT STD_LOGIC ;
        overload : OUT STD_LOGIC ;   --High when symbol errors to much

        anode : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) ;
        cathode : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
    );
    
END mainR;

ARCHITECTURE monarch OF mainR IS
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
    COMPONENT loader32_to_8 IS
    PORT (
        bits8 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) ;
        clock : IN STD_LOGIC ;
        reset : IN STD_LOGIC ;
        ready : OUT STD_LOGIC ;
        fetch : IN STD_LOGIC ;
        bits32 : IN STD_LOGIC_VECTOR(31 DOWNTO 0)        
    );
    END COMPONENT;

    COMPONENT decode IS 
    PORT (
        clk16x : in STD_LOGIC;
        srst : in STD_LOGIC;
        rxd : in STD_LOGIC;
        rx_data : out STD_LOGIC_VECTOR (15 downto 0);
        rx_stb : out STD_LOGIC;
        fm_err : out STD_LOGIC;
        rx_idle : out STD_LOGIC
    );
    END COMPONENT;

    COMPONENT srom IS
    PORT (
        data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) ; --make a process sensitive to this
        querry : IN STD_LOGIC ;
        clock : IN STD_LOGIC ;
        reset : IN STD_lOGIC    --keep high to prevent data read
    );
    END COMPONENT;

    COMPONENT clock_divider IS
     PORT (
        clock_100MHz : IN STD_lOGIC;
        clock_10MHz : OUT STD_LOGIC ;
        clock_70kHz : OUT STD_LOGIC ;
        clock_1Hz : OUT STD_lOGIC
    );
    END COMPONENT ;
    
    COMPONENT lcdbox IS
    PORT (
        number : IN STD_LOGIC_VECTOR(15 DOWNTO 0) ;
        clock_100Mhz : IN STD_LOGIC ;
        rst : IN STD_LOGIC ;         
        Anode_Activate : OUT STD_LOGIC_VECTOR (3 DOWNTO 0) ;  -- 4 Anode signals
        LED_out : OUT STD_LOGIC_VECTOR (6 DOWNTO 0)  -- Cathode patterns of 7-segment display
    );
    END COMPONENT;
    
    SIGNAL global_reset_line : STD_LOGIC := '0' ;
    SIGNAL idle_line : STD_LOGIC := '1' ;
    SIGNAL init_line : STD_LOGIC := '0' ;

    SIGNAL clock_1Hz_line : STD_LOGIC ;
    SIGNAL clock_70kHz_line : STD_LOGIC ;
    SIGNAL clock_1p3615MHz : STD_LOGIC ;
        
    SIGNAL manchester1_received_stopbit : STD_LOGIC ;
    SIGNAL manchester2_received_stopbit : STD_LOGIC ;
    
    -- To account for the NPN transistor to shift the 5V logic from light sensor to 3.3V
    SIGNAL man1_temp : STD_LOGIC ;
    SIGNAL man2_temp : STD_LOGIC ;

    SIGNAL manchester1_idle : STD_LOGIC ;
    SIGNAL manchester2_idle : STD_LOGIC ;
    
    SIGNAL manchester1_frame_error : STD_LOGIC ;
    SIGNAL manchester2_frame_error : STD_LOGIC ;    

    SIGNAL data_bus_line_for_man1_reception:  STD_LOGIC_VECTOR(data_bus_width-1 DOWNTO 0);
    SIGNAL data_bus_line_for_man2_reception:  STD_LOGIC_VECTOR(data_bus_width-1 DOWNTO 0); 

    SIGNAL main_data_bus_line_for_all_in : STD_LOGIC_VECTOR(31 DOWNTO 0) ;
    SIGNAL temp_trans_in : STD_LOGIC_VECTOR(31 DOWNTO 0) ;

    SIGNAL srom_reset : STD_LOGIC ;
    SIGNAL srom_querry : STD_LOGIC ; 
    
    SIGNAL rxaction : UNSIGNED(2 DOWNTO 0) := "000" ;

    SIGNAL symbols_equal : STD_LOGIC := '0' ;
    SIGNAL symbol_error_count : UNSIGNED(15 DOWNTO 0) := x"0000" ;  --Also used as displayed number    
    SIGNAL symbol_count_reset : STD_LOGIC := '0' ;
    SIGNAL symbol_count : INTEGER RANGE 0 TO 65536 := 0 ;      --Used in manual mode only

    SIGNAL statusvis : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0000" ;
    SIGNAL statusaction : STD_LOGIC := '0' ;
    
    SIGNAL display_bus : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0000" ;
    

    SIGNAL uart_rx_error : STD_LOGIC ;
    SIGNAL uart_rx_busy : STD_LOGIC ;
    SIGNAL uart_tx_busy : STD_LOGIC ;
    SIGNAL uart_tx_ena : STD_LOGIC := '0' ;
    SIGNAL uart_data_bus_rx : STD_LOGIC_VECTOR(uart_d_width-1 DOWNTO 0) ;
    SIGNAL uart_data_bus_tx : STD_LOGIC_VECTOR(uart_d_width-1 DOWNTO 0) ;
    SIGNAL uart_data_next : STD_LOGIC_VECTOR(uart_d_width-1 DOWNTO 0) ;
    SIGNAL uart_tx_pending : STD_LOGIC := '0' ;
    SIGNAL uart_action : STD_LOGIC := '0' ;
    SIGNAL uart_activate : STD_LOGIC := '0' ; 
    SIGNAL uart_bytecow : UNSIGNED(1 DOWNTO 0) := "00" ;

    SIGNAL loader_is_ready : STD_LOGIC ; 
    SIGNAL loader_activate : STD_LOGIC ;
BEGIN
    
    --MSB first. Bus reads zero on reset.
    main_data_bus_line_for_all_in(15 DOWNTO 0) <= data_bus_line_for_man2_reception ; 
    main_data_bus_line_for_all_in(31 DOWNTO 16) <= data_bus_line_for_man1_reception ;
    
    overload <= '1' WHEN symbol_error_count > 8192 ELSE '0' ;       --8192 is half of maximum count; just to see what's going on
    led_idle <= idle_line ;

    idle_line <= clock_1Hz_line WHEN rxaction="000" OR rxaction="001" ELSE '1' ;
    
   --display_bus <= STD_LOGIC_VECTOR(symbol_error_count) ;
   
   man1_temp <= not man1_in ;
   man2_temp <= not man2_in ;

  
SYMERRORVIEW: PROCESS(clock_1Hz_line, reset)
    BEGIN
        IF (reset='1') THEN
            symbol_count_reset <= '0' ;
        ELSIF (clock_1Hz_line='1') THEN
            symbol_count_reset <= '1' ;  
        ELSE
            symbol_count_reset <= '0' ;
        END IF;
    END PROCESS;    


UARTCOMMS: PROCESS(clock)
    BEGIN
        IF (RISING_EDGE(clock)) THEN
            CASE uart_action IS

                WHEN '0' =>        --Idle and waiting for event
                    IF (uart_activate='1' AND loader_is_ready='1') THEN        --MSB goes out via UART
                        uart_tx_ena <= '1' ;
                        uart_action <= '1' ;
                        uart_bytecow <= uart_bytecow + 1 ;
                    END IF;

                WHEN '1' =>        --Stay here until UART sends out all
                    IF (uart_tx_busy='1') THEN
                        uart_tx_ena <= '0' ;
                    ELSIF uart_bytecow < "11" THEN
                        uart_tx_ena <= '1' ;
                        uart_bytecow <= uart_bytecow + 1 ;
                    ELSE
                        uart_tx_ena <= '0' ;
                        uart_bytecow <= "00" ;
                        uart_action <= '0' ;
                    END IF;

                WHEN OTHERS =>
            END CASE;
        END IF;
END PROCESS;


DONESTATUS: PROCESS(clock_1Hz_line)
    BEGIN
        IF (RISING_EDGE(clock_1Hz_line)) THEN
            IF (rxaction="100") THEN
                IF (statusaction='0') THEN
                    display_bus <= STD_LOGIC_VECTOR(symbol_error_count) ;
                    statusaction <= '1' ;
                ELSE
                    display_bus <= statusvis ;
                    statusaction <= '0' ;
                END IF;
            END IF;
        END IF;
END PROCESS; 


MAIN: PROCESS(clock, reset)
    BEGIN             
        IF (init_line='0' OR reset='1') THEN  --Self reset on startup   
            srom_reset <= '1' ;
            srom_querry <= '0' ;
            global_reset_line <= '1' ;
            symbol_error_count <= x"0000" ;
            symbols_equal <= '0' ;
            symbol_count <= 0 ;
            init_line <= '1' ;
            statusvis <= x"0000" ;
            rxaction <= "000" ;

        ELSIF RISING_EDGE(clock) THEN
            
            CASE rxaction IS
                WHEN "000" =>       --Initialised system
                    srom_reset <= '0' ;
                    srom_querry <= '1' ;
                    global_reset_line <= '0' ;
                    symbol_error_count <= x"0000" ;
                    symbols_equal <= '0' ;
                    symbol_count <= 0 ;
                    rxaction <= "001" ;
                    
                WHEN "001" =>       --Waiting for reception to begin              
                    srom_querry <= '0' ;
                    srom_reset <= '0' ; 
                    uart_activate <= '0' ; 

                    IF (manchester1_idle='0' AND manchester2_idle='0') THEN
                        rxaction <= "010" ;
                    END IF;
                    
                WHEN "010" =>       --Receiving the data
                    IF (manchester1_idle='1'AND manchester2_idle='1') THEN    --Data completely received

                        uart_activate <= '1' ;      --Stays on for 2 clock cycles i.e. this state and when rxaction is 011.
                                        
                        IF ( (main_data_bus_line_for_all_in = temp_trans_in) AND symbol_count >= memory_size ) THEN      --We successfully received all
                            rxaction <= "100" ;

                        ELSIF ( (main_data_bus_line_for_all_in /= temp_trans_in) AND symbol_count < memory_size ) THEN      --An error in received data
                            symbol_error_count <= symbol_error_count + 1 ;
                            rxaction <= "011" ;

                        ELSIF ( (main_data_bus_line_for_all_in = x"FFFFFFFF") AND symbol_count > memory_size ) THEN     --Received all for sure
                            rxaction <= "101" ;
                            
                        ELSE
                            rxaction <= "010" ;

                        END IF;
                        
                        symbol_count <= symbol_count + 1 ;

                    END IF ;    
                    
                WHEN "011" =>       --Received state. Load the comparison line and do other stuff
                    srom_querry <= '1' ;

                    IF (rx_mode = '1') THEN
                        rxaction <= "001" ;
                    ELSE
                        rxaction <= "100" ;
                    END IF;

                WHEN "100" =>
                    statusvis <= x"D09E" ;

                WHEN "101" =>
                    statusvis <= x"FFFF" ;
                
                WHEN OTHERS =>
                    statusvis <= x"EEEE" ;

                               
            END CASE;
    
        END IF;
END PROCESS;          



    -------------------------------------------------------------------------------------------------------
-------------------------------------  PORT MAPS ------------------------------------------------------
-------------------------------------------------------------------------------------------------------

CLOCKDIV: clock_divider
PORT MAP (
    clock_100MHz => clock,
    clock_70kHz => OPEN,
    clock_10MHz => clock_1p3615MHz,
    clock_1Hz => clock_1Hz_line
);

DATASRC: srom
PORT MAP (
    data => temp_trans_in,
    clock => clock, 
    reset => srom_reset,
    querry => srom_querry
);

MANDECODE1: decode
PORT MAP (
    clk16x => clock_1p3615MHz,
    srst => global_reset_line,
    rx_data => data_bus_line_for_man1_reception,
    rx_stb => manchester1_received_stopbit,
    rxd => man1_temp,
    fm_err => manchester1_frame_error,
    rx_idle => manchester1_idle
);

MANDECODE2: decode
PORT MAP (
    clk16x => clock_1p3615MHz,
    srst => global_reset_line,
    rx_data => data_bus_line_for_man2_reception,
    rx_stb => manchester2_received_stopbit,
    rxd => man2_temp,
    fm_err => manchester2_frame_error,
    rx_idle => manchester2_idle
);

DISPLAY: lcdbox
PORT MAP (
    number => display_bus ,
    clock_100Mhz => clock,
    rst => global_reset_line,
    Anode_Activate => anode,
    LED_out => cathode
);

PCCONN: uart
GENERIC MAP (clk_freq => master_clock, baud_rate => uart_baud_rate, d_width => uart_d_width)
PORT MAP (
    clk => clock,  
    tx_ena => uart_tx_ena, 
    tx_data => uart_data_bus_tx,
    rx => uart_rx, 
    rx_busy => uart_rx_busy, 
    rx_error => uart_rx_error, 
    rx_data => uart_data_bus_rx,
    tx_busy => uart_tx_busy,
    tx => uart_tx
);  

BITCONN: loader32_to_8
PORT MAP (
    bits8 => uart_data_bus_tx,
    clock => clock,
    reset => global_reset_line,
    ready => loader_is_ready,
    fetch => loader_activate,
    bits32 =>  main_data_bus_line_for_all_in   
);
END monarch;