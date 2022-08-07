LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY manrx IS
    GENERIC( data_bus_width : NATURAL := 32 );
    PORT (
        clock_100MHz : IN STD_LOGIC ;
        clock_1p3615MHz : IN STD_LOGIC ;

        data_bus : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) ;
        readme : OUT STD_LOGIC ;

        man1_in:   IN STD_LOGIC ; 
        man2_in:   IN STD_LOGIC ;   

        reset :      IN STD_LOGIC ;        
        led_idle : OUT STD_LOGIC ;
        overload : OUT STD_LOGIC 
    );
    
END manrx;

ARCHITECTURE manrxarch OF manrx IS

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
            
    SIGNAL manchester1_received_stopbit : STD_LOGIC ;
    SIGNAL manchester2_received_stopbit : STD_LOGIC ;
    
    -- To account for the NPN transistor to shift the 5V logic from light sensor to 3.3V
    SIGNAL man1_temp : STD_LOGIC ;
    SIGNAL man2_temp : STD_LOGIC ;

    SIGNAL manchester1_idle : STD_LOGIC ;
    SIGNAL manchester2_idle : STD_LOGIC ;
    
    SIGNAL manchester1_frame_error : STD_LOGIC ;
    SIGNAL manchester2_frame_error : STD_LOGIC ;    

    SIGNAL data_bus_line_for_man1_reception:  STD_LOGIC_VECTOR(15 DOWNTO 0) ;
    SIGNAL data_bus_line_for_man2_reception:  STD_LOGIC_VECTOR(15 DOWNTO 0) ; 

    SIGNAL main_data_bus_line_for_all_in : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"FFFFFFFF" ;
    
    SIGNAL rxstate : UNSIGNED(1 DOWNTO 0) := "00" ;

    
BEGIN
    
    --MSB first. Bus reads zero on reset.
    main_data_bus_line_for_all_in(15 DOWNTO 0) <= data_bus_line_for_man2_reception ; 
    main_data_bus_line_for_all_in(31 DOWNTO 16) <= data_bus_line_for_man1_reception ;
       
    man1_temp <= not man1_in ;
    man2_temp <= not man2_in ;

    led_idle <= '1' WHEN manchester1_idle='1' AND manchester2_idle='1' ELSE '0' ;
    overload <= '1' WHEN manchester1_frame_error='1' OR manchester2_frame_error='1' ELSE '0' ;


MAIN: PROCESS(clock_100MHz, reset)
    BEGIN             
        IF (reset='1') THEN 
            rxstate <= "00" ;
            readme <= '0' ;

        ELSIF RISING_EDGE(clock_100MHz) THEN        
            CASE rxstate IS
                WHEN "00" =>       --Ready to receive data
                    readme <= '0' ;               
                    IF (manchester1_idle='0' AND manchester2_idle='0') THEN
                        rxstate <= "01" ;
                        data_bus <= main_data_bus_line_for_all_in ;
                    END IF;
                WHEN "01" =>       --Receiving the data
                    IF (manchester1_idle='1' AND manchester2_idle='1') THEN     --Done receiving the data
                        rxstate <= "00" ;
                        readme <= '1' ;    
                    END IF;                           
                WHEN OTHERS =>
            END CASE;
        END IF;
    END PROCESS;


-------------------------------------------------------------------------------------------------------
-------------------------------------  PORT MAPS ------------------------------------------------------
-------------------------------------------------------------------------------------------------------

MANDECODE1: decode
PORT MAP (
    clk16x => clock_1p3615MHz,
    srst => reset,
    rx_data => data_bus_line_for_man1_reception,
    rx_stb => manchester1_received_stopbit,
    rxd => man1_temp,
    fm_err => manchester1_frame_error,
    rx_idle => manchester1_idle
);

MANDECODE2: decode
PORT MAP (
    clk16x => clock_1p3615MHz,
    srst => reset,
    rx_data => data_bus_line_for_man2_reception,
    rx_stb => manchester2_received_stopbit,
    rxd => man2_temp,
    fm_err => manchester2_frame_error,
    rx_idle => manchester2_idle
);


END manrxarch;