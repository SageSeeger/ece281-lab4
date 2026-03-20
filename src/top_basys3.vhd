library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_basys3 is
    port(
        -- inputs
        clk     : in std_logic;
        sw      : in std_logic_vector(15 downto 0);
        btnU    : in std_logic; -- master_reset
        btnL    : in std_logic; -- clk_reset (unused now)
        btnR    : in std_logic; -- fsm_reset
        
        -- outputs
        led : out std_logic_vector(15 downto 0);
        seg : out std_logic_vector(6 downto 0);
        an  : out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is

    -- SIGNALS
    signal floor1, floor2 : std_logic_vector(3 downto 0);
    signal stopped1, stopped2 : std_logic;
    signal dir1, dir2 : std_logic;
    signal slow_clk : std_logic;

    signal tdm_data : std_logic_vector(3 downto 0);
    signal tdm_sel  : std_logic_vector(3 downto 0);

    -- COMPONENTS
    component sevenseg_decoder is
        port (
            i_Hex   : in  STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component;

    component elevator_controller_fsm is
        port (
            i_clk        : in  STD_LOGIC;
            i_reset      : in  STD_LOGIC;
            is_stopped   : in  STD_LOGIC;
            go_up_down   : in  STD_LOGIC;
            o_floor      : out STD_LOGIC_VECTOR (3 downto 0)
        );
    end component;

    component TDM4 is
        generic (k_WIDTH : natural := 4);
        port (
            i_clk  : in  STD_LOGIC;
            i_reset: in  STD_LOGIC;
            i_D3   : in  STD_LOGIC_VECTOR (k_WIDTH-1 downto 0);
            i_D2   : in  STD_LOGIC_VECTOR (k_WIDTH-1 downto 0);
            i_D1   : in  STD_LOGIC_VECTOR (k_WIDTH-1 downto 0);
            i_D0   : in  STD_LOGIC_VECTOR (k_WIDTH-1 downto 0);
            o_data : out STD_LOGIC_VECTOR (k_WIDTH-1 downto 0);
            o_sel  : out STD_LOGIC_VECTOR (3 downto 0)
        );
    end component;

    component clock_divider is
        generic (k_DIV : natural := 2);
        port (
            i_clk   : in std_logic;
            i_reset : in std_logic;
            o_clk   : out std_logic
        );
    end component;

begin

    -- CLOCK DIVIDER 
    CLK_DIV: clock_divider
        generic map (
            k_DIV => 50000000   -- 0.5 sec 
        )
        port map (
            i_clk   => clk,
            i_reset => btnU,    -- master reset
            o_clk   => slow_clk
        );

    -- FSM INSTANCES
    ELEVATOR1: elevator_controller_fsm
        port map (
            i_clk        => slow_clk,
            i_reset      => btnU,  -- master reset
            is_stopped   => sw(0),
            go_up_down   => sw(1),
            o_floor      => floor1
        );

    ELEVATOR2: elevator_controller_fsm
        port map (
            i_clk        => slow_clk,
            i_reset      => btnU,  -- same reset
            is_stopped   => sw(14),
            go_up_down   => sw(15),
            o_floor      => floor2
        );

    -- TDM DISPLAY 
    TDM_INST: TDM4
        port map (
            i_clk   => clk,       -- fast clock for display
            i_reset => btnU,

            i_D3 => "1111",   -- Display 3 → F
            i_D2 => floor2,   -- Display 2 → Elevator 2
            i_D1 => "1111",   -- Display 1 → F
            i_D0 => floor1,   -- Display 0 → Elevator 1

            o_data => tdm_data,
            o_sel  => tdm_sel
        );

    -- 7-SEG DECODER 
    SEG_DEC: sevenseg_decoder
        port map (
            i_Hex   => tdm_data,
            o_seg_n => seg
        );

    -- OUTPUTS
    an <= tdm_sel;

    -- LED 15 = FSM clock
    led(15) <= slow_clk;

    -- Debug LEDs (floors)
    led(3 downto 0) <= floor1;
    led(7 downto 4) <= floor2;

    -- Ground unused LEDs
    led(14 downto 8) <= (others => '0');

end top_basys3_arch;