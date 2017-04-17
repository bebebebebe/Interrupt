# Interrupt Chat

"Realtime" interruptible chat in the terminal.

<img src='https://cloud.githubusercontent.com/assets/2926692/25077293/7aff1b68-22f6-11e7-8312-4642fd0c803e.gif' />

A command line chat program for multiple clients, where the idea is to give something like the experience of seeing a transcript of voice conversation. The text that clients see is updated with each keypress from a client. Each client is assigned a color, and their text appears in that color for all clients. Chat text appears on one line, with the cursor at the far right (representing "now"); text moves to the left as you type or as time passes. Clients can't delete or move the cursor left.

## To run
To run both the client and server on localhost, use one terminal window to run the server:

```
ruby interrupt_server.rb
```

In another terminal window, run the client:

```
ruby interrupt_client.rb
```

Run the client in a third window in the same way to chat between the two windows running the client.

To run the server and make it available on your network rather than just via the loopback interface, do

```
ruby interrupt_server.rb -network
```

This will run the server on your first private ipv4 ip address. If you want to select an ip address (to use something other than the first one), do

```
ruby interrupt_server.rb -network -select
```
This will give you a list of ip addresses to choose from.

On the command line, you'll get a message saying what ip address you're running the program on.


If you're running the client, and the server is running elsewhere at '[server-ip-address-string]', run the client with a command line argument

```
ruby interrupt_client.rb [server-ip-address-string]
```

#### Running from inside Docker

If you have docker in your system and don't have ruby and/or don't want to download it, the following line will create a docker container with ruby and the app code mounted in the /chat folder.

```
docker run -it --name Interrupt -w /chat -v $(pwd):/chat ruby:alpine /bin/sh
```

In there, running the below command will work like normal.

```
ruby interrupt_client.rb [server-ip-addres-string]
```

Once you exit the docker container, to start it up again you can run the command below and then run the ruby script from there.

```
docker start -i Interrupt
```

## Overview of how it works
Clients send messages to the server, and the server sends messages to clients. Messages are sent via UDP sockets. Both client and server programs are single threaded. The messages are string representations of formats described in [Message formats](#message-formats) below.

### Connecting
The client is prompted to supply a nickname on starting the program. Once supplied, the client sends the server a connect message with this nickname. When the server receives a connect message, the server sends the client an acknowledgement message and adds the client to the clients list. The client keeps resending the server connect messages (waiting a bit between resends) until getting an acknowledgement from the server.

### Chatting

The server stores two (main) pieces of state information: a list of clients connected, and the most recent 45 characters of chatting. The list of clients connected is a hash, with information about the 'color' (an integer) the server has assigned the client, the time of the last message received from the client, the client's user supplied nickname, and the client's address information (host and port). The data for the most recent 45 characters of chatting includes info for each character about what the character is, and the 'color' (assigned integer) of the client it came from.

When the client presses a (alphanumeric, space, or punctuation) key, the client sends a chat message to the server.

When the server receives a [chat message from a client](#sent-by-client), the server checks its timestamp and compares it to the time of the last message received from that client. If it's older than the last message received, the message is ignored. Assuming it's a new message, the server sends all clients a [chat message](#sent-by-server) with data about the nicknames of clients in the client list and who is the 'speaker', and data representing the state of the last 45 characters of chat text as described above.

When the client receives such a chat message from the server, the client checks the timestamp to make sure it's newer than the last chat message received, and if so the client overwrites the chat names list and chat text in the terminal to reflect the updated state.

### Disconnecting
When a client quits properly, that is by typing the quit command `\`, the client sends the server a quit message and the program exits. When the server receives a quit message from a client, the server removes the client from the stored clients list, and adds the 'color' (integer) associated with the client back to the list of available colors.


## Message formats

### Sent by client

connect:
`{'type' => 'connect', 'name' => (String), 'time' => (timestamp String)}`

chat:
`{'type' => 'chat', 'body' => (String), 'time' => (timestamp String)}`

quit:
`{'type' => 'quit', 'time' => (timestamp String)}`


### Sent by server

chat: `{'type' => 'chat', 'body' => (Array), 'names' => (Array) 'time' => (timestamp String)}`

Here the `body` value is an array of arrays, with one (nested) array to represent each letter in the chat string: `[[char (String, one letter), color (Integer)], ... ]`. The value of the `names` key is an array of arrays, one (nested) array for each client in the chat: `[[name (String), color (Integer), current_speaker? (Boolean)], ...]`.

ack: `{'type' => 'ack', 'time' => (timestamp String)}`


## Behavior on wrong message types

### Received by server

Checks message format and sender. Ignores "wrong" messages, which are
- wrong format: message isn't of the form described in "sent by client" message format types above, or
- sender not in clients list, unless the messege is a connect message.

### Received by client

Checks message format and sender. Ignores "wrong" messages, which are:
- wrong format: message isn't of the form described in "sent by server" message format types above, or
- sender is not server.

## Server message representations (internal to server program)
chat message: send to all clients
`{'type' => 'chat', 'msg'=> {...}}`

Private:
`{'type' => 'private', 'key' => (String) 'msg'=> {....}}`

(Private messages aren't used at present.)

Private to "new" user (not assumed to be in client list):
`{'type' => 'private_new', 'host' => (String), 'port' => (Integer), msg=>{...}}`

The values of the msg keys here are of a form in the "sent by server" section above.

## Limitations / TODO

1. [*Update*: done! The server now has a thread to keep track of when to ping clients and purge the clients list. New TODO: update readme with details on this.] The server doesn't monitor clients to see if they are still running the chat program. Currently, the server will remove clients from the list of clients to message if the client quits the program properly, i.e., by typing the quit command. However, the server won't make such an update if the client halts the chat program in another way, for instance by closing the terminal window.

2. The client doesn't get any feedback on keypress until the server knows about it and messages all clients with an update. One possiblity is to update the chat string on the client side with newly typed data in a lighter color or grey; it would be "overwritten" in the client's ususal colour once the server message comes through. [*Update*: this wasn't an issue, at least on the network here where we tested it, and keypress-to-letter feedback felt instant, so no further work was done here. It would be interesting to work on for worse networks, though.]
