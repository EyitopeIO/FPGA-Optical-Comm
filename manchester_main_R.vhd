LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY mainR IS
    GENERIC(
        master_clock        :   NATURAL     := 100_000_000;
        data_bus_width      :   NATURAL     := 16;
        uart_baud_rate      :   INTEGER     := 9600;
        memory_size         :   INTEGER     := 46
    );
    
    PORT (
        clock:      IN STD_LOGIC;
        man1_in:   IN STD_LOGIC; --connect to high speed port
        man2_in:   IN STD_LOGIC;        
        reset :      IN STD_LOGIC;
        rx_mode : IN STD_LOGIC ;
        led_idle : OUT STD_LOGIC ;
        overload : OUT STD_LOGIC  --High when symbol errors to much
    );
    
END mainR;

ARCHITECTURE monarch OF mainR IS

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
    
    SIGNAL global_reset_line : STD_LOGIC := '0' ;
    SIGNAL idle_line : STD_LOGIC := '1' ;
    SIGNAL init_line : STD_LOGIC := '0' ;

    SIGNAL clock_1Hz_line : STD_LOGIC ;
    SIGNAL clock_70kHz_line : STD_LOGIC ;
        
    SIGNAL manchester1_stopped_receiving : STD_LOGIC ;
    SIGNAL manchester2_stopped_receiving : STD_LOGIC ;

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
    SIGNAL symbol_error_count : UNSIGNED(15 DOWNTO 0) := x"0000" ;  --Unlikely to have errors greater than 256, yeah?
    SIGNAL symbol_error_overload : STD_LOGIC := '0' ;
    SIGNAL symbol_count_reset : STD_LOGIC := '0' ;
    
    SIGNAL display_bus : STD_LOGIC_VECTOR(15 DOWNTO 0) ;
    
BEGIN
    
    --MSB first. Bus reads zero on reset.
    main_data_bus_line_for_all_in(15 DOWNTO 0) <= data_bus_line_for_man2_reception ; 
    main_data_bus_line_for_all_in(31 DOWNTO 16) <= data_bus_line_for_man1_reception ;
    
    overload <= '1' WHEN symbol_error_overload = '1' ELSE '0' ;
    led_idle <= idle_line ;
  
SYMERRORVIEW: PROCESS(clock_1Hz_line, reset)
    BEGIN
        IF (reset='1') THEN
            display_bus <= x"0000" ;
            symbol_count_reset <= '0' ;
        ELSIF (RISING_EDGE(clock_1Hz_line)) THEN
            display_bus <= STD_LOGIC_VECTOR(symbol_error_count) ;  
            symbol_count_reset <= '1' ;     
        END IF;
    END PROCESS;    

MAIN: PROCESS(clock, reset)
    BEGIN             
        IF (init_line='0' OR reset='1') THEN  --Self reset on startup   
            srom_reset <= '1' ;
            srom_querry <= '0' ;
            global_reset_line <= '1' ;
            symbol_error_count <= x"0000" ;
            symbol_error_overload <= '0' ;
            symbols_equal <= '0' ;
            init_line <= '1' ;
            idle_line <= '0' ;
            rxaction <= "000" ;

        ELSIF RISING_EDGE(clock) THEN

            IF (symbol_error_count > 65535) THEN
                symbol_error_overload <= '1' ;
            ELSE
                symbol_error_overload <= '0' ;
            END IF;
    
            CASE rxaction IS             
                WHEN "000" =>    --Wait for first data in memory
                    srom_reset <= '0' ;
                    global_reset_line <= '0' ; 
                    
                    IF (manchester1_idle='0' AND manchester2_idle='0') THEN  --i.e. It just began receiving
                        rxaction <= "001" ;
                        srom_querry <= '1' ;
                    END IF;
                                     
                WHEN "001" =>  --Wait for idle line to go high, or low to high
                    srom_querry <= '0' ;
                
                    IF (manchester1_idle='1' AND manchester2_idle='1') THEN  -- symbol received
                        rxaction <= "010" ;

                        IF (main_data_bus_line_for_all_in /= temp_trans_in) THEN
                            symbol_error_count <= symbol_error_count + 1 ;

                        ELSIF (main_data_bus_line_for_all_in = x"FFFFFFFF") THEN
                            IF (rx_mode = '1') THEN
                                srom_reset <= '1' ;
                                rxaction <= "000" ;
                            ELSE
                                rxaction <= "111" ;
                            END IF;
                        END IF;

                    END IF;

                WHEN "010" =>  --Wait for idle line to go low   
                    IF (manchester1_idle='0' AND manchester2_idle='0') THEN
                        rxaction <= "011" ;
                    END IF;         
                                
                WHEN "011" =>  --Load next data in comparison line
                    srom_querry <= '1' ;
                    rxaction <= "001" ;
                    IF (symbol_count_reset = '1') THEN
                        symbol_error_count <= x"0000" ;
                    END IF;
                       
                WHEN OTHERS =>
                    led_idle <= '1' ; 
                                     
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
    clock_10MHz => OPEN,
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
    clk16x => clock,
    srst => global_reset_line,
    rx_data => data_bus_line_for_man1_reception,
    rx_stb => manchester1_stopped_receiving,
    rxd => man1_in,
    fm_err => manchester1_frame_error,
    rx_idle => manchester1_idle
);

MANDECODE2: decode
PORT MAP (
    clk16x => clock,
    srst => global_reset_line,
    rx_data => data_bus_line_for_man2_reception,
    rx_stb => manchester2_stopped_receiving,
    rxd => man2_in,
    fm_err => manchester2_frame_error,
    rx_idle => manchester2_idle
);

END monarch;