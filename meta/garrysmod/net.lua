---@meta garrysmod.net


--- [SHARED]
---
--- The net library is one of a number of ways to send data between the client and server.
---
--- > NOTE: The major advantages of the net library are the large size limit (64kb/message) and the ability to send data backwards - from the client to the server.
---
---@class garrysmod.net
net = {}

--- [SHARED]
---
--- Cancels a net message started by `net.Start`, so you can immediately start a new one without any errors.
---
---@see net.Start
---
function net.Abort() end

--- [SERVER]
---
--- Sends the currently built net message (see `net.Start`) to all connected players.
---
--- > **NOTE**: This is equivalent to `net.Send(player.GetAll())`
---
function net.Broadcast() end

--- [SHARED]
---
--- Returns the amount of data left to read in the current message. Does nothing when sending data.
---
---@return integer byte_count The amount of data left to read in the current net message in **bytes** or `nil` if no net message has been started.
---@return integer bit_count The amount of data left to read in the current net message in **bits** or `nil` if no net message has been started.
function net.BytesLeft() end

--- [SHARED]
---
--- Returns the size of the current message.
---
--- > **NOTE**: This will include 3 extra bytes (24 bits) used by the engine internally to send the data over the network.
---
---@return integer byte_count The amount of **bytes** written to the current net message or `nil` if no net message has been started.
---@return integer bit_count The amount of **bits** written to the current net message or `nil` if no net message has been started.
function net.BytesWritten() end

--- [SHARED]
---
--- Function called by the engine to tell the Lua state a message arrived.
---
---@param length integer The message length, in **bits**.
---@param client garrysmod.Player The player that sent the message. This will be `nil` in the client state.
function net.Incoming( length, client ) end

--- [SHARED]
---
--- Reads an angle from the received net message.
---
---@return garrysmod.Angle ang3 The read angle, or `Angle( 0, 0, 0 )` if no angle could be read
function net.ReadAngle() end

--- [SHARED]
---
--- Reads a bit from the received net message.
---
---@return 0 | 1 bit_value `0` or `1`, or `0` if the bit could not be read.
function net.ReadBit() end

--- [SHARED]
---
--- Reads pure binary data from the message.
---
---@param length integer The length of the data to be read, in **bytes**.
---@return string data The binary data read, or a string containing one character with a byte of `0` if no data could be read.
function net.ReadData( length ) end

--- [SHARED]
---
--- Reads a double-precision number from the received net message.
---
---@return number float64 The double-precision number, or `0` if no number could be read.
function net.ReadDouble() end

--- [SHARED]
---
--- Reads a floating point number from the received net message.
---
---@return number float32 The floating point number, or `0` if no number could be read.
function net.ReadFloat() end

--- [SHARED]
---
--- Reads a word, basically unsigned short.
---
--- This is used internally to read the "header" of the message
--- which is an unsigned short which can be converted to
--- the corresponding message name via `util.NetworkIDToString`.
---
---@see util.NetworkIDToString
---
---@return integer id The header number
function net.ReadHeader() end

--- [SHARED]
---
--- Reads an integer from the received net message.
---
---@param bit_count integer The amount of bits to be read.
---@return integer int The read integer number, or `0` if no integer could be read.
function net.ReadInt( bit_count ) end

--- [SHARED]
---
--- Reads a `VMatrix` from the received net message.
---
---@return garrysmod.VMatrix vmatrix The matrix, or an empty matrix if no matrix could be read.
function net.ReadMatrix() end

--- [SHARED]
---
--- Reads a normal vector from the net message.
---
---@return garrysmod.Vector vec3 The normalized vector ( length = `1` ), or `Vector( 0, 0, 1 )` if no normal could be read.
function net.ReadNormal() end

--- [SHARED]
---
--- Reads a `null-terminated string` from the net stream.
---
--- The size of the string is 8 bits plus 8 bits for every ASCII character in the string.
---
---@return string str The read string, or emtpy string if no data to read.
function net.ReadString() end

--- [SHARED]
---
--- Reads an unsigned integer with the specified number of bits from the received net message.
---
---@param bit_count integer The size of the integer to be read, in bits.
---@return integer uint The unsigned integer read, or `0` if the integer could not be read.
function net.ReadUInt( bit_count ) end

--- [SHARED]
---
--- Reads a unsigned integer with 64 bits from the received net message.
---
---@return string uint64_str The uint64 number. Since Lua cannot store full 64-bit integers, this function returns a string. It is mainly aimed at usage with `Player:SteamID64`.
function net.ReadUInt64() end

--- [SHARED]
---
--- Reads a vector from the received net message. Vectors sent by this function are **compressed**, which may result in precision loss. See `net.WriteVector` for more information.
---
---@return garrysmod.Vector vec3 The read vector, or `Vector( 0, 0, 0 )` if no vector could be read.
function net.ReadVector() end

--- [SHARED]
---
--- Adds a net message handler. Only one receiver can be used to receive the net message.
---
--- You can use the `net.Read*` functions within the message handler callback.
---
--- **WARNING**: You **should** put this function **outside** of any other function or hook for it to work properly unless you know what you are doing!
---
--- You **must** read information in the same order as you write it.
---
--- Each net message has a length limit of **64KB**!
---
---@param messageName string The message name to hook to.
---@param callback fun( bit_count: integer, sender: ( garrysmod.Player | nil ) ) The function to be called if the specified message was received.
function net.Receive( messageName, callback ) end

--- [SERVER]
---
--- Sends the current net message to the specified player(s). It is then received via `net.Receive` on the client realm of each of those players.
---
---@param pl garrysmod.Player The player to send the message to.
function net.Send( pl ) end

--- [SERVER]
---
--- Sends the current net message to the specified player(s). It is then received via `net.Receive` on the client realm of each of those players.
---
---@param plys garrysmod.Player[] A table of players to send the message to.
function net.Send( plys ) end

--- [SERVER]
---
--- Sends the current net message to the specified player(s). It is then received via `net.Receive` on the client realm of each of those players.
---
---@param filter garrysmod.RecipientFilter A recipient filter specifying message targets.
function net.Send( filter ) end

--- [SERVER]
---
--- Sends the current message (see `net.Start`) to all except the player or players specified.
---
---@param pl garrysmod.Player The player to **NOT** send the message to.
function net.SendOmit( pl ) end

--- [SERVER]
---
--- Sends the current message (see `net.Start`) to all except the player or players specified.
---
---@param plys garrysmod.Player[] A table of players to **NOT** send the message to.
function net.SendOmit( plys ) end

--- [SERVER]
---
--- Sends current net message (see `net.Start`) to all players that are in the same `Potentially Audible Set (PAS)` as the position, or simply said, it adds all players that can potentially hear sounds from this position.
---
---@param position garrysmod.Vector PAS position.
function net.SendPAS( position ) end

--- [SERVER]
---
--- Sends current net message (see `net.Start`) to all players in the `PVS (Potential Visibility Set)` of the position, or, more simply said, sends the message to players that can potentially see this position.
---
---@param position garrysmod.Vector Position that must be in players' visibility set.
function net.SendPVS( position ) end

--- [CLIENT]
---
--- Sends the current net message (see `net.Start`) to the server. The player object must exist on the server for the net message to be received successfully by the server.
---
--- **WARNING**: Each net message has a length limit of 65,533 bytes (approximately 64 KiB) and your net message will error and fail to send if it is larger than this.
---
--- The message name must be pooled with `util.AddNetworkString` beforehand!
---
function net.SendToServer() end

--- [SHARED]
---
--- Begins a new net message. If another net message is already started and hasn't been sent yet, it will be discarded.
---
--- After calling this function, you will want to call `net.Write` functions to write your data, if any, and then finish with a call to one of the following functions:
--- * `net.Send`
--- * `net.SendOmit`
--- * `net.SendPAS`
--- * `net.SendPVS`
--- * `net.Broadcast`
--- * `net.SendToServer`
---
--- **WARNING**: Each net message has a length limit of 65,533 bytes (approximately 64 KiB) and your net message will error and fail to send if it is larger than this.
---
--- The net library has an internal buffer that sent messages are added to that is capable of holding roughly 256 kb at a time. Trying to send more will lead to the client being kicked because of a buffer overflow. `More information on net library limits can be found here.`
---
--- The message name must be pooled with `util.AddNetworkString` beforehand!
---
--- Net messages will not reliably reach the client until the client's `GM:InitPostEntity` hook is called.
---
---@param messageName string The name of the message to send
---@param unreliable? boolean If set to `true`, the message is not guaranteed to reach its destination
---@return boolean success `true` if the message has been started.
function net.Start( messageName, unreliable ) end

--- [SHARED]
---
--- Writes an angle to the current net message.
---
---@param angle garrysmod.Angle The angle to be sent.
function net.WriteAngle( angle ) end

--- [SHARED]
---
--- Appends a boolean (as `1` or `0`) to the current net message.
---
--- Please note that the bit is written here from a `boolean` (`true/false`) but `net.ReadBit` returns a number.
---
---@param boolean boolean Bit status (false = `0`, true = `1`).
function net.WriteBit( boolean ) end

--- [SHARED]
---
--- Appends a boolean to the current net message. Alias of `net.WriteBit`.
---
---@param boolean boolean Boolean value to write.
function net.WriteBool( boolean ) end

--- [SHARED]
---
--- Writes a chunk of binary data to the message.
---
---@param binaryData string The binary data to be sent.
---@param length? integer The length of the binary data to be sent, in bytes.
function net.WriteData( binaryData, length ) end

--- [SHARED]
---
--- Appends a double-precision number to the current net message.
---
---@param double number The double to be sent
function net.WriteDouble( double ) end

--- [SHARED]
---
--- Appends a float (number with decimals) to the current net message.
---
---@param float number The float to be sent.
function net.WriteFloat( float ) end

--- [SHARED]
---
--- Appends a signed integer - a whole number, positive/negative - to the current net message. Can be read back with `net.ReadInt` on the receiving end.
---
--- Use `net.WriteUInt` to send an unsigned number (that you know will **never** be negative). Use `net.WriteFloat` for a non-whole number (e.g. `2.25`).
---
---@param int integer The integer to be sent.
---@param bit_count integer The amount of bits the number consists of. This must be **32** or less.
function net.WriteInt( int, bit_count ) end

--- [SHARED]
---
--- Writes a `VMatrix` to the current net message.
---
---@param matrix garrysmod.VMatrix The matrix to be sent.
function net.WriteMatrix( matrix ) end

--- [SHARED]
---
--- Writes a normalized/direction vector ( Vector with length of 1 ) to the net message.
---
--- This function uses less bandwidth compared to `net.WriteVector` and will not send vectors with length of > 1 properly.
---
---@param normal garrysmod.Vector The normalized/direction vector to be send.
function net.WriteNormal( normal ) end

--- [SHARED]
---
--- Appends a string to the current net message.
---
--- The size of the written data is 8 bits
--- for every ASCII character in the string `+ 8`
--- bits for the null terminator.
---
---@see net.WriteData
---
---@param string string The string to be sent, that will be terminated with null byte.
function net.WriteString( string ) end

--- [SHARED]
---
--- Appends an unsigned integer with the specified number of bits to the current net message.
---
--- Use `net.WriteInt` if you want to send negative and positive numbers. Use `net.WriteFloat` for a non-whole number (e.g. `2.25`).
---
--- > **NOTE**: Unsigned numbers **do not** support negative numbers.
---
---@param uint integer The unsigned integer to be sent.
---@param bit_count integer The size of the integer to be sent, in bits.
function net.WriteUInt( uint, bit_count ) end

--- [SHARED]
---
--- Appends an unsigned integer with 64 bits to the current net message.
---
---@param uint64 string | integer The 64 bit value to be sent.
function net.WriteUInt64( uint64 ) end

--- [SHARED]
---
--- Appends a vector to the current net message.
---
--- Vectors sent by this function are compressed,
--- which may result in precision loss.
---
--- XYZ components greater than `16384` or less than `-16384`
--- are irrecoverably altered (most significant bits are trimmed)
--- and precision after the decimal point is 1 digit (5 bits).
---
---@param vector garrysmod.Vector The vector to be sent.
function net.WriteVector( vector ) end
