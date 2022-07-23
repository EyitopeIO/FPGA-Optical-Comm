--    File Name:  md.vhd
--      Version:  1.0
--         Date:  January 22, 2000
--        Model:  Manchester decoder Chip
--
--      Company:  Xilinx
--
--
--   Disclaimer:  THESE DESIGNS ARE PROVIDED "AS IS" WITH NO WARRANTY 
--                WHATSOEVER AND XILINX SPECIFICALLY DISCLAIMS ANY 
--                IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR
--                A PARTICULAR PURPOSE, OR AGAINST INFRINGEMENT.
--
--                Copyright (c) 2000 Xilinx, Inc.
--                All rights reserved
--

library ieee ;
use ieee.std_logic_1164.all ;
use ieee.std_logic_arith.all ;

entity md is
port (rst,clk16x,mdi,rdn : in std_logic ;
	dout : out std_logic_vector (7 downto 0) ;
	data_ready : out std_logic 
) ;
end md ;

architecture v1 of md is

signal clk1x_enable : std_logic ;
signal mdi1 : std_logic ;
signal mdi2 : std_logic ;
signal rsr : std_logic_vector (7 downto 0) ;
signal dout_i : std_logic_vector (7 downto 0) ;
signal no_bits_rcvd : unsigned (3 downto 0) ;
signal clkdiv : unsigned (3 downto 0) ;
signal nrz : std_logic ;
signal clk1x : std_logic ;
signal sample : std_logic ;

begin

-- Generate two FF register to accept serial Manchester data in

process (rst,clk16x)
begin
if rst = '1' then
mdi1 <= '0' ;
mdi2 <= '0' ;
elsif clk16x'event and clk16x = '1' then 
mdi2 <= mdi1 ;
mdi1 <= mdi ;
end if ;
end process ;

-- Enable the clock when an edge on mdi is detected

process (rst,clk16x,mdi1,mdi2,no_bits_rcvd)
begin
if rst = '1' then
clk1x_enable <= '0' ;
elsif clk16x'event and clk16x = '1' then
if mdi1 = '0' and mdi2 = '1' then
clk1x_enable <= '1' ;
else if std_logic_vector(no_bits_rcvd) = "1101" then
clk1x_enable <= '0' ;
end if ;
end if ;
end if ;
end process ;

-- Center sample the data at 1/4 and 3/4 points in data cell

sample <= ((not clkdiv(3)) and (not clkdiv(2)) and clkdiv(1) and clkdiv(0)) or (clkdiv(3) and clkdiv(2) and (not clkdiv(1)) and (not clkdiv(0))) ; 

-- Decode Manchester data into NRZ

process (rst,sample,mdi2,clk16x,no_bits_rcvd)
begin
if rst = '1' then
nrz <= '0' ;
elsif clk16x'event and clk16x = '1' then
if std_logic_vector(no_bits_rcvd) > "000" and sample = '1' then
nrz <= mdi2 xor clk1x ;
end if ;
end if ;
end process ;

-- Increment the clock

process (rst,clk16x,clk1x_enable,clkdiv)
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

-- Serial to parallel conversion

process (rst,clk1x,dout_i,nrz)
begin
if rst = '1' then
rsr <= "00000000" ;
elsif clk1x'event and clk1x = '1' then
rsr <= rsr(6 downto 0) & nrz ;
end if ;
end process ;

-- Transfer from shift to data register

process (rst,clk1x,no_bits_rcvd)
begin
if rst = '1' then
dout_i <= "00000000" ;
elsif clk1x'event and clk1x = '1' then
if std_logic_vector(no_bits_rcvd) = "1001" then
dout_i <= rsr ;
end if ;
end if ;
end process ;

-- Track no of bits rcvd for word size 

process (rst,clk1x,clk1x_enable,no_bits_rcvd)
begin
if rst = '1' then 
no_bits_rcvd <= "0000" ;
elsif clk1x'event and clk1x = '1' then
if (clk1x_enable = '0') then
no_bits_rcvd <= "0000" ;
else
no_bits_rcvd <= no_bits_rcvd + "0001" ;
end if ;
end if ;
end process ;

-- Generate data_ready status signal

process (rst,clk1x,clk1x_enable,rdn)
begin
if (rst = '1' or rdn = '0') then
data_ready <= '0' ;
elsif clk1x'event and clk1x = '1' then
if (clk1x_enable = '0') then
data_ready <= '1' ;
else data_ready <= '0' ;
end if ;
end if ;
end process ;

dout <= dout_i ;

end ;

