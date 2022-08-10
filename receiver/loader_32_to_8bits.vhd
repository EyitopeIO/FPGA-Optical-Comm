
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
        
        busy : OUT STD_LOGIC ;
        trigger : IN STD_LOGIC ;

        bits32 : IN STD_LOGIC_VECTOR(31 DOWNTO 0) ;
            
--        ubus : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) ;
--        txena : OUT STD_LOGIC ;
--        txbyten : OUT STD_LOGIC_VECTOR(2 DOWNTO 0) ;
--        txb : OUT STD_LOGIC ;

        
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
    SIGNAL byten : UNSIGNED(2 DOWNTO 0) := "000" ;
    SIGNAL byten_next : UNSIGNED(2 DOWNTO 0) := "000" ;
    SIGNAL busyline : STD_LOGIC := '0' ;

    SIGNAL uart_rx_error : STD_LOGIC ;
    SIGNAL uart_rx_busy : STD_LOGIC ;
    SIGNAL uart_tx_busy : STD_LOGIC ;
    SIGNAL uart_tx_ena : STD_LOGIC := '0' ;
    SIGNAL uart_nx_byte : STD_LOGIC ; 

    SIGNAL uart_tx_tmp1 : STD_LOGIC := '0' ;
    SIGNAL bits8 : STD_LOGIC_VECTOR(uart_d_width-1 DOWNTO 0) := x"00" ;

BEGIN

--    busy <= busyline ;
--    ubus <= bits8 ;
--    txena <= uart_tx_ena ;
--    txb <= uart_tx_busy ;
--    txbyten <= STD_LOGIC_VECTOR(byten) ;

MAIN: PROCESS(clock, reset, trigger, input_line, byten_next, uart_tx_busy)
    BEGIN
        IF (reset='1') THEN
            input_line <= x"00000000" ;
            busyline <= '0' ;
            byten <= "000" ;
            uart_tx_ena <= '0' ;

        ELSIF RISING_EDGE(clock) THEN

            CASE byten IS
                WHEN "000" =>
                    IF (trigger='1') THEN
                        input_line <= bits32 ;
                        uart_tx_ena <= '1' ;
                        busyline <= '1' ;
                        byten_next <= "001" ;
                        byten <= "110" ;
                    END IF;
                    
                WHEN "001" =>
                    uart_tx_ena <= '0' ;
                    bits8 <= input_line(31 DOWNTO 24) ;
                    IF (uart_tx_busy='0') THEN
                        uart_tx_ena <= '1' ;
                        byten_next <= "010" ;
                        byten <= "110" ;
                    END IF;
                    
                WHEN "010" =>
                    uart_tx_ena <= '0' ;
                    bits8 <= input_line(23 DOWNTO 16) ;            
                    IF (uart_tx_busy='0') THEN
                        uart_tx_ena <= '1' ;
                        byten_next <= "011" ;
                        byten <= "110" ;
                    END IF;
                    
                WHEN "011" =>
                    uart_tx_ena <= '0' ;                
                    bits8 <= input_line(15 DOWNTO 8) ;
                    IF (uart_tx_busy='0') THEN
                        uart_tx_ena <= '1' ;                    
                        byten_next <= "100" ;
                        byten <= "110" ;
                    END IF;          
                       
                WHEN "100" =>
                    uart_tx_ena <= '0' ;                
                    bits8 <= input_line(7 DOWNTO 0) ;         
                    IF (uart_tx_busy='0') THEN
                        uart_tx_ena <= '1' ;                    
                        byten_next <= "101" ;
                        byten <= "110" ;
                    END IF; 
                    
                WHEN "101" =>           --Final state
                    uart_tx_ena <= '0' ;                
                    IF (uart_tx_busy='0') THEN
                        byten_next <= "000" ;
                        byten <= "110" ;
                        busyline <= '0' ;
                    END IF;
                                        
                WHEN "110" =>           --For empty clock cycle
                    byten <= byten_next ;
                    
                WHEN OTHERS =>          --Never happening
                    busyline <= '1' ;
                    byten <= "111" ;

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