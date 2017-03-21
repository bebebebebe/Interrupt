# Utility for writing to terminal, mostly colors and cursor movements.

require 'io/console'

module Console
  def self.color(color, text)
    return text if color.nil?
    self.public_send(color, text)
  end

  def self.red(text)
    color_encode(text, 31)
  end

  def self.green(text)
    color_encode(text, 32)
  end

  def self.blue(text)
    color_encode(text, 34)
  end

  def self.cyan(text)
    color_encode(text, 36)
  end

  def self.magenta(text)
    color_encode(text, 35)
  end

  def self.light_green(text)
    color_encode(text, 92)
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
