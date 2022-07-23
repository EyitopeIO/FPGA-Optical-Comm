--    File Name:  med.vhd
--    Version:  1.1
--    Date:  January 22, 2000
--    Model:  Manchester Encoder Decoder Chip
--    Dependencies:  md.hd, me.vhd
--
--    Company:  Xilinx
--
--
--    Disclaimer:  THESE DESIGNS ARE PROVIDED "AS IS" WITH NO WARRANTY 
--                WHATSOEVER AND XILINX SPECIFICALLY DISCLAIMS ANY 
--                IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR
--                A PARTICULAR PURPOSE, OR AGAINST INFRINGEMENT.
--
--                Copyright (c) 2000 Xilinx, Inc.
--                All rights reserved


library ieee;
use ieee.std_logic_1164.all ;
use ieee.std_logic_arith.all ;
use ieee.std_logic_unsigned.all ;

entity med is
PORT (rst,clk16x,mdi,rdn,wrn  : in std_logic;
din : in std_logic_vector(7 downto 0);
dout : out std_logic_vector(7 downto 0);
data_ready : out std_logic;
mdo : out std_logic;
tbre : out std_logic);
end med;

architecture v1 of med is

component md 
port (rst,clk16x,mdi,rdn : in std_logic ;
	dout : out std_logic_vector (7 downto 0) ;
	data_ready : out std_logic ) ;
end component  ;

component me
port (rst,clk16x,wrn : in std_logic ;
	din : in std_logic_vector (7 downto 0) ;
	tbre : out std_logic ;
	mdo   : out std_logic ) ;
end component ;

begin
   
u1 : md PORT MAP 
(rst => rst,
clk16x => clk16x,
mdi => mdi,
rdn => rdn,
dout => dout,
data_ready => data_ready);

u2 : me PORT MAP  
(rst => rst,
clk16x => clk16x,
wrn => wrn,
din => din,
tbre => tbre,
mdo => mdo) ;

end v1 ;



