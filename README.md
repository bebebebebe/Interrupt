## Message formats:

### Sent by client:

connect:
{'type' => 'connect', 'name' => (String), 'time' => (timestamp String)}

chat:
{'type' => 'chat', 'body' => (String), 'time' => (timestamp String)}

quit:
{'type' => 'quit', 'time' => (timestamp String)}

exists:
{'type' => 'hi', 'time' => (timestamp String)}
- not yet implemented

### Sent by server:

{'type' => chat, 'body' => (String), 'time' => (timestamp String)}

{'type' => 'id', 'time' => (timestamp String)} 
- request connect message from client

## Behavior on wrong message types:

### Received by server:

Checks message format and sender. Ignores "wrong" messages, which are
- wrong format
- sender not in clients list, if its not a connect message
- ideally: if get correctly formatted message that is not a connect message, and the client is not in the clients list, should request new
connect message from client by sending just this client an id message.
Shouldn't add client to clients list until get a connect message with name.

###Received by client:

Checks message format and sender. Ignores "wrong" messages, which are:
- sender is not server
- format is wrong


