library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity project_reti_logiche is
    port( 
        i_clk     : in std_logic;
        i_rst     : in std_logic;
        i_start   : in std_logic;
        i_data    : in std_logic_vector(7 downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done    : out std_logic;
        o_en      : out std_logic;
        o_we      : out std_logic; 
        o_data    : out std_logic_vector(7 downto 0));
end project_reti_logiche;

architecture FSM of project_reti_logiche is

--definisco gli stati
    type state_type is (IDLE,READ_COL,READ_ROW,NUM_PIX,CALC_TOT,READ_MAX_MIN,CALC_MAX_MIN,INIT,READ_PIX,CALC_PIX, WRITE_PIX, DONE);
    
--registri
    signal state, next_state: state_type := IDLE;
    signal d_done, q_done: std_logic:= '0';
    signal d_currentaddress, q_currentaddress: std_logic_vector(15 downto 0) := (others => '0');
    signal d_totPixel, q_totPixel: std_logic_vector(14 downto 0) := (others => '0');
    signal d_max, q_max: std_logic_vector(7 downto 0) := (others => '0');
    signal d_min, q_min: std_logic_vector(7 downto 0) := (others => '0');
    signal d_col,q_col: std_logic_vector(7 downto 0) := (others => '0');
    signal d_row, q_row: std_logic_vector(7 downto 0) := (others => '0');
    signal d_shiftLevel, q_shiftLevel: std_logic_vector(7 downto 0) := (others => '0');
    signal d_tempPix, q_tempPix: std_logic_vector(15 downto 0) := (others => '0');
    
    -- constanti
    constant n0 : std_logic_vector(7 downto 0):= (others => '0');
    constant n255: std_logic_vector(7 downto 0) := (others => '1');
    
begin

  state_clock: process(
        i_clk,
        i_rst
    )
    
    begin
    
    if i_rst = '1' then
        state <= IDLE;
        q_done <= '0';
        q_currentaddress <= (others => '0');
        q_totpixel <= (others => '0');
        q_max <= (others => '0');
        q_row <= (others => '0');
        q_col <= (others => '0');
        q_min <= (others => '1');
        q_shiftlevel <= (others => '0');
        q_temppix <= (others => '0');
        
    elsif rising_edge(i_clk) then
        state <= next_state;
        q_done <= d_done;
        q_currentaddress <= d_currentaddress;
        q_totpixel <= d_totpixel;
        q_min <= d_min;
        q_max <= d_max; 
        q_col <= d_col;
        q_row <= d_row;
        q_shiftlevel <= d_shiftlevel;
        q_temppix <= d_temppix;
        
    end if;
    
end process;

state_comb: process(
    i_start,
    i_data,
    state,
    q_done,
    q_col,
    q_row,
    q_currentaddress,
    q_totpixel,
    q_min,
    q_max,
    q_shiftlevel,
    q_temppix
    )
    
    variable deltavalue: integer range 0 to 256;
    --variable diff: std_logic_vector(7 downto to 0);
    variable tempdiff: std_logic_vector(15 downto 0);
    variable temppix: std_logic_vector(7 downto 0);
    variable numcol: std_logic_vector(7 downto 0);
    
    begin 
    next_state <= state;
    d_done <= q_done;
    d_currentaddress <= q_currentaddress;
    d_totpixel <= q_totpixel;
    d_min <= q_min;
    d_max <= q_max;
    d_shiftlevel <= q_shiftlevel;
    d_temppix <= q_temppix;
    d_col <= q_col;
    d_row <= q_row;
    
    --default
    o_address <= (others => '0');
    o_data <= (others => '0');
    o_en <= '0';
    o_we <= '0';
    o_done <= q_done;
    
    case state is
        when IDLE =>
            --inizializzo
            d_done <= '0';
            d_currentaddress <= (others => '0');
            d_totpixel <= (others => '0');
            d_min <= (others => '1');
            d_row <= (others => '0');
            d_col <= (others => '0');
            d_max <= (others => '0');
            d_shiftlevel <= (others => '0');
            d_temppix <= (others => '0');
            
             if i_start = '1' and q_done = '0' then
                next_state <= READ_COL;
             elsif i_start = '0' and q_done = '1' then
                d_done <= '0';
                next_state <= IDLE;
             else 
                next_state <= IDLE;
             end if;
        when READ_COL =>
            o_en <= '1';
            o_address <= q_currentaddress;
            d_currentaddress <= q_currentaddress + 1;
            next_state <= READ_ROW;
        when READ_ROW =>
            o_en <= '1';
            if (i_data = n0) then
                next_state <= DONE;
             else
                d_col <= i_data;
                --d_totpixel <= std_logic_vector(resize(unsigned(i_data),15));
                o_address <= q_currentaddress;
                d_currentaddress <= q_currentaddress +1;
                next_state <= NUM_PIX;
            end if;
        when NUM_PIX =>
            o_en <= '1';
            if( i_data = n0) then
                next_state <= DONE;
            else 
            d_row <= i_data;
            o_address <= q_currentaddress;
            next_state <= CALC_TOT;
            --numrow := std_logic_vector(resize((unsigned(i_data)), 15));
            --d_totpixel <= std_logic_vector(to_unsigned(
            --                                          to_integer(unsigned(q_totpixel))* to_integer(unsigned(numrow))
            --                               ,15)
            --                );
            --next_state <= READ_MAX_MIN;
            end if;
        when CALC_TOT =>
             o_en <= '1';
             o_address <= q_currentaddress;
             if (q_col /= n0) then
                d_totpixel <= q_totpixel + q_row;
                d_col <= q_col - 1;
                next_state <= CALC_TOT;
             elsif (q_col = n0) then
                next_state <= READ_MAX_MIN;
             end if;
        when READ_MAX_MIN => 
            o_en <= '1';
            o_address <= q_currentaddress;
            if(q_totpixel = 0) then
                next_state <= DONE;
            else 
            next_state <= CALC_MAX_MIN;
            end if;
        when CALC_MAX_MIN =>
            o_en <= '1';
            --check se è nuovo massimo o minimo
            if i_data = n255 then
                    d_max <= n255;
            elsif  i_data > q_max then
                    d_max <= i_data;
            end if;
            
            if i_data = n0 then
                    d_min <= n0;
            elsif i_data < q_min then
                    d_min <= i_data;
            end if;
            
            if ((q_min = n0) and (q_max = n255)) or q_currentaddress = (q_totpixel + 1) then
                  next_state <= INIT; 
            else
                  d_currentaddress <= q_currentaddress +1;
                  next_state <= READ_MAX_MIN; 
            end if; 
        when INIT =>
            o_en <= '1';
            deltavalue := to_integer(unsigned(q_max - q_min));
            d_currentaddress <= std_logic_vector(to_unsigned( 2 , 16));
            o_address <= std_logic_vector(to_unsigned( 2 , 16));
                    case deltavalue is
                        when 0 => d_shiftlevel <= std_logic_vector(to_unsigned( 8 , 8));
                        when 1 to 2 => d_shiftlevel <= std_logic_vector(to_unsigned( 7 , 8));
                        when 3 to 6 => d_shiftlevel <= std_logic_vector(to_unsigned( 6 , 8));
                        when 7 to 14 => d_shiftlevel <= std_logic_vector(to_unsigned( 5 , 8));
                        when 15 to 30 => d_shiftlevel <= std_logic_vector(to_unsigned( 4 , 8));
                        when 31 to 62 => d_shiftlevel <= std_logic_vector(to_unsigned( 3 , 8));
                        when 63 to 126 => d_shiftlevel <= std_logic_vector(to_unsigned( 2 , 8));
                        when 127 to 254 => d_shiftlevel <= std_logic_vector(to_unsigned( 1 , 8));
                        when others => d_shiftlevel <= n0;
                    end case;
            next_state <= READ_PIX;
        when READ_PIX =>
            o_en <= '1';
            o_address <= q_currentaddress;
            next_state <= CALC_PIX;
        when CALC_PIX =>
            o_en <= '1';
            --o_we <= '1';
            --shift operation
            --diff := i_data - q_min;
            if (q_shiftlevel /= n0) then 
                tempdiff := std_logic_vector(resize(unsigned(i_data - q_min),16));
                -- da aggiungere se q_shiftleve = 0 allora d_temppix = i_data
                d_temppix <= std_logic_vector(shift_left(unsigned(tempdiff),to_integer(unsigned(q_shiftlevel))));
            else
                d_temppix <= std_logic_vector(resize(unsigned(i_data),16));
            end if;
            o_address <= q_currentaddress + q_totpixel;
            --d_currentaddress <= q_currentaddress + q_totpixel;
              
            next_state <= WRITE_PIX;
        when WRITE_PIX =>
            o_en <= '1';
            o_we <= '1';
            o_address <= q_currentaddress + q_totpixel;
            if q_temppix > n255 then
                o_data <= n255;
            else
                o_data <= q_temppix(7 downto 0);
            end if;
            
            if q_currentaddress = ( 1 + q_totpixel ) then
                next_state <= DONE;
            else
                d_currentaddress <= q_currentaddress +1;
                next_state <= READ_PIX;
            end if;
                       
        when DONE =>
            o_done <= '1';
            d_done <= '1';
            next_state <= IDLE; 

     end case;
  end process;
end FSM;