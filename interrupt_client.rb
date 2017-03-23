require 'socket'
require 'json'

require_relative './console'

class InterruptClient

  CMD_QUIT                      = "\u0003" # CTRL-C
  START_MSG                     = 'Welcome! What is your name?'
  INSTRUCTIONS                  = "Start typing to join the chat! To quit, type CTRL-C"
  NAME_FORMAT_INSTRUCTIONS      = "\n For a name, use alphanumeric characters, at most 8."
  FAREWELL                      = "\r\nbye"
  CONNECT_REFUSED_MSG           = "Connection to server refused."
  PROMPT                        = '> '

  MAX_MSG_LENGTH                = 3000 # max length of incoming message read
  HANDSHAKE_WAIT                = 2 # number of seconds to wait for ack from server before resending
  TEXT_LINE                     = 10 # what line to print chat text on in terminal

  COLORS = %w(green magenta cyan blue light_green)

  def initialize(server_host, server_port)
    @server_host = server_host
    @server_port = server_port

    @client = UDPSocket.new
    @client.connect(@server_host, @server_port)

    @latest_chat = '' # string timestamp of latest chat received
    @term_width ||= Console.term_width

    terminate_handle
  end

  def call
    set_name
    handshake_loop
    instructions
    terminal_config
    receive_loop
  end

  private

  def terminate_handle
    Signal.trap('TERM') do
      bye
    end
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

  def handshake_loop
    loop do
      send_msg(msg_connect(@name))
      incoming = IO.select([@client], nil, nil, HANDSHAKE_WAIT)
      break if (incoming && ack?)
    end
  end

  def ack?
    begin
      data, sender = @client.recvfrom(MAX_MSG_LENGTH)
    rescue Errno::ECONNREFUSED
      bye(CONNECT_REFUSED_MSG)
    end
    msg = parse_msg(data, sender)
    return false if msg.nil?

    msg['type'] == 'ack'
  end

  def instructions
    Console.clear
    puts INSTRUCTIONS
    draw_line
  end

  def receive_loop
    loop do
      readables, _, _ = IO.select([@client, STDIN])
      readables.each { |ios|
        if ios == @client
          begin
            msg, sender = ios.recvfrom(MAX_MSG_LENGTH)
            handle_msg(msg, sender)
          rescue Errno::ECONNREFUSED
            bye(CONNECT_REFUSED_MSG)
          end
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
      #indent = chat_array.length > @term_width ? 1 : (@term_width - chat_array.length) / 2
      indent = 2

      Console.cursor_hide
      Console.cursor_pos(2, 3)
      print names_string
      Console.clear_el
      Console.cursor_pos(TEXT_LINE, indent)
      print chat_string(chat_array)
      Console.cursor_show
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
    max_length = @term_width * (TEXT_LINE - 3) # may truncate names (unlikely)

    names_array.each {|item|
      nickname, color_code, emph = item
      names_length += nickname.length + 2
      break if names_length > max_length

      nickname = color_code.nil? ? nickname : Console.color(COLORS[color_code], nickname)
      nickname = emph ? Console.emph(nickname) : nickname
      names_string += " #{nickname} "
      }

    return [names_string, names_length]
  end

  # TODO: get chat length from server with ack message.
  # Temporarily hardcoded, assuming length is 40.
  def draw_line
    Console.cursor_pos(TEXT_LINE + 1, 2)
    Console.print_line(41)
    Console.cursor_pos(TEXT_LINE, 42)
  end

  # disregard eg return, delete, backspace keys presses
  # only pass on to server word, punctuation, or space characters
  def handle_key(input)
    if input == CMD_QUIT
      bye
    elsif /^[[[:word:]][[:punct:]] ]$/.match(input)
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
    _, port, host = sender

    (port == @server_port) && (host == @server_host)
  end

  # return nil if fields wrong, otherwise return msg
  def check_fields(msg)
    basic_fields = (msg.has_key?('type') && msg.has_key?('time'))
    return nil if not basic_fields

    case msg['type']
    when 'chat'
      (msg.has_key?('body') && msg.has_key?('names')) ? msg : nil
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

  def bye(msg=nil)
    terminal_reset
    send_msg(msg_quit)
    puts FAREWELL
    puts msg if msg
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
client.()
