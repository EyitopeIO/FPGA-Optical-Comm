--    File Name:  me.vhd
--    Version:  1.0
--    Date:  January 22, 2000
--    Model:  Manchester Encoder Chip
--
--    Company:  Xilinx
--
--
--   Disclaimer:  THESE DESIGNS ARE PROVIDED "AS IS" WITH NO WARRANTY 
--                WHATSOEVER AND XILINX SPECIFICALLY DISCLAIMS ANY 
--                IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR
--                A PARTICULAR PURPOSE, OR AGAINST INFRINGEMENT.
--
--                Copyright (c) 2000 Xilinx, Inc.
--                All rights reserved

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_arith.all ;
use ieee.std_logic_unsigned.all ;

entity me is
port (rst,clk16x,wrn : in std_logic ;
	din : in std_logic_vector (7 downto 0) ;
	tbre : out std_logic ;
	mdo   : out std_logic 
) ;
end me ;

architecture v1 of me is

signal clk1x : std_logic ;
signal clk1x_enable : std_logic ;
signal clkdiv : std_logic_vector (3 downto 0) ;
signal tsr : std_logic_vector (7 downto 0) ;
signal tbr : std_logic_vector (7 downto 0) ;
signal parity : std_logic ;
signal no_bits_sent : std_logic_vector (3 downto 0) ;
signal wrn1 : std_logic ;
signal wrn2 : std_logic ;
signal clk1x_disable : std_logic ;

begin

-- Form two bit register for write pulse

process (rst,clk16x,wrn,wrn1,wrn2)
begin
if rst = '1' then
wrn2 <= '1' ;
wrn1 <= '1' ;
elsif clk16x'event and clk16x = '1' then
wrn2 <= wrn1 ;
wrn1 <= wrn ;
end if ;
end process ;

-- Enable clock when detect edge on write pulse 

process (rst,clk16x,wrn1,wrn2,no_bits_sent)
begin
if rst = '1' or std_logic_vector(no_bits_sent) = "1010" then
clk1x_enable <=  '0' ;
elsif clk16x'event and clk16x = '1' then
if (wrn1 = '1' and wrn2 = '0')  then 
clk1x_enable <= '1' ;
elsif std_logic_vector(no_bits_sent) = "1001" then
clk1x_enable <= '0' ;
end if ;
end if ;
end process ;

-- Generate Transmit Buffer Register Empty signal

process (rst,clk16x,wrn1,wrn2,no_bits_sent)
begin
if rst = '1' then
tbre <= '1' ;
elsif clk16x'event and clk16x = '1' then
if (wrn1 = '1' and wrn2 = '0')  then
tbre <= '0' ;
elsif (std_logic_vector(no_bits_sent) = "0010") then
tbre <= '1' ;
else 
tbre <= '0' ;
end if ;
end if ;
end process ;

-- Detect edge on write pulse to load transmit buffer

process (rst,clk16x,wrn1,wrn2)
begin
if rst = '1' then 
tbr <= "00000000" ;
elsif clk16x'event and clk16x = '0' then
if wrn1 = '1' and wrn2 = '0' then
tbr <= din ;
end if ;
end if ;
end process ;

-- Increment clock 

process (rst,clk16x,clkdiv,clk1x_enable)
begin
if rst = '1' then
clkdiv <= "0000" ;
elsif clk16x'event and clk16x = '1' then
if clk1x_enable = '1' then
clkdiv <= clkdiv + "0001" ;
end if ;
end if ;
end process ;

clk1x <= clkdiv(3) ;

-- Load TSR from TBR, shift TSR

process (rst,clk1x,no_bits_sent,tsr)
begin
if rst = '1' then
tsr <= "00000000" ;
elsif clk1x'event and clk1x = '1' then
if std_logic_vector(no_bits_sent) = "0001" then
tsr <= tbr ;
elsif std_logic_vector(no_bits_sent) >= "0010" and std_logic_vector(no_bits_sent) <= "1010" then
tsr <= tsr(6 downto 0)  & '0' ;
else
tsr <= tsr ;
end if ;
end if ;
end process ;

-- Generate Manchester data from NRZ

mdo <= tsr(7) xor clk1x ;

-- Generate parity

process (rst,clk1x,tsr(7))
begin
if rst = '1' then 
parity <= '0' ;
elsif clk1x'event and clk1x = '1' then
parity <= parity xor tsr(7) ;
end if ;
end process ;

-- Calculate the number of bits sent

process (clk1x,rst,clk1x_disable,clk1x_enable,no_bits_sent)
begin 
if rst = '1' or clk1x_disable = '1' then
no_bits_sent <= "0000" ;
elsif clk1x'event and clk1x = '1'  then
if clk1x_enable = '1' then
no_bits_sent <= no_bits_sent + "0001" ;
end if  ;
end if  ;
end process ;

clk1x_disable <= not clk1x_enable ;

end ;

