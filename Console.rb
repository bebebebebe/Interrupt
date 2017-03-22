# Utility for writing to terminal, mostly colors and cursor movements.

require 'io/console'

module Console

  COLOR_CODE_MAP = {
    'red' => 31,
    'green' => 32,
    'blue' => 34,
    'cyan' => 36,
    'magenta' => 35,
    'light_green' => 92
  }

  def self.color(color, text)
    return text if (color.nil? || !COLOR_CODE_MAP.has_key?(color))

    self.color_encode(text, COLOR_CODE_MAP[color])
  end

  def self.color_encode(text, code)
    "\e[#{code}m#{text}\e[0m"
  end

  def self.emph(text) # bold underline
    "\e[1m\e[4m#{text}"
  end

  def self.cursor_pos(row, col)
    system("tput cup #{row} #{col}")
  end

  def self.term_width
    height, width = STDIN.winsize
    return width
  end

  def self.clear()
    system('clear')
  end

  def self.no_echo
    system('stty raw -echo')
  end

  def self.sane
    system('stty -raw echo')
  end

end
