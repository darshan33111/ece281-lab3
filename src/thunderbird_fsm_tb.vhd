--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm_tb.vhd (TEST BENCH)
--| AUTHOR(S)     : Capt Phillip Warner
--| CREATED       : 03/2017
--| DESCRIPTION   : This file tests the thunderbird_fsm modules.
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : thunderbird_fsm_enumerated.vhd, thunderbird_fsm_binary.vhd, 
--|				   or thunderbird_fsm_onehot.vhd
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  
entity thunderbird_fsm_tb is
end thunderbird_fsm_tb;

architecture test_bench of thunderbird_fsm_tb is 
	
	component thunderbird_fsm is 
	  port (
        i_clk, i_reset  : in    std_logic;
        i_left, i_right : in    std_logic;
        o_lights_L      : out   std_logic_vector(2 downto 0);
        o_lights_R      : out   std_logic_vector(2 downto 0)
    );
	end component thunderbird_fsm;

	-- test I/O signals
	signal w_clk : std_logic := '0';
	signal w_reset : std_logic := '0';
	signal w_left : std_logic := '0';
	signal w_right : std_logic := '0';
	
	signal w_lights_L : std_logic_vector(2 downto 0) := "000";
	signal w_lights_R : std_logic_vector(2 downto 0) := "000";
	-- constants
	constant k_clk_period : time := 10 ns;
	
	
begin
	-- PORT MAPS ----------------------------------------
	uut: thunderbird_fsm port map (
          i_left => w_left,
          i_right => w_right,
          i_reset => w_reset,
          i_clk => w_clk,
          o_lights_L => w_lights_L,
          o_lights_R => w_lights_R
        );
	-----------------------------------------------------
	
	-- PROCESSES ----------------------------------------	
    -- Clock process ------------------------------------
	clk_proc : process
	begin
		w_clk <= '0';
        wait for k_clk_period/2;
		w_clk <= '1';
		wait for k_clk_period/2;
	end process;
	----------------------------------------------------------------
	
	-- Test Plan Process --------------------------------
	sim_proc: process
	begin
		-- sequential timing		
		
		--This one tests what happens when you apply a reset, 
		--as the default state is OFF it should move to the OFF state
		w_reset <= '1';
		wait for k_clk_period*1;
		  assert w_lights_L = "000" and w_lights_R = "000" report "bad reset" severity failure;
		
		w_reset <= '0';
		wait for k_clk_period*1;
		
		-- The left and the right turn signals are on, which means that it should move to ON(all lights on) state and 
		-- then back to OFF, on repeat until left and right signals are turned off
		w_left <= '1'; 
		w_right <= '1'; 
		wait for k_clk_period*1;
          assert w_lights_L = "111" and w_lights_R = "111" report "all lights should be on when L and R on" severity failure;
        wait for k_clk_period*1;
          assert w_lights_L = "000" and w_lights_R = "000" report "should be transitioning to off state" severity failure;
        wait for k_clk_period*1;
          assert w_lights_L = "111" and w_lights_R = "111" report "all lights should be on when L and R on" severity failure;
        wait for k_clk_period*1;
          assert w_lights_L = "000" and w_lights_R = "000" report "should be transitioning to off state" severity failure;
        w_left <= '0'; 
        w_right <= '0';
        
        --Upon just the right indicator being on, it should cycle through the states from just being RA on,
        -- to all three rights on to back to off
        w_right <= '1'; 
        wait for k_clk_period*1;
            assert w_lights_R = "001" report "Should be just RA" severity failure;
        wait for k_clk_period*1;
            assert w_lights_R = "011" report "Should be just RA and RB" severity failure;
        wait for k_clk_period*1;
            assert w_lights_R = "111" report "Should be all reds on" severity failure;
        wait for k_clk_period*1;
            assert w_lights_R = "000" report "Should be back to off" severity failure;
        w_right <= '0';
        
        --Upon just the left indicator being on, it should cycle through the states from just being LA on,
        -- to all three lefts on to back to off
        w_left <= '1'; 
        wait for k_clk_period*1;
            assert w_lights_L = "001" report "Should be just LA" severity failure;
        wait for k_clk_period*1;
            assert w_lights_L = "011" report "Should be just LA and LB" severity failure;
        wait for k_clk_period*1;
            assert w_lights_L = "111" report "Should be all lefts on" severity failure;
        wait for k_clk_period*1;
            assert w_lights_L = "000" report "Should be back to off" severity failure;
        w_left <= '0';
        
        
        --Start off with the left indicator being on, but then suddenly turn the right indicator on after 
        --moving through all states of left and being back to OFF, which should
        -- move it to an ON/blinkers state
        w_left <= '1'; 
        wait for k_clk_period*4;
            assert w_lights_L = "001" report "Should be just LA" severity failure;
        w_right <= '1'; 
        wait for k_clk_period*1;
             assert w_lights_L = "111" and w_lights_R = "111" report "all lights should be on when L and R on" severity failure;
        w_left <= '0'; 
        w_right <= '0';     
		wait;
	end process;
	----------------------------------------------------------------
	
end test_bench;
