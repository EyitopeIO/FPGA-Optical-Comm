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
        reset:      IN STD_LOGIC; --assign to button
        man1_out:   OUT STD_LOGIC; --connect to high speed port
        man2_out:   OUT STD_LOGIC;
        start_tx : IN STD_LOGIC;
        led_tx : OUT STD_LOGIC;
        led_tx_error : OUT STD_LOGIC
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

    COMPONENT srom IS
    PORT (
        data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) ; --make a process sensitive to this
        readme : OUT STD_LOGIC ;
        clock : IN STD_LOGIC ;
        reset : IN STD_lOGIC    --keep high to prevent data read
    );
    END COMPONENT;

    COMPONENT clock_divider IS
    PORT (
        clock_100MHz : IN STD_lOGIC;
        clock_50MHz : OUT STD_LOGIC ;
        clock_1Hz : OUT STD_lOGIC
    );
    END COMPONENT ;
    
    SIGNAL global_reset_line : STD_LOGIC := '0' ;
    SIGNAL master_clock_line : STD_LOGIC ;
    SIGNAL clock_50MHz_line : STD_LOGIC ;
    SIGNAL clock_1Hz_line : STD_LOGIC ;
    
    SIGNAL manchester_begin_transmission : STD_LOGIC := '0' ;
    
    SIGNAL manchester1_ready_for_data_on_din : STD_LOGIC ;
    SIGNAL manchester2_ready_for_data_on_din : STD_LOGIC ;
    
    SIGNAL manchester1_overrun_error : STD_LOGIC ;
    SIGNAL manchester2_overrun_error : STD_LOGIC ;
    
    SIGNAL data_bus_line_for_man1_transmission:  STD_LOGIC_VECTOR(data_bus_width-1 DOWNTO 0);
    SIGNAL data_bus_line_for_man2_transmission:  STD_LOGIC_VECTOR(data_bus_width-1 DOWNTO 0);     

--    SIGNAL data_bus_line_for_man1_reception:  STD_LOGIC_VECTOR(data_bus_width-1 DOWNTO 0);
--    SIGNAL data_bus_line_for_man2_reception:  STD_LOGIC_VECTOR(data_bus_width-1 DOWNTO 0); 

    SIGNAL main_data_bus_line_for_all_out : STD_LOGIC_VECTOR(31 DOWNTO 0) ;
    --SIGNAL main_data_bus_line_for_all_in : STD_LOGIC_VECTOR(31 DOWNTO 0) ;
    SIGNAL temp_out : STD_LOGIC_VECTOR(31 DOWNTO 0) ;

    --SIGNAL small_data_bus : STD_LOGIC_VECTOR(7 DOWNTO 0) ;
    SIGNAL srom_reset : STD_LOGIC := '0' ;
    SIGNAL srom_readme : STD_LOGIC ;

BEGIN

    data_bus_line_for_man2_transmission <= main_data_bus_line_for_all_out(31 DOWNTO 16) ;
    data_bus_line_for_man1_transmission <= main_data_bus_line_for_all_out(15 DOWNTO 0) ;

    master_clock_line <= clock ;

-------------------------------------------------------------------------------------------------------
-------------------------------------  PORT MAPS ------------------------------------------------------
-------------------------------------------------------------------------------------------------------

MAIN: PROCESS(master_clock_line)
    BEGIN
      
        IF (reset='1') THEN
            srom_reset <= '1' ;
            global_reset_line <= '1' ;
            
        ELSIF (start_tx='1') THEN
            IF (master_clock_line'EVENT AND master_clock_line='1') THEN
                srom_reset <= '0' ;
                global_reset_line <= '0' ;
                
                IF (srom_readme='1') THEN
                    IF (manchester1_ready_for_data_on_din='1' AND manchester2_ready_for_data_on_din='1') THEN   
                        manchester_begin_transmission <= '1' ;  --will cause manchester encoder to latch the main data bus                 
                    ELSE
                        manchester_begin_transmission <= '0' ;
                    END IF;                 
                END IF;
                
            END IF;
        END IF;

    END PROCESS;
            

STATUSLED: PROCESS(main_data_bus_line_for_all_out, manchester_begin_transmission, manchester1_overrun_error, manchester2_overrun_error)
    BEGIN
    
        IF (main_data_bus_line_for_all_out=x"00000000") THEN
            led_tx <= '1' ;
        ELSIF (main_data_bus_line_for_all_out=x"FFFFFFFF") THEN
            led_tx <= '0' ;
        END IF;
        
        IF (manchester1_overrun_error='1' OR manchester2_overrun_error='1') THEN
            led_tx_error <= '1' ;
        ELSE
            led_tx_error <= '0' ;
        END IF;
        
    END PROCESS;

CLOCKDIV: clock_divider
PORT MAP (clock_100MHz => clock, clock_50MHz => clock_50MHz_line, clock_1Hz => clock_1Hz_line) ;

DATASRC: srom
PORT MAP (
    data => main_data_bus_line_for_all_out,
    clock => clock_50MHz_line, --Don't want this faster than the manchester encoder
    reset => srom_reset,
    readme => srom_readme
);

MANENCODE1: encode
PORT MAP (
    clk16x=>clock_50MHz_line,
    srst=>global_reset_line,
    tx_data=>data_bus_line_for_man1_transmission,
    tx_stb=>manchester_begin_transmission,
    txd=>man1_out,
    or_err=> manchester1_overrun_error,
    tx_idle=>manchester1_ready_for_data_on_din
);

MANENCODE2: encode
PORT MAP (
    clk16x=>clock_50MHz_line,
    srst=>global_reset_line,
    tx_data=>data_bus_line_for_man2_transmission,
    tx_stb=>manchester_begin_transmission,
    txd=>man2_out,
    or_err=> manchester2_overrun_error,
    tx_idle=>manchester2_ready_for_data_on_din
);

END monarch;