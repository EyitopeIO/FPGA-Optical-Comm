-- fpga4student.com: FPGA projects, Verilog projects, VHDL projects
-- VHDL code for seven-segment display on Basys 3 FPGA
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;

--Adapted from: https://www.fpga4student.com/2017/09/vhdl-code-for-seven-segment-display.html

ENTITY lcdbox IS
    PORT (
        number : IN STD_LOGIC_VECTOR(15 DOWNTO 0) ;
        clock_100Mhz : IN STD_LOGIC ;
        rst : IN STD_LOGIC ;         
        Anode_Activate : OUT STD_LOGIC_VECTOR (3 DOWNTO 0) ;  -- 4 Anode signals
        LED_out : OUT STD_LOGIC_VECTOR (6 DOWNTO 0)  -- Cathode patterns of 7-segment display
    );
END lcdbox;


ARCHITECTURE disp OF lcdbox IS
        
    signal one_second_counter: STD_LOGIC_VECTOR (27 downto 0);
    -- counter for generating 1-second clock enable
    signal one_second_enable: std_logic;
    -- one second enable for counting numbers
    signal displayed_number: STD_LOGIC_VECTOR (15 downto 0) := x"FFFF" ;
    -- counting decimal number to be displayed on 4-digit 7-segment display
    signal LED_BCD: STD_LOGIC_VECTOR (3 downto 0);
    signal refresh_counter: STD_LOGIC_VECTOR (19 downto 0);
    -- creating 10.5ms refresh period
    signal LED_activating_counter: std_logic_vector(1 downto 0);
    -- the other 2-bit for creating 4 LED-activating signals
    
    SIGNAL init_line : STD_LOGIC := '0' ;
    SIGNAL reset : STD_LOGIC := '1' ; 

       
    -- count         0    ->  1  ->  2  ->  3
    -- activates    LED1    LED2   LED3   LED4
    -- and repeat
BEGIN

    LED_activating_counter <= refresh_counter(19 downto 18) ;
    one_second_enable <= '1' when one_second_counter=x"5F5E0FF" else '0' ;
            
    PROCESS(clock_100Mhz)
    BEGIN
        IF RISING_EDGE(clock_100Mhz) THEN
            IF (init_line = '0') THEN
                displayed_number <= x"FFFF" ;
                init_line <= '1' ;
                reset <= '1' ;
            ELSE
                displayed_number <= number ;
                reset <= rst ;
            END IF;
        END IF;
    END PROCESS;
       
       
    -- 7-segment display controller
    -- generate refresh period of 10.5ms
    PROCESS(clock_100Mhz,reset)
    begin 
        if(reset='1') then
            refresh_counter <= (others => '0');
        elsif(rising_edge(clock_100Mhz)) then
            refresh_counter <= refresh_counter + 1;
        end if;
    end PROCESS;
    
    
    -- 4-to-1 MUX to generate anode activating signals for 4 LEDs 
    PROCESS(LED_activating_counter)
    begin
        case LED_activating_counter is
        when "00" =>
            Anode_Activate <= "0111"; 
            -- activate LED1 and Deactivate LED2, LED3, LED4
            LED_BCD <= displayed_number(15 downto 12);
            -- the first hex digit of the 16-bit number
        when "01" =>
            Anode_Activate <= "1011"; 
            -- activate LED2 and Deactivate LED1, LED3, LED4
            LED_BCD <= displayed_number(11 downto 8);
            -- the second hex digit of the 16-bit number
        when "10" =>
            Anode_Activate <= "1101"; 
            -- activate LED3 and Deactivate LED2, LED1, LED4
            LED_BCD <= displayed_number(7 downto 4);
            -- the third hex digit of the 16-bit number
        when "11" =>
            Anode_Activate <= "1110"; 
            -- activate LED4 and Deactivate LED2, LED3, LED1
            LED_BCD <= displayed_number(3 downto 0);
            -- the fourth hex digit of the 16-bit number  
        when others =>
            
        end case;
    end PROCESS;
    
    
    -- Counting the number to be displayed on 4-digit 7-segment Display 
    -- on Basys 3 FPGA board
    PROCESS(clock_100Mhz, reset)
    begin
            if(reset='1') then
                one_second_counter <= (others => '0');
            elsif(rising_edge(clock_100Mhz)) then
                if(one_second_counter>=x"5F5E0FF") then  --99 999 999 DEC
                    one_second_counter <= (others => '0');
                else
                    one_second_counter <= one_second_counter + "0000001";
                end if;
            end if;
    end PROCESS;
    
    
    -- VHDL code for BCD to 7-segment decoder
    -- Cathode patterns of the 7-segment LED display
    PROCESS(LED_BCD)
    BEGIN
        CASE LED_BCD is
            WHEN "0000" => LED_out <= "0000001"; -- "0"     
            WHEN "0001" => LED_out <= "1001111"; -- "1" 
            WHEN "0010" => LED_out <= "0010010"; -- "2" 
            WHEN "0011" => LED_out <= "0000110"; -- "3" 
            WHEN "0100" => LED_out <= "1001100"; -- "4" 
            WHEN "0101" => LED_out <= "0100100"; -- "5" 
            WHEN "0110" => LED_out <= "0100000"; -- "6" 
            WHEN "0111" => LED_out <= "0001111"; -- "7" 
            WHEN "1000" => LED_out <= "0000000"; -- "8"     
            WHEN "1001" => LED_out <= "0000100"; -- "9" 
            WHEN "1010" => LED_out <= "0000010"; -- a
            WHEN "1011" => LED_out <= "1100000"; -- b
            WHEN "1100" => LED_out <= "0110001"; -- C
            WHEN "1101" => LED_out <= "1000010"; -- d
            WHEN "1110" => LED_out <= "0110000"; -- E
            WHEN "1111" => LED_out <= "0111000"; -- F
            WHEN OTHERS =>
        END CASE;
    END PROCESS;

END disp;