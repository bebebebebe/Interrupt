require 'socket'
require 'json'

class InterruptClient

	START_MSG = 'Welcome! What is your name?'
	PROMPT = '> '
	MAX_MSG_LENGTH = 3000 # max length of incoming message read
	HANDSHAKE_WAIT = 2 # number of seconds to wait for ack from server before resending
	CMD_QUIT = "\\"
	INSTRUCTIONS = "Start typing to join the chat! To quit anytime, type #{CMD_QUIT}"

	COLORS = [
		'green',
		'magenta',
		'cyan',
		'blue',
		'light_green',
	]

	def initialize(server_host, server_port)
		@server_host = server_host
		@server_port = server_port

		@client = UDPSocket.new
		@client.connect(@server_host, @server_port)

		@latest_chat = '' # string timestamp of latest chat received
	end

	def run
		set_name
		handshake
		instructions
		terminal_config
		receive_loop
	end

	def set_name
		puts START_MSG
		print PROMPT
		@name = gets.chomp
	end

	def handshake
		ackd = false
		while not ackd
			send_msg(msg_connect(@name))
			incoming = IO.select([@client], nil, nil, HANDSHAKE_WAIT)
			if ((not incoming.nil?) && ack?)
				ackd = true
			end
		end
	end

	def ack?
		data, sender = @client.recvfrom(MAX_MSG_LENGTH)
		msg = parse_msg(data, sender)
		return false if msg.nil?

		msg['type'] == 'ack'
	end

	def instructions
		print Console.clear

		puts INSTRUCTIONS + "\n" * 12
	end

	def receive_loop
		loop do
			to_read = IO.select([@client, STDIN]) # check what's ready to read: socket, or terminal input
			to_read[0].each { |ios|
				if ios == @client
					msg, sender = ios.recvfrom(MAX_MSG_LENGTH)
					handle_msg(msg, sender)
				elsif ios.tty? # ios comes from terminal
					input = STDIN.getc
					handle_key(input)
				end
			}
		end
	end

	def handle_msg(msg, sender)
		msg = parse_msg(msg, sender)
		return if msg.nil?

		case msg['type']
		when 'chat'
			time = msg['time']
			return if time < @latest_chat

			@latest_chat = time
			chat_array = msg['body']
			names_array = msg['names']

			chat_string = chat_string(chat_array)
			names_string, names_length = names_data(names_array)

			string = Console.left(chat_array.length) + Console.up(10) +
					names_string +
					Console.left(names_length) + Console.down(10) +
					chat_string

			print string
		end
	end

	def chat_string(chat_array)
		chat_array.inject('') { |string, item|
				text, color_code = item
				color = color_code.nil? ? nil : COLORS[color_code]

				string + Console.color(color, text)
			}
	end

	def names_data(names_array)
		names_string = ''
		names_length = 0

		names_array.each {|item|
			nickname, color_code, emph = item
			names_length += nickname.length + 2

			nickname = color_code.nil? ? nickname : Console.color(COLORS[color_code], nickname)
			nickname = emph ? Console.emph(nickname) : nickname
			names_string += " #{nickname} "
			}

		return [names_string, names_length]
	end

	# disregard eg return, delete, backspace keys presses
	# only pass on to server word, punctuation, or space characters
	# TODO: strip out two chars following '\e'
	def handle_key(input)
		if input == CMD_QUIT
			bye
		elsif	not /^[[[:word:]][[:punct:]] ]$/.match(input).nil?
			send_msg(msg_chat(input))
		end
	end

	# return parsed msg if correct format and comes from Interrupt server
	# return nil otherwise
	def parse_msg(data, sender)
		return nil if not is_server?(sender)

		begin
			msg = JSON.parse(data)
			msg = check_fields(msg)
		rescue
			nil
		end
	end

	def is_server?(sender)
		port = sender[1]
		host = sender[2]

		(port == @server_port) && (host == @server_host)
	end

	# return nil if fields wrong, otherwise return msg
	def check_fields(msg)
		basic_fields = (msg.has_key?('type') && msg.has_key?('time'))
		return nil if not basic_fields

		case msg['type']
		when 'chat'
			msg if msg.has_key?('body')
		when 'ack'
			msg
		else
			nil
		end
	end


	def send_msg(msg)
		msg['time'] = Time.now.to_f.to_s
		json = msg.to_json
		@client.send(json, 0)
	end

	def msg_chat(body)
		{'type' => 'chat', 'body' => body}
	end

	def msg_connect(nick)
		{'type' => 'connect', 'name' => nick}
	end

	def msg_quit
		{'type' => 'quit'}
	end
	
	def terminal_config
		system("stty raw -echo")
	end

	def terminal_reset
		system("stty -raw echo")
	end

	def bye
		terminal_reset
		send_msg(msg_quit)
		puts "\n\rbye"
		exit
	end

end

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


SERVER_HOST = '127.0.0.1'
SERVER_PORT = 4481

client = InterruptClient.new(SERVER_HOST, SERVER_PORT)
client.run
