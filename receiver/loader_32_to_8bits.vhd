
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY loader32_to_8 IS

    GENERIC (
        master_clock : INTEGER := 100_000_000 ;
        uart_baud_rate : INTEGER := 115200 ;
        uart_d_width : INTEGER := 8 
    );
    PORT (
        clock : IN STD_LOGIC ;
        
        reset : IN STD_LOGIC ;
        idle : OUT STD_LOGIC ;
        trigger : IN STD_LOGIC ;

        bits32 : IN STD_LOGIC_VECTOR(31 DOWNTO 0) ;    
        
        uart_rx : IN STD_LOGIC ;
        uart_tx : OUT STD_LOGIC
    );
END loader32_to_8;

ARCHITECTURE loader328 OF loader32_to_8 IS

    COMPONENT uart IS
    GENERIC(
        clk_freq  :  INTEGER ;
        baud_rate :  INTEGER ;     
        d_width   :  INTEGER        
    );
    PORT(
        clk      :  IN   STD_LOGIC;                             
        tx_ena   :  IN   STD_LOGIC;                             
        tx_data  :  IN   STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);  
        rx       :  IN   STD_LOGIC;                          
        rx_busy  :  OUT  STD_LOGIC;                           
        rx_error :  OUT  STD_LOGIC;                             
        rx_data  :  OUT  STD_LOGIC_VECTOR(d_width-1 DOWNTO 0); 
        tx_busy  :  OUT  STD_LOGIC;                           
        tx       :  OUT  STD_LOGIC                          
    );
    END COMPONENT;

    SIGNAL input_line : STD_LOGIC_VECTOR(31 DOWNTO 0) := x"00000000" ;
    SIGNAL byten : UNSIGNED(2 DOWNTO 0) := "111" ;
    SIGNAL bytxt : UNSIGNED(1 DOWNTO 0) := "00" ;

    SIGNAL uart_rx_error : STD_LOGIC ;
    SIGNAL uart_rx_busy : STD_LOGIC ;
    SIGNAL uart_tx_busy : STD_LOGIC ;
    SIGNAL uart_tx_ena : STD_LOGIC := '0' ;
    SIGNAL bits8 : STD_LOGIC_VECTOR(uart_d_width-1 DOWNTO 0) ;

BEGIN

MAIN: PROCESS(clock, reset, trigger)
    BEGIN
        IF (reset='1') THEN
            bits8 <= x"00" ;
            uart_tx_ena <= '0' ;
            idle <= '1' ;
            byten <= "000" ;

        ELSIF RISING_EDGE(clock) THEN

                CASE byten IS
                ------------------------------------------------------------------------------
                    WHEN "000" =>       --Waiting for first activity
                        IF (trigger='1' AND uart_tx_busy='0') THEN
                            input_line <= bits32 ;      --Only latch on to input line here
                            byten <= "001" ;
                            idle <= '0' ; 
                        ELSE
                            idle <= '1' ;
                        END IF;
                    -------------------------------------------------------------------------------
                    WHEN "001" =>       --Enable the UART
                        uart_tx_ena <= '1' ;
                        CASE bytxt IS
                            WHEN "00" =>      
                                bits8 <= input_line(31 DOWNTO 24) ;
                                bytxt <= "01" ;                  
                            WHEN "01" =>
                                bits8 <= input_line(23 DOWNTO 16) ;
                                bytxt <= "10" ;
                            WHEN "10" =>
                                bits8 <= input_line(15 DOWNTO 8) ; 
                                bytxt <= "11" ;
                            WHEN "11" =>
                                bits8 <= input_line(7 DOWNTO 0) ;
                                bytxt <= "00" ;
                        END CASE;
                    ------------------------------------------------------------------------------
                        IF (uart_tx_busy='1') THEN
                            byten <= "010" ;
                        END IF;
                    ------------------------------------------------------------------------------
                    WHEN "010" =>       --Wait for UART to go idle again
                        uart_tx_ena <= '0' ;
                        IF (uart_tx_busy='0') THEN
                            IF (bytxt="00") THEN       --If we had just sent the final byte
                                byten <= "000" ;
                            ELSE
                                byten <= "001" ;
                            END IF;
                        END IF;
                    ------------------------------------------------------------------------------
                    WHEN OTHERS =>
                        byten <= "000" ;
                    ------------------------------------------------------------------------------
                END CASE;
        END IF;
END PROCESS;


PCCONN: uart
GENERIC MAP (clk_freq => master_clock, baud_rate => uart_baud_rate, d_width => uart_d_width)
PORT MAP (
    clk => clock,  
    tx_ena => uart_tx_ena, 
    tx_data => bits8,
    rx => uart_rx, 
    rx_busy => OPEN, 
    rx_error => OPEN, 
    rx_data => OPEN,
    tx_busy => uart_tx_busy,
    tx => uart_tx
);  

END loader328;