# Utility for writing to terminal, mostly colors and cursor movements.

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

  def self.left(num)
		"\033[#{num}D"
  end

  def self.right(num)
		"\033[#{num}C"
  end

  def self.up(num)
		"\033[#{num}A"
  end

  def self.down(num)
		"\033[#{num}B"
  end

  # clear screen and move to top
  def self.clear()
		"\033[2J\033[0;0H"
  end
end
