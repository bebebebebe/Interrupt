# Utility for writing to terminal, mostly colors and cursor movements.

require 'io/console'

module Console

  COLOR_CODE_MAP = {
    'red' => 31,
    'green' => 32,
    'blue' => 34,
    'cyan' => 36,
    'magenta' => 35,
    'light_green' => 92,
    'yellow' => 33,
    'light_red' => 91,
    'light_blue' => 94,
    'light_cyan' => 96,
    'light_magenta' => 95,
    'light_gray' => 37
  }

  def self.color(color, text)
    return text if (color.nil? || !COLOR_CODE_MAP.has_key?(color))

    self.color_encode(text, COLOR_CODE_MAP[color])
  end

  def self.color_encode(text, code)
    "\e[#{code}m#{text}\e[0m"
  end

  def self.emph(text) # bold underline
    "\e[1m\e[4m#{text}\e[0m"
  end

  def self.term_width
    height, width = STDIN.winsize
    return width
  end

  def self.print_line(len)
    line = "\u2504" * len
    print line.encode('utf-8')
  end

  def self.cursor_pos(row, col)
    system("tput cup #{row} #{col}")
  end

  def self.clear
    system('clear')
  end

  def self.clear_el # clear to end of line
    system('tput el')
  end

  def self.cursor_hide
    system('tput civis')
  end

  def self.cursor_show
    system('tput cnorm')
  end

  def self.no_echo
    system('stty raw -echo')
  end

  def self.sane
    system('stty -raw echo')
  end

end
