require 'socket'
require 'json'

require_relative './Console'

class InterruptClient

  CMD_QUIT = "\u0003" # CTRL-C
  START_MSG = 'Welcome! What is your name?'
  INSTRUCTIONS = "Start typing to join the chat! To quit, type CTRL-C"
  NAME_FORMAT_INSTRUCTIONS = "\n For a name, use alphanumeric characters, at most 8."
  FAREWELL = "\r\nbye"
  PROMPT = '> '

  MAX_MSG_LENGTH = 3000 # max length of incoming message read
  HANDSHAKE_WAIT = 2 # number of seconds to wait for ack from server before resending
  TEXT_LINE = 12 # what line to print chat text on in terminal

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
    @term_width ||= Console.term_width

    terminate_handle
  end

  def terminate_handle
    Signal.trap('TERM') do
      bye
    end
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
    input = STDIN.gets.chomp
    if input.length > 8 || /\W/.match(input)
      puts NAME_FORMAT_INSTRUCTIONS
      set_name
    else
      @name = input
    end
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
    Console.clear
    puts INSTRUCTIONS
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
      names_string, names_length = names_data(names_array)

      indent = chat_array.length > @term_width ? 1 : (@term_width - chat_array.length) / 2

      Console.cursor_pos(2, 3)
      print names_string
      Console.cursor_pos(TEXT_LINE, indent)
      print chat_string(chat_array)
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
    names_length = 0 # names_string may have color encoding chars, so we can't just check its length

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
  def handle_key(input)
    if input == CMD_QUIT
      bye
    elsif not /^[[[:word:]][[:punct:]] ]$/.match(input).nil?
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
      msg if (msg.has_key?('body') && msg.has_key?('names'))
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
    Console.no_echo
  end

  def terminal_reset
    Console.sane
  end

  def bye
    terminal_reset
    send_msg(msg_quit)
    puts FAREWELL
    exit
  end

end

SERVER_HOST = '127.0.0.1'
SERVER_PORT = 4481

if ARGV.length > 1
  puts 'Run with 0 or 1 argument. If 1, use the server host address as a string.'
  exit
end

host = (ARGV.length == 1 && ARGV[0]) || SERVER_HOST

client = InterruptClient.new(host, SERVER_PORT)
client.run
