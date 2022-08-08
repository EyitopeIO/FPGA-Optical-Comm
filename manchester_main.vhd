LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;


ENTITY main IS
    GENERIC(
        master_clock        :   NATURAL     := 100_000_000;
        data_bus_width      :   NATURAL     := 16;
        ascii_gen_bus_width :   NATURAL     := 8;   --ideally should by related to data_bus_width by formula
        uart_baud_rate      :   INTEGER     := 9600;
        memory_size         :   INTEGER     := 46
    );
    
    PORT (
        clock:      IN STD_LOGIC;
        man1_out:   OUT STD_LOGIC; --connect to high speed port
        man2_out:   OUT STD_LOGIC;
        
        start_tx : IN STD_LOGIC; --send 46 bytes once
        tx_mode : IN STD_LOGIC;
        reset :      IN STD_LOGIC; 

        overload : OUT STD_LOGIC ;

        cathode : OUT STD_LOGIC_VECTOR (6 DOWNTO 0) ;
        anode : OUT STD_LOGIC_VECTOR (3 DOWNTO 0) ;
        
--         test_tout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) ; 
--         test_man1 : OUT STD_LOGIC;
--         test_man2 : OUT STD_LOGIC;
--         test_querry : OUT STD_LOGIC;
--         test_manbeg : OUT STD_LOGIC;
        
        led_idle : OUT STD_LOGIC
        -- led_tx : OUT STD_LOGIC;
        -- led_tx_error : OUT STD_LOGIC ;
    );
    
END main;


ARCHITECTURE monarch OF main IS

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

    COMPONENT lcdbox IS
    PORT (
        rst :            IN STD_LOGIC ;         
        number :         IN STD_LOGIC_VECTOR(15 DOWNTO 0) ;
        LED_out :        OUT STD_LOGIC_VECTOR (6 DOWNTO 0) ; 
        clock_100Mhz :   IN STD_LOGIC ;
        Anode_Activate : OUT STD_LOGIC_VECTOR (3 DOWNTO 0)
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
    SIGNAL init_line : STD_LOGIC := '0' ;
    
    SIGNAL clock_1Hz_line : STD_LOGIC ;
    SIGNAL clock_1p3615MHz_line : STD_LOGIC ;
    
    SIGNAL manchester_begin_transmission : STD_LOGIC := '0' ;
    
    SIGNAL man1_temp_output : STD_LOGIC ;
    SIGNAL man2_temp_output : STD_LOGIC ;

    SIGNAL manchester1_ready_for_data_on_din : STD_LOGIC ;
    SIGNAL manchester2_ready_for_data_on_din : STD_LOGIC ;
    
    SIGNAL manchester1_overrun_error : STD_LOGIC ;
    SIGNAL manchester2_overrun_error : STD_LOGIC ;
    
    SIGNAL data_bus_line_for_man1_transmission:  STD_LOGIC_VECTOR(data_bus_width-1 DOWNTO 0);
    SIGNAL data_bus_line_for_man2_transmission:  STD_LOGIC_VECTOR(data_bus_width-1 DOWNTO 0);     

    SIGNAL main_data_bus_line_for_all_out : STD_LOGIC_VECTOR(31 DOWNTO 0) ;
    SIGNAL temp_trans_out : STD_LOGIC_VECTOR(31 DOWNTO 0) ;

    SIGNAL srom_reset : STD_LOGIC ;
    SIGNAL srom_querry : STD_LOGIC ; 
    
    SIGNAL txaction : UNSIGNED(2 DOWNTO 0) := "000" ;
    
    SIGNAL vnumber : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0000" ;    
    
BEGIN

    -- To drive 5V logic with 3.3V FPGA output, additional transistor was needed.
    -- Next two lines necessary if using NPN. Not needed for PNP.
    man1_out <= not man1_temp_output ;
    man2_out <= not man2_temp_output ;

    -- MSB first in data
    data_bus_line_for_man2_transmission <= main_data_bus_line_for_all_out(15 DOWNTO 0) ; 
    data_bus_line_for_man1_transmission <= main_data_bus_line_for_all_out(31 DOWNTO 16) ;

    overload <= '1' WHEN manchester1_overrun_error='1' OR manchester2_overrun_error='1' ELSE '0' ;
    led_idle <= clock_1Hz_line WHEN txaction="000" ELSE '0' ;

--     test_man1 <= manchester1_ready_for_data_on_din ;
--     test_man2 <= manchester2_ready_for_data_on_din ;
--     test_querry <= srom_querry ;
--     test_manbeg <= manchester_begin_transmission ;    
    
MAIN: PROCESS(clock, reset)
    BEGIN     
        main_data_bus_line_for_all_out <= temp_trans_out ;
--        test_tout <= temp_trans_out ;
        
        IF (init_line='0' OR reset='1') THEN  --Self reset on startup   
            srom_reset <= '1' ;
            srom_querry <= '0' ;
            manchester_begin_transmission <= '0' ;
            global_reset_line <= '1' ;
            init_line <= '1' ;
            txaction <= "000" ;
            vnumber <= x"0000" ;
            
        ELSIF (RISING_EDGE(clock)) THEN
            
            CASE txaction IS    
                WHEN "000" =>    --Ready to begin transmission
                    
                    IF (start_tx = '1' OR tx_mode = '1') THEN
                        srom_reset <= '0' ;
                        srom_querry <= '1' ;
                        global_reset_line <= '0' ;
                        manchester_begin_transmission <= '0' ;
                        txaction <= "001" ;
                    END IF;
                                     
                WHEN "001" =>    --First entrance
                    manchester_begin_transmission <= '1' ;
                    srom_querry <= '0' ;
                    txaction <= "010" ;

                WHEN "010" =>   --Wait for manchester to < begin > sending its data, or high to low
                
                    srom_querry <= '0' ;
                    
                    IF (manchester1_ready_for_data_on_din='0' OR manchester2_ready_for_data_on_din='0') THEN
                        manchester_begin_transmission <= '0' ;
                        txaction <= "011" ;
                    END IF;                
                                
                WHEN "011" =>   --Wait for manchester to < finish > sending data, or low to high                                                                             
                    IF (manchester1_ready_for_data_on_din='1' OR manchester2_ready_for_data_on_din='1') THEN
                        manchester_begin_transmission <= '1' ;
                        txaction <= "100" ;
                    END IF;
                                                                                             
                    IF (main_data_bus_line_for_all_out = x"FFFFFFFF") THEN
                        txaction <= "101" ;
                    END IF;                                  
                    
                WHEN "100" =>   --Load data bus2
                    srom_querry <= '1' ;
                    txaction <= "010" ;
                
                WHEN "101" =>   --Repeat transmission or stay idle
                    IF (tx_mode = '1') THEN  --automatic mode
                        srom_reset <= '1' ;
                        srom_querry <= '0' ;
                        global_reset_line <= '1' ;
                        manchester_begin_transmission <= '0' ;
                        txaction <= "110" ;
                        vnumber <= x"FFFF" ;         
                    ELSE
                        txaction <= "111" ;
                    END IF;
                    
                WHEN "110" =>       --empty state to allow a clock cycle
                    txaction <= "000" ;

                WHEN "111" =>       --Idle mode when system is in manual mode
                    vnumber <= x"D09E" ;
                                 
                WHEN OTHERS =>      --Never happening
                    vnumber <= x"EEEE" ; 
                                     
            END CASE;
            
        END IF;
        
    END PROCESS;          


-------------------------------------------------------------------------------------------------------
-------------------------------------  PORT MAPS ------------------------------------------------------
-------------------------------------------------------------------------------------------------------

CLOCKDIV: clock_divider
PORT MAP (
    clock_100MHz => clock,
    clock_10MHz => clock_1p3615MHz_line,
    clock_70kHz => OPEN, 
    clock_1Hz => clock_1Hz_line
);

DATASRC: srom
PORT MAP (
    data => temp_trans_out,
    
    --Don't want this slower than the manchester encoder. It must always be ready for Manchester/
    clock => clock, 
    
    reset => srom_reset,
    querry => srom_querry
);

MANENCODE1: encode
PORT MAP (
    clk16x => clock_1p3615MHz_line,
    srst => global_reset_line,
    tx_data => data_bus_line_for_man1_transmission,
    tx_stb => manchester_begin_transmission,
    txd => man1_temp_output,
    or_err => manchester1_overrun_error,
    tx_idle => manchester1_ready_for_data_on_din
);

MANENCODE2: encode
PORT MAP (
    clk16x => clock_1p3615MHz_line,
    srst => global_reset_line,
    tx_data => data_bus_line_for_man2_transmission,
    tx_stb => manchester_begin_transmission,
    txd => man2_temp_output,
    or_err => manchester2_overrun_error,
    tx_idle => manchester2_ready_for_data_on_din
);

DISPLAY: lcdbox
PORT MAP (
    rst => global_reset_line,       
    number => vnumber,
    LED_out => cathode, 
    clock_100Mhz => clock,
    Anode_Activate => anode
);

END monarch;