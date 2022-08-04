LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY mantx IS
    GENERIC(
        data_bus_width : NATURAL := 32     --Expects 32 as default
    );
    
    PORT (
        clock_100MHz : IN STD_LOGIC ;
        clock_1p3615MHz : IN STD_LOGIC ;

        data_bus : STD_LOGIC_VECTOR(31 DOWNTO 0) ;

        man1_out : OUT STD_LOGIC ;      --connect to high speed port
        man2_out : OUT STD_LOGIC ;
        
        start_tx : IN STD_LOGIC ; --send 46 bytes once
        reset :      IN STD_LOGIC ; 
        
        overload : OUT STD_LOGIC ;
        led_idle : OUT STD_LOGIC
        
--         test_tout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) ; 
--         test_man1 : OUT STD_LOGIC;
--         test_man2 : OUT STD_LOGIC;
--         test_querry : OUT STD_LOGIC;
--         test_manbeg : OUT STD_LOGIC;
        
        -- led_tx : OUT STD_LOGIC;
        -- led_tx_error : OUT STD_LOGIC ;
    );
    
END mantx;


ARCHITECTURE mantxarch OF mantx IS

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

    SIGNAL manchester_begin_transmission : STD_LOGIC := '0' ;
    
    SIGNAL man1_temp_output : STD_LOGIC ;
    SIGNAL man2_temp_output : STD_LOGIC ;

    SIGNAL manchester1_ready_for_data_on_din : STD_LOGIC ;
    SIGNAL manchester2_ready_for_data_on_din : STD_LOGIC ;
    
    SIGNAL manchester1_overrun_error : STD_LOGIC ;
    SIGNAL manchester2_overrun_error : STD_LOGIC ;
    
    SIGNAL data_bus_line_for_man1_transmission:  STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL data_bus_line_for_man2_transmission:  STD_LOGIC_VECTOR(15 DOWNTO 0);     

    SIGNAL main_data_bus_line_for_all_out : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000" ;

    SIGNAL txaction : UNSIGNED(1 DOWNTO 0) := "00" ;
    
BEGIN

    -- To drive 5V logic with 3.3V FPGA output, additional transistor was needed.
    -- Next two lines necessary if using NPN. Not needed for PNP.
    man1_out <= not man1_temp_output ;
    man2_out <= not man2_temp_output ;

    -- MSB first in data
    data_bus_line_for_man2_transmission <= main_data_bus_line_for_all_out(15 DOWNTO 0) ; 
    data_bus_line_for_man1_transmission <= main_data_bus_line_for_all_out(31 DOWNTO 16) ;

    overload <= '1' WHEN manchester1_overrun_error='1' OR manchester2_overrun_error='1' ELSE '0' ;
    led_idle <= '1' WHEN txaction="00" ELSE '0' ;
        
--     test_man1 <= manchester1_ready_for_data_on_din ;
--     test_man2 <= manchester2_ready_for_data_on_din ;
--     test_querry <= srom_querry ;
--     test_manbeg <= manchester_begin_transmission ;    
    
MAIN: PROCESS(clock_100MHz, reset)
    BEGIN     
        
        IF (reset='1') THEN 
            manchester_begin_transmission <= '0' ;
            txaction <= "00" ;
            main_data_bus_line_for_all_out <= x"00000000" ;

        ELSIF (RISING_EDGE(clock_100MHz)) THEN

            main_data_bus_line_for_all_out <= data_bus ;
            
            CASE txaction IS    
                WHEN "00" =>    --Ready to begin transmission
                    IF (start_tx = '1' ) THEN
                        txaction <= "01" ;
                        manchester_begin_transmission <= '1' ;
                    END IF;

                WHEN "01" =>   --Wait for manchester to < begin > sending its data                              
                    IF (manchester1_ready_for_data_on_din='0' AND manchester2_ready_for_data_on_din='0') THEN
                        manchester_begin_transmission <= '0' ;
                        txaction <= "11" ;
                    END IF;                
                                
                WHEN "11" =>   --Wait for manchester to < finish > sending data                                                                         
                    IF (manchester1_ready_for_data_on_din='1' AND manchester2_ready_for_data_on_din='1') THEN
                        txaction <= "00" ;
                    END IF;
                                                                                                                           
                WHEN OTHERS =>
                    manchester_begin_transmission <= '0' ;                           
                    led_idle <= '1' ;                                      
            END CASE;
            
        END IF;
        
    END PROCESS;          


-------------------------------------------------------------------------------------------------------
-------------------------------------  PORT MAPS ------------------------------------------------------
-------------------------------------------------------------------------------------------------------

MANENCODE1: encode
PORT MAP (
    clk16x => clock_1p3615MHz,
    srst => reset,
    tx_data => data_bus_line_for_man1_transmission,
    tx_stb => manchester_begin_transmission,
    txd => man1_temp_output,
    or_err => manchester1_overrun_error,
    tx_idle => manchester1_ready_for_data_on_din
);

MANENCODE2: encode
PORT MAP (
    clk16x => clock_1p3615MHz,
    srst => reset,
    tx_data => data_bus_line_for_man2_transmission,
    tx_stb => manchester_begin_transmission,
    txd => man2_temp_output,
    or_err => manchester2_overrun_error,
    tx_idle => manchester2_ready_for_data_on_din
);

END mantxarch;