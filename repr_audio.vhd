library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity repr_audio is
    port (
        clk_50MHz      : in  std_logic;
        reset          : in  std_logic;
        audio_out      : out std_logic;
        audio_data     : in  std_logic_vector(23 downto 0);
        audio_valid    : in  std_logic;
        vu_meter       : out std_logic_vector(7 downto 0);
        i2c_sclk       : buffer std_logic;
        i2c_sdat       : inout std_logic
    );
end entity repr_audio;

architecture Behavioral of repr_audio is
    signal counter     : unsigned(23 downto 0);
    signal vu_counter  : unsigned(3 downto 0);
    signal vu_level    : std_logic_vector(7 downto 0);
    signal vu_meter_en : std_logic := '0';
    signal audio_sample: std_logic_vector(23 downto 0);
    signal audio_index : integer range 0 to 65535 := 0;
begin
    process (clk_50MHz, reset)
    begin
			if reset = '1' then
				 counter     <= (others => '0');
				 vu_counter  <= (others => '0');
				 vu_level    <= (others => '0');
				 audio_index <= 0;
			elsif rising_edge(clk_50MHz) then
				 if audio_valid = '1' then
					  counter <= counter + to_unsigned(1, counter'length);

					  if counter = "111111111111111111111111" then
							audio_out <= audio_sample(0);
					  else
							audio_out <= '0';
					  end if;

					  if vu_meter_en = '1' then
							if vu_counter = "1111" then
								 vu_level   <= std_logic_vector(unsigned(vu_level) + 1);
								 vu_counter <= (others => '0');
							else
								 vu_counter <= vu_counter + 1;
							end if;
					  end if;
					  
					  audio_index <= audio_index + 1; -- Here we increment the audio_index
				 else
					  audio_out <= '0';
				 end if;
			end if;

    end process;
    
    process (clk_50MHz, reset)
    begin
        if reset = '1' then
            vu_meter <= (others => '0');
        elsif rising_edge(clk_50MHz) then
            if vu_counter = "0000" then
                vu_meter_en <= '1';
            else
                vu_meter_en <= '0';
            end if;
            
            vu_meter <= vu_level;
        end if;
    end process;
    
    process (clk_50MHz, reset)
    begin
        if reset = '1' then
            audio_sample <= (others => '0');
        elsif rising_edge(clk_50MHz) then
            if audio_index = 0 then
                audio_sample <= "101010101010101010101010";
            end if;
        end if;
    end process;
    
    process (clk_50MHz, reset)
    begin
        if reset = '1' then
            i2c_sclk <= '0';
        elsif rising_edge(clk_50MHz) then
            if vu_counter = "1000" then
                i2c_sdat <= '0';
            elsif vu_counter = "1001" then
                i2c_sdat <= 'Z';
            end if;
            
            if vu_counter = "1111" then
                i2c_sclk <= not i2c_sclk;
            end if;
        end if;
    end process;
end architecture Behavioral;
