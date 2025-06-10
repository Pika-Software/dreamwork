local std = _G.gpm.std

local string = std.string

local string_byte, string_char = string.byte, string.char
local string_sub, string_rep = string.sub, string.rep
local string_len = string.len

local math = std.math
local math_ceil = math.ceil

---@class gpm.std.crypto
local crypto = std.crypto

local bytepack = crypto.bytepack

local bytepack_readUInt16, bytepack_writeUInt16 = bytepack.readUInt16, bytepack.writeUInt16
local bytepack_readUInt24, bytepack_writeUInt24 = bytepack.readUInt24, bytepack.writeUInt24
local bytepack_readUInt32, bytepack_writeUInt32 = bytepack.readUInt32, bytepack.writeUInt32
local bytepack_readUInt40, bytepack_writeUInt40 = bytepack.readUInt40, bytepack.writeUInt40
local bytepack_readUInt48, bytepack_writeUInt48 = bytepack.readUInt48, bytepack.writeUInt48
local bytepack_readUInt56, bytepack_writeUInt56 = bytepack.readUInt56, bytepack.writeUInt56
local bytepack_readUInt64, bytepack_writeUInt64 = bytepack.readUInt64, bytepack.writeUInt64

local bytepack_readInt8, bytepack_writeInt8 = bytepack.readInt8, bytepack.writeInt8
local bytepack_readInt16, bytepack_writeInt16 = bytepack.readInt16, bytepack.writeInt16
local bytepack_readInt24, bytepack_writeInt24 = bytepack.readInt24, bytepack.writeInt24
local bytepack_readInt32, bytepack_writeInt32 = bytepack.readInt32, bytepack.writeInt32
local bytepack_readInt40, bytepack_writeInt40 = bytepack.readInt40, bytepack.writeInt40
local bytepack_readInt48, bytepack_writeInt48 = bytepack.readInt48, bytepack.writeInt48
local bytepack_readInt56, bytepack_writeInt56 = bytepack.readInt56, bytepack.writeInt56
local bytepack_readInt64, bytepack_writeInt64 = bytepack.readInt64, bytepack.writeInt64

--- [SHARED AND MENU]
---
--- The binary pack/unpack library.
---
---@class gpm.std.crypto.pack
local pack = crypto.pack or {}
crypto.pack = pack

--- [SHARED AND MENU]
---
--- The binary reader object.
---
---@class gpm.std.crypto.pack.Reader : gpm.std.Object
---@field __class gpm.std.crypto.pack.ReaderClass
---@field protected position integer The current position of the reader in bytes. **READ-ONLY**
---@field protected data_length integer The size of the reader in bytes. **READ-ONLY**
---@field protected data string The content of the reader. **READ-ONLY**
local Reader = std.class.base( "crypto.pack.Reader" )

---@protected
function Reader:__tostring()
	return string.format( "crypto.pack.Reader: %p [%d/%d bytes]", self, self.position, self.data_length )
end

---@protected
function Reader:__init()
	self.data_length = 0
	self.position = 0
end

--- [SHARED AND MENU]
---
--- Opens the reader.
---
---@param data string The content to read.
---@return boolean success `true` on success, `false` on failure.
function Reader:open( data )
	self.data_length = string_len( data )
	self.position = 0
	self.data = data
	return true
end

--- [SHARED AND MENU]
---
--- Closes the reader.
---
function Reader:close()
	self.data_length = 0
	self.position = 0
	self.data = nil
end

--- [SHARED AND MENU]
---
--- Returns the current position of the reader.
---
---@return integer position
function Reader:tell()
	return self.position
end

--- [SHARED AND MENU]
---
--- Returns the size of the reader content in bytes.
---
---@return integer size
function Reader:size()
	return self.data_length
end

do

	local math_min = math.min

	--- [SHARED AND MENU]
	---
	--- Sets the current position of the reader.
	---
	---@param new_position integer
	function Reader:seek( new_position )
		local data_length = self.data_length

		while new_position < 0 do
			new_position = new_position + data_length + 1
		end

		self.position = math_min( new_position, data_length )
	end

end

--- [SHARED AND MENU]
---
--- Skips the reader position by the specified offset.
---
---@param offset integer
function Reader:skip( offset )
	self:seek( self.position + offset )
end

--- [SHARED AND MENU]
---
--- Reads the specified number of bytes from the reader.
---
---@param length? integer
---@return string | nil binary_str
---@return nil | string error
function Reader:read( length )
	if length == 0 then
		return "", nil
	end

	local position, data_length = self.position, self.data_length


	local available = data_length - position
	if available <= 0 then
		return nil, "end of file"
	end

	if length == nil then
		length = available
	elseif length > available then
		return nil, "not enough data"
	end

	while length < 0 do
		length = length + available + 1
	end

	if length == data_length then
		self.position = data_length
		return self.data, nil
	else
		self.position = position + length
		return string_sub( self.data, position + 1, position + length ), nil
	end
end

--- [SHARED AND MENU]
---
--- The binary reader class.
---
---@class gpm.std.crypto.pack.ReaderClass : gpm.std.crypto.pack.Reader
---@field __base gpm.std.crypto.pack.Reader
---@overload fun(): gpm.std.crypto.pack.Reader
local ReaderClass = std.class.create( Reader )
pack.Reader = ReaderClass

--- [SHARED AND MENU]
---
--- The binary writer object.
---
---@class gpm.std.crypto.pack.Writer : gpm.std.Object
---@field __class gpm.std.crypto.pack.WriterClass
---@field protected position integer The current position of the reader in bytes. **READ-ONLY**
---@field protected data_length integer The size of the reader in bytes. **READ-ONLY**
---@field protected data string The content of the reader. **READ-ONLY**
local Writer = std.class.base( "crypto.pack.Writer" )

---@protected
---@return string
function Writer:__tostring()
	return string.format( "crypto.pack.Writer: %p [%d/%d bytes]", self, self.position, self:size() )
end

---@protected
function Writer:__init()
	self.position = 0
end

--- [SHARED AND MENU]
---
--- Opens the writer.
---
---@param data? string The content to read.
---@return boolean success `true` on success, `false` on failure.
function Writer:open( data )
	local data_length

	if data == nil then
		data_length = 0
		data = ""
	else
		data_length = string_len( data )
	end

	self.position = data_length
	self.sub_data = data
	self.data = data

	self.buffer_size = 0
	self.buffer = {}

	return true
end

--- [SHARED AND MENU]
---
--- Closes the writer.
---
function Writer:close()
	self.buffer_size = 0
	self.buffer = nil
	self.position = 0
	self.data = nil
	self.sub_data = nil
end

--- [SHARED AND MENU]
---
--- Returns the current position of the writer.
---
---@return integer position
function Writer:tell()
	return self.position
end

--- [SHARED AND MENU]
---
--- Returns the size of the writer data in bytes.
---
---@return integer size
function Writer:size()
	local sub_data = self.sub_data
	if sub_data == nil then
		return 0
	else
		return string_len( sub_data )
	end
end

do

	local table_concat = std.table.concat

	--- [SHARED AND MENU]
	---
	--- Flushes the writer buffer.
	---
	---@return string data
	function Writer:flush()
		local buffer_size, sub_data = self.buffer_size, self.sub_data

		if buffer_size == 0 then
			local position, sub_data_length = self.position, string_len( sub_data )
			if position > sub_data_length then
				local new_sub_data = sub_data .. string_rep( "\0", position - sub_data_length )
				self.sub_data = new_sub_data
				return new_sub_data
			else
				return sub_data
			end
		end

		local position, sub_data_length = self.position, string_len( sub_data )
		if position > sub_data_length then
			sub_data, sub_data_length = sub_data .. string_rep( "\0", position - sub_data_length ), position
		end

		self.buffer_size = 0

		local buffer_str = table_concat( self.buffer, "", 1, buffer_size )
		self.buffer = {}

		local buffer_str_length = string_len( buffer_str )
		self.position = position + buffer_str_length

		local new_sub_data = string_sub( sub_data, 1, position ) .. buffer_str .. string_sub( sub_data, position + buffer_str_length + 1, sub_data_length )
		self.sub_data = new_sub_data

		return new_sub_data
	end

end

--- [SHARED AND MENU]
---
--- Commits the writer buffer.
---
---@return string data
function Writer:commit()
	local new_data = self:flush()
	self.data = new_data
	return new_data
end

--- [SHARED AND MENU]
---
--- Clears the writer buffer.
---
function Writer:clear()
	self.buffer_size = 0
	self.buffer = {}
end

--- [SHARED AND MENU]
---
--- Roll back the writer buffer.
---
---@return string data
function Writer:rollback()
	self:clear()

	local data = self.data
	self.sub_data = data
	self.position = string_len( data )
	return data
end

--- [SHARED AND MENU]
---
--- Writes the specified data to the writer.
---
---@param data string
function Writer:write( data )
	local next_buffer_size = self.buffer_size + 1
	self.buffer[ next_buffer_size ] = data
	self.buffer_size = next_buffer_size
end

--- [SHARED AND MENU]
---
--- Sets the current position of the writer.
---
---@param position integer
function Writer:seek( position )
	self:flush()

	local sub_data_length = string_len( self.sub_data )

	while position < 0 do
		position = position + sub_data_length + 1
	end

	self.position = position
end

do

	local math_max = math.max

	--- [SHARED AND MENU]
	---
	--- Skips the writer position by the specified offset.
	---
	---@param offset integer
	function Writer:skip( offset )
		self:flush()
		self.position = math_max( 0, self.position + offset )
	end

end

--- [SHARED AND MENU]
---
--- The binary writer class.
---
---@class gpm.std.crypto.pack.WriterClass : gpm.std.crypto.pack.Writer
---@field __base gpm.std.crypto.pack.Writer
---@overload fun(): gpm.std.crypto.pack.Writer
local WriterClass = std.class.create( Writer )
pack.Writer = WriterClass

--- [SHARED AND MENU]
---
--- Reads unsigned 1-byte (8 bit) integer from binary string.
---
--- Range of values: `0` - `255`
---
---@param binary_str string The binary string.
---@param start_position? integer The start position in binary string, default is `1`.
---@return integer | nil value The unsigned 1-byte integer.
---@return nil | string err_msg The error message.
function pack.readUInt8( binary_str, start_position )
	local uint8 = string_byte( binary_str, start_position or 1 )
	if uint8 == nil then
		return nil, "not enough data"
	else
		return uint8, nil
	end
end

--- [SHARED AND MENU]
---
--- Reads unsigned 1-byte (8 bit) integer.
---
--- Range of values: `0` - `255`
---
---@return integer | nil value The unsigned 1-byte integer.
---@return nil | string err_msg The error message.
function Reader:readU8()
	local start_position = self.position

	local available = self.data_length - start_position
	if available <= 0 then
		return nil, "end of file"
	elseif available < 1 then
		return nil, "not enough data"
	end

	start_position = start_position + 1
	self.position = start_position

	return string_byte( self.data, start_position ), nil
end

do

	--- [SHARED AND MENU]
	---
	--- Writes unsigned 1-byte (8 bit) integer as binary string.
	---
	--- Range of values: `0` - `255`
	---
	---@param value integer The unsigned 1-byte integer.
	---@return string | nil binary_str The binary string.
	---@return nil | string err_msg The error message.
	local function pack_writeUInt8( value )
		if value < 0 or value > 255 then
			return nil, "UInt8 value out of range"
		else
			return string_char( value ), nil
		end
	end

	pack.writeUInt8 = pack_writeUInt8

	--- [SHARED AND MENU]
	---
	--- Writes unsigned 1-byte (8 bit) integer.
	---
	--- Range of values: `0` - `255`
	---
	---@param value integer The unsigned 1-byte integer.
	function Writer:writeU8( value )
		local binary_str, err_msg = pack_writeUInt8( value )
		if binary_str == nil then
			error( err_msg, 2 )
		else
			self:write( binary_str )
		end
	end

end

--- [SHARED AND MENU]
---
--- Reads unsigned 2-byte (16 bit) integer from binary string.
---
--- Range of values: `0` - `65535`
---
---@param binary_str string The binary string.
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@param start_position? integer The start position in binary string, default is `1`.
---@return integer | nil value The unsigned 2-byte integer.
---@return nil | string err_msg The error message.
function pack.readUInt16( binary_str, big_endian, start_position )
	if start_position == nil then
		start_position = 1
	end

	local b1, b2 = string_byte( binary_str, start_position, start_position + 1 )

	if b2 == nil then
		return nil, "not enough data"
	end

	if not big_endian then
		b1, b2 = b2, b1
	end

	return bytepack_readUInt16( b1, b2 )
end

--- [SHARED AND MENU]
---
--- Reads unsigned 2-byte (16 bit) integer.
---
--- Range of values: `0` - `65535`
---
---@return integer | nil value The unsigned 2-byte integer.
---@return nil | string err_msg The error message.
function Reader:readU16( big_endian )
	local start_position = self.position

	local available = self.data_length - start_position
	if available <= 0 then
		return nil, "end of file"
	elseif available < 2 then
		return nil, "not enough data"
	end

	start_position = start_position + 1

	local end_position = start_position + 1
	self.position = end_position

	local b1, b2 = string_byte( self.data, start_position, end_position )

	if b2 == nil then
		return nil, "not enough data"
	end

	if not big_endian then
		b1, b2 = b2, b1
	end

	return bytepack_readUInt16( b1, b2 )
end

do

	--- [SHARED AND MENU]
	---
	--- Writes unsigned 2-byte (16 bit) integer as binary string.
	---
	--- Range of values: `0` - `65535`
	---
	---@param value integer The unsigned 2-byte integer.
	---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
	---@return string | nil binary_str The binary string.
	---@return nil | string err_msg The error message.
	local function pack_writeUInt16( value, big_endian )
		if value < 0 or value > 65535 then
			return nil, "UInt16 value out of range"
		end

		local b1, b2 = bytepack_writeUInt16( value )

		if not big_endian then
			b1, b2 = b2, b1
		end

		return string_char( b1, b2 )
	end

	--- [SHARED AND MENU]
	---
	--- Writes unsigned 2-byte (16 bit) integer.
	---
	--- Range of values: `0` - `65535`
	---
	---@param value integer The unsigned 2-byte integer.
	function Writer:writeU16( value )
		local binary_str, err_msg = pack_writeUInt16( value )
		if binary_str == nil then
			error( err_msg, 2 )
		else
			self:write( binary_str )
		end
	end

end

--- [SHARED AND MENU]
---
--- Reads unsigned 3-byte (24 bit) integer from binary string.
---
--- Range of values: `0` - `16777215`
---
---@param binary_str string The binary string.
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@param start_position? integer The start position in binary string, default is `1`.
---@return integer | nil value The unsigned 3-byte integer.
---@return nil | string err_msg The error message.
function pack.readUInt24( binary_str, big_endian, start_position )
	if start_position == nil then
		start_position = 1
	end

	local b1, b2, b3 = string_byte( binary_str, start_position, start_position + 2 )

	if b3 == nil then
		return nil, "not enough data"
	end

	if not big_endian then
		b1, b2, b3 = b3, b2, b1
	end

	return bytepack_readUInt24( b1, b2, b3 )
end

--- [SHARED AND MENU]
---
--- Writes unsigned 3-byte (24 bit) integer as binary string.
---
--- Range of values: `0` - `16777215`
---
---@param value integer The unsigned 3-byte integer.
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@return string | nil binary_str The binary string.
---@return nil | string err_msg The error message.
function pack.writeUInt24( value, big_endian )
	if value < 0 or value > 16777215 then
		return nil, "UInt24 value out of range"
	end

	local b1, b2, b3 = bytepack_writeUInt24( value )

	if not big_endian then
		b1, b2, b3 = b3, b2, b1
	end

	return string_char( b1, b2, b3 )
end

--- [SHARED AND MENU]
---
--- Reads unsigned 4-byte (32 bit) integer from binary string.
---
--- Range of values: `0` - `4294967295`
---
---@param binary_str string The binary string.
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@param start_position? integer The start position in binary string, default is `1`.
---@return integer | nil value The unsigned 4-byte integer.
---@return nil | string err_msg The error message.
function pack.readUInt32( binary_str, big_endian, start_position )
	if start_position == nil then
		start_position = 1
	end

	local b1, b2, b3, b4 = string_byte( binary_str, start_position, start_position + 3 )

	if b4 == nil then
		return nil, "not enough data"
	end

	if not big_endian then
		b1, b2, b3, b4 = b4, b3, b2, b1
	end

	return bytepack_readUInt32( b1, b2, b3, b4 )
end

--- [SHARED AND MENU]
---
--- Reads unsigned 4-byte (32 bit) integer.
---
--- Range of values: `0` - `4294967295`
---
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@return integer | nil value The unsigned 4-byte integer.
---@return nil | string err_msg The error message.
function Reader:readU32( big_endian )
	local start_position = self.position

	local available = self.data_length - start_position
	if available <= 0 then
		return nil, "end of file"
	elseif available < 4 then
		return nil, "not enough data"
	end

	start_position = start_position + 1

	local end_position = start_position + 3
	self.position = end_position

	local b1, b2, b3, b4 = string_byte( self.data, start_position, end_position )

	if b4 == nil then
		return nil, "not enough data"
	end

	if not big_endian then
		b1, b2, b3, b4 = b4, b3, b2, b1
	end

	return bytepack_readUInt32( b1, b2, b3, b4 )
end

do

	--- [SHARED AND MENU]
	---
	--- Writes unsigned 4-byte (32 bit) integer as binary string.
	---
	--- Range of values: `0` - `4294967295`
	---
	---@param value integer The unsigned 4-byte integer.
	---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
	---@return string | nil binary_str The binary string.
	---@return nil | string err_msg The error message.
	local function pack_writeUInt32( value, big_endian )
		if value < 0 or value > 4294967295 then
			return nil, "UInt32 value out of range"
		end

		local b1, b2, b3, b4 = bytepack_writeUInt32( value )

		if not big_endian then
			b1, b2, b3, b4 = b4, b3, b2, b1
		end

		return string_char( b1, b2, b3, b4 )
	end

	pack.writeUInt32 = pack_writeUInt32

	--- [SHARED AND MENU]
	---
	--- Writes unsigned 4-byte (32 bit) integer.
	---
	--- Range of values: `0` - `4294967295`
	---
	---@param value integer The unsigned 4-byte integer.
	---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
	function Writer:writeU32( value, big_endian )
		local binary_str, err_msg = pack_writeUInt32( value, big_endian )
		if binary_str == nil then
			error( err_msg, 2 )
		else
			self:write( binary_str )
		end
	end

end

--- [SHARED AND MENU]
---
--- Reads unsigned 5-byte (40 bit) integer from binary string.
---
--- Range of values: `0` - `1099511627775`.
---
--- All values above range will have problems.
---
---@param binary_str string The binary string.
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@param start_position? integer The start position in binary string, default is `1`.
---@return integer | nil value The unsigned 5-byte integer.
---@return nil | string err_msg The error message.
function pack.readUInt40( binary_str, big_endian, start_position )
	if start_position == nil then
		start_position = 1
	end

	local b1, b2, b3, b4, b5 = string_byte( binary_str, start_position, start_position + 4 )

	if b5 == nil then
		return nil, "not enough data"
	end

	if not big_endian then
		b1, b2, b3, b4, b5 = b5, b4, b3, b2, b1
	end

	return bytepack_readUInt40( b1, b2, b3, b4, b5 )
end

--- [SHARED AND MENU]
---
--- Writes unsigned 5-byte (40 bit) integer as binary string.
---
--- Range of values: `0` - `1099511627775`.
---
---@param value integer The unsigned 5-byte integer.
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@return string | nil binary_str The binary string.
---@return nil | string err_msg The error message.
function pack.writeUInt40( value, big_endian )
	if value < 0 or value > 1099511627775 then
		return nil, "UInt40 value out of range"
	end

	local b1, b2, b3, b4, b5 = bytepack_writeUInt40( value )

	if not big_endian then
		b1, b2, b3, b4, b5 = b5, b4, b3, b2, b1
	end

	return string_char( b1, b2, b3, b4, b5 )
end

--- [SHARED AND MENU]
---
--- Reads unsigned 6-byte (48 bit) integer from binary string.
---
--- Range of values: `0` - `281474976710655`
---
---@param binary_str string The binary string.
---@param big_endian boolean `true` for big endian, `false` for little endian, default is `false`.
---@param start_position? integer The start position in binary string, default is `1`.
---@return integer | nil value The unsigned 6-byte integer.
---@return nil | string err_msg The error message.
function pack.readUInt48( binary_str, big_endian, start_position )
	if start_position == nil then
		start_position = 1
	end

	local b1, b2, b3, b4, b5, b6 = string_byte( binary_str, start_position, start_position + 5 )

	if b6 == nil then
		return nil, "not enough data"
	end

	if not big_endian then
		b1, b2, b3, b4, b5, b6 = b6, b5, b4, b3, b2, b1
	end

	return bytepack_readUInt48( b1, b2, b3, b4, b5, b6 )
end

--- [SHARED AND MENU]
---
--- Writes unsigned 6-byte (48 bit) integer as binary string.
---
--- Range of values: `0` - `281474976710655`
---
---@param value integer The unsigned 6-byte integer.
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@return string | nil binary_str The binary string.
---@return nil | string err_msg The error message.
function pack.writeUInt48( value, big_endian )
	if value < 0 or value > 281474976710655 then
		return nil, "UInt48 value out of range"
	end

	local b1, b2, b3, b4, b5, b6 = bytepack_writeUInt48( value )

	if not big_endian then
		b1, b2, b3, b4, b5, b6 = b6, b5, b4, b3, b2, b1
	end

	return string_char( b1, b2, b3, b4, b5, b6 )
end

--- [SHARED AND MENU]
---
--- Reads unsigned 7-byte (56 bit) integer from binary string.
---
--- Range of values: `0` - `9007199254740991`
---
--- All values above range will have problems.
---
---@param binary_str string The binary string.
---@param big_endian? boolean The endianess.
---@param start_position? integer The start position in binary string, default is `1`.
---@return integer | nil value The unsigned integer.
---@return nil | string err_msg The error message.
function pack.readUInt56( binary_str, big_endian, start_position )
	if start_position == nil then
		start_position = 1
	end

	local b1, b2, b3, b4, b5, b6, b7 = string_byte( binary_str, start_position, start_position + 6 )

	if b7 == nil then
		return nil, "not enough data"
	end

	if not big_endian then
		b1, b2, b3, b4, b5, b6, b7 = b7, b6, b5, b4, b3, b2, b1
	end

	return bytepack_readUInt56( b1, b2, b3, b4, b5, b6, b7 )
end

--- [SHARED AND MENU]
---
--- Writes unsigned 7-byte (56 bit) integer as binary string.
---
--- Range of values: `0` - `9007199254740991`
---
--- All values above range will have problems.
---
---@param value integer The unsigned 7-byte integer.
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@return string | nil binary_str The binary string.
---@return nil | string err_msg The error message.
function pack.writeUInt56( value, big_endian )
	if value < 0 or value > 9007199254740991 then
		return nil, "UInt56 value out of range"
	end

	local b1, b2, b3, b4, b5, b6, b7 = bytepack_writeUInt56( value )

	if not big_endian then
		b1, b2, b3, b4, b5, b6, b7 = b7, b6, b5, b4, b3, b2, b1
	end

	return string_char( b1, b2, b3, b4, b5, b6, b7 )
end

--- [SHARED AND MENU]
---
--- Reads unsigned 8-byte (64 bit) integer as binary string.
---
--- Range of values: `0` - `9007199254740991`
---
--- All values above range will have problems.
---
---@param binary_str string The binary string.
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@param start_position? integer The start position in binary string, default is `1`.
---@return integer | nil value The unsigned 8-byte integer.
---@return nil | string err_msg The error message.
function pack.readUInt64( binary_str, big_endian, start_position )
	if start_position == nil then
		start_position = 1
	end

	local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( binary_str, start_position, start_position + 7 )

	if b8 == nil then
		return nil, "not enough data"
	end

	if not big_endian then
		b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
	end

	return bytepack_readUInt64( b1, b2, b3, b4, b5, b6, b7, b8 )
end

--- [SHARED AND MENU]
---
--- Reads unsigned 8-byte (64 bit) integer.
---
--- Range of values: `0` - `9007199254740991`
---
--- All values above range will have problems.
---
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@return integer | nil value The unsigned 8-byte integer.
---@return nil | string err_msg The error message.
function Reader:readU64( big_endian )
	local start_position = self.position

	local available = self.data_length - start_position
	if available <= 0 then
		return nil, "end of file"
	elseif available < 8 then
		return nil, "not enough data"
	end

	start_position = start_position + 1

	local end_position = start_position + 7
	self.position = end_position

	local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( self.data, start_position, end_position )

	if b8 == nil then
		return nil, "not enough data"
	end

	if not big_endian then
		b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
	end

	return bytepack_readUInt64( b1, b2, b3, b4, b5, b6, b7, b8 )
end

do

	--- [SHARED AND MENU]
	---
	--- Writes unsigned 8-byte (64 bit) integer as binary string.
	---
	--- Range of values: `0` - `9007199254740991`
	---
	--- All values above range will have problems.
	---
	---@param value integer The unsigned 8-byte integer.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string | nil binary_str The binary string.
	---@return nil | string err_msg The error message.
	local function pack_writeUInt64( value, big_endian )
		if value < 0 or value > 9007199254740991 then
			return nil, "UInt64 value out of range"
		end

		local b1, b2, b3, b4, b5, b6, b7, b8 = bytepack_writeUInt64( value )

		if not big_endian then
			b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
		end

		return string_char( b1, b2, b3, b4, b5, b6, b7, b8 )
	end

	pack.writeUInt64 = pack_writeUInt64

	--- [SHARED AND MENU]
	---
	--- Writes unsigned 8-byte (64 bit) integer.
	---
	--- Range of values: `0` - `9007199254740991`
	---
	--- All values above range will have problems.
	---
	---@param value integer The unsigned 8-byte integer.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	function Writer:writeU64( value, big_endian )
		local binary_str, err_msg = pack_writeUInt64( value, big_endian )
		if binary_str == nil then
			error( err_msg, 2 )
		else
			self:write( binary_str )
		end
	end

end

--- [SHARED AND MENU]
---
--- Reads an unsigned integer with the specified number of bits.
---
--- #### Unsigned Integers limits for bit count
--- | Bit count | Max Value (`2^n - 1`)           |
--- |:----------|:--------------------------------|
--- | 1    		| 1                               |
--- | 2    		| 3                               |
--- | 4    		| 15                              |
--- | 8			| 255                             |
--- | 12		| 4,095                           |
--- | 16		| 65,535                          |
--- | 24		| 16,777,215                      |
--- | 32		| 4,294,967,295                   |
--- | 40		| 1,099,511,627,775               |
--- | 48		| 281,474,976,710,655             |
--- | 64		| 18,446,744,073,709,551,615      |
---
---@param bit_count integer The number of bits to read.
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@return integer | nil value The unsigned integer.
---@return nil | string err_msg The error message.
function Reader:readUInt( bit_count, big_endian )
	if bit_count == 0 then
		return 0, nil
	elseif bit_count < 0 then
		return nil, "invalid number of bits"
	end

	local position = self.position

	local available = self.data_length - position
	if available <= 0 then
		return nil, "end of file"
	end

	local byte_count = math_ceil( bit_count * 0.125 )
	if byte_count > available then
		return nil, "not enough data"
	end

	self.position = position + byte_count

	if byte_count == 1 then
		return string_byte( self.data, position + 1 )
	end

	local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( self.data, position + 1, position + byte_count )

	if big_endian then
		if byte_count == 2 then
			return bytepack_readUInt16( b1, b2 )
		elseif byte_count == 3 then
			return bytepack_readUInt24( b1, b2, b3 )
		elseif byte_count == 4 then
			return bytepack_readUInt32( b1, b2, b3, b4 )
		elseif byte_count == 5 then
			return bytepack_readUInt40( b1, b2, b3, b4, b5 )
		elseif byte_count == 6 then
			return bytepack_readUInt48( b1, b2, b3, b4, b5, b6 )
		elseif byte_count == 7 then
			return bytepack_readUInt56( b1, b2, b3, b4, b5, b6, b7 )
		else
			return bytepack_readUInt64( b1, b2, b3, b4, b5, b6, b7, b8 )
		end
	elseif byte_count == 2 then
		return bytepack_readUInt16( b2, b1 )
	elseif byte_count == 3 then
		return bytepack_readUInt24( b3, b2, b1 )
	elseif byte_count == 4 then
		return bytepack_readUInt32( b4, b3, b2, b1 )
	elseif byte_count == 5 then
		return bytepack_readUInt40( b5, b4, b3, b2, b1 )
	elseif byte_count == 6 then
		return bytepack_readUInt48( b6, b5, b4, b3, b2, b1 )
	elseif byte_count == 7 then
		return bytepack_readUInt56( b7, b6, b5, b4, b3, b2, b1 )
	else
		return bytepack_readUInt64( b8, b7, b6, b5, b4, b3, b2, b1 )
	end
end

--- [SHARED AND MENU]
---
--- Writes an unsigned integer with the specified number of bits.
---
--- #### Unsigned Integers limits for bit count
--- | Bit count | Max Value (`2^n - 1`)           |
--- |:----------|:--------------------------------|
--- | 1    		| 1                               |
--- | 2    		| 3                               |
--- | 4    		| 15                              |
--- | 8			| 255                             |
--- | 12		| 4,095                           |
--- | 16		| 65,535                          |
--- | 24		| 16,777,215                      |
--- | 32		| 4,294,967,295                   |
--- | 40		| 1,099,511,627,775               |
--- | 48		| 281,474,976,710,655             |
--- | 64		| 18,446,744,073,709,551,615      |
---
---@param value integer The unsigned integer.
---@param bit_count integer The number of bits to write.
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
function Writer:writeUInt( value, bit_count, big_endian )
	if bit_count == 0 then
		return
	elseif bit_count < 0 then
		error( "invalid number of bits", 2 )
	end

	local byte_count = math_ceil( bit_count * 0.125 )
	if byte_count == 1 then
		self:write( string_char( value ) )
	elseif byte_count == 2 then
		local b1, b2 = bytepack_writeUInt16( value )

		if not big_endian then
			b1, b2 = b2, b1
		end

		self:write( string_char( b1, b2 ) )
	elseif byte_count == 3 then
		local b1, b2, b3 = bytepack_writeUInt24( value )

		if not big_endian then
			b1, b2, b3 = b3, b2, b1
		end

		self:write( string_char( b1, b2, b3 ) )
	elseif byte_count == 4 then
		local b1, b2, b3, b4 = bytepack_writeUInt32( value )

		if not big_endian then
			b1, b2, b3, b4 = b4, b3, b2, b1
		end

		self:write( string_char( b1, b2, b3, b4 ) )
	elseif byte_count == 5 then
		local b1, b2, b3, b4, b5 = bytepack_writeUInt40( value )

		if not big_endian then
			b1, b2, b3, b4, b5 = b5, b4, b3, b2, b1
		end

		self:write( string_char( b1, b2, b3, b4, b5 ) )
	elseif byte_count == 6 then
		local b1, b2, b3, b4, b5, b6 = bytepack_writeUInt48( value )

		if not big_endian then
			b1, b2, b3, b4, b5, b6 = b6, b5, b4, b3, b2, b1
		end

		self:write( string_char( b1, b2, b3, b4, b5, b6 ) )
	elseif byte_count == 7 then
		local b1, b2, b3, b4, b5, b6, b7 = bytepack_writeUInt56( value )

		if not big_endian then
			b1, b2, b3, b4, b5, b6, b7 = b7, b6, b5, b4, b3, b2, b1
		end

		self:write( string_char( b1, b2, b3, b4, b5, b6, b7 ) )
	elseif byte_count == 8 then
		local b1, b2, b3, b4, b5, b6, b7, b8 = bytepack_writeUInt64( value )

		if not big_endian then
			b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
		end

		self:write( string_char( b1, b2, b3, b4, b5, b6, b7, b8 ) )
	else
		error( "invalid number of bits", 2 )
	end
end

-- unsigned fixed-point number
do

	local bytepack_readUnsignedFixedPoint = bytepack.readUnsignedFixedPoint

	--- [SHARED AND MENU]
	---
	--- Reads unsigned fixed-point number (**UQm.n**) as binary string.
	---
	--- ### Commonly used UQm.n formats
	--- | Format  | Range                          | Precision (Step)        |
	--- |:--------|:-------------------------------|:------------------------|
	--- | UQ8.8   | `0 to 255.996`                 | 0.00390625 (1/256)      |
	--- | UQ10.6  | `0 to 1023.984375`             | 0.015625 (1/64)         |
	--- | UQ12.4  | `0 to 4095.9375`               | 0.0625 (1/16)           |
	--- | UQ16.16 | `0 to 65,535.99998`            | 0.0000152588 (1/65536)  |
	--- | UQ24.8  | `0 to 16,777,215.996`          | 0.00390625 (1/256)      |
	--- | UQ32.16 | `0 to 4,294,967,295.99998`     | 0.0000152588 (1/65536)  |
	---
	---@param binary_str string The binary string to read.
	---@param m integer Number of integer bits (including sign bit).
	---@param n integer Number of fractional bits.
	---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
	---@param start_position? integer The start position in binary string, default is `1`.
	---@return number | nil value The unsigned fixed-point number.
	---@return nil | string err_msg The error message.
	function pack.readUnsignedFixedPoint( binary_str, m, n, big_endian, start_position )
		local byte_count = ( m + n ) * 0.125
		if byte_count % 1 ~= 0 then
			return nil, "invalid m.n values"
		end

		if byte_count == 0 then
			return 0
		elseif string_byte( binary_str, 1, 1 ) == nil then
			return nil, "not enough data"
		end

		if start_position == nil then
			start_position = 1
		end

		local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( binary_str, start_position, start_position + byte_count )

		if byte_count == 1 and b1 ~= nil then
			return bytepack_readUnsignedFixedPoint( n, b1 ), nil
		elseif byte_count == 2 and b2 ~= nil then
			if not big_endian then
				b1, b2 = b2, b1
			end

			return bytepack_readUnsignedFixedPoint( n, b1, b2 ), nil
		elseif byte_count == 3 and b3 ~= nil then
			if not big_endian then
				b1, b2, b3 = b3, b2, b1
			end

			return bytepack_readUnsignedFixedPoint( n, b1, b2, b3 ), nil
		elseif byte_count == 4 and b4 ~= nil then
			if not big_endian then
				b1, b2, b3, b4 = b4, b3, b2, b1
			end

			return bytepack_readUnsignedFixedPoint( n, b1, b2, b3, b4 ), nil
		elseif byte_count == 5 and b5 ~= nil then
			if not big_endian then
				b1, b2, b3, b4, b5 = b5, b4, b3, b2, b1
			end

			return bytepack_readUnsignedFixedPoint( n, b1, b2, b3, b4, b5 ), nil
		elseif byte_count == 6 and b6 ~= nil then
			if not big_endian then
				b1, b2, b3, b4, b5, b6 = b6, b5, b4, b3, b2, b1
			end

			return bytepack_readUnsignedFixedPoint( n, b1, b2, b3, b4, b5, b6 ), nil
		elseif byte_count == 7 and b7 ~= nil then
			if not big_endian then
				b1, b2, b3, b4, b5, b6, b7 = b7, b6, b5, b4, b3, b2, b1
			end

			return bytepack_readUnsignedFixedPoint( n, b1, b2, b3, b4, b5, b6, b7 ), nil
		elseif byte_count == 8 and b8 ~= nil then
			if not big_endian then
				b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
			end

			return bytepack_readUnsignedFixedPoint( n, b1, b2, b3, b4, b5, b6, b7, b8 ), nil
		end

		return nil, "not enough data"
	end

	--- [SHARED AND MENU]
	---
	--- Reads unsigned fixed-point number (**UQm.n**).
	---
	--- ### Commonly used UQm.n formats
	--- | Format  | Range                          | Precision (Step)        |
	--- |:--------|:-------------------------------|:------------------------|
	--- | UQ8.8   | `0 to 255.996`                 | 0.00390625 (1/256)      |
	--- | UQ10.6  | `0 to 1023.984375`             | 0.015625 (1/64)         |
	--- | UQ12.4  | `0 to 4095.9375`               | 0.0625 (1/16)           |
	--- | UQ16.16 | `0 to 65,535.99998`            | 0.0000152588 (1/65536)  |
	--- | UQ24.8  | `0 to 16,777,215.996`          | 0.00390625 (1/256)      |
	--- | UQ32.16 | `0 to 4,294,967,295.99998`     | 0.0000152588 (1/65536)  |
	---
	---@param m integer Number of integer bits.
	---@param n integer Number of fractional bits.
	---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
	---@return nil | number value The unsigned fixed-point number.
	---@return string | nil err_msg The error message.
	function Reader:readUnsignedFixedPoint( n, m, big_endian )
		local byte_count = ( m + n ) * 0.125
		if byte_count % 1 ~= 0 or byte_count < 0 then
			return nil, "invalid m.n values"
		end

		if byte_count == 0 then
			return 0, nil
		end

		local position = self.position

		local available = self.data_length - position
		if available <= 0 then
			return nil, "end of file"
		elseif byte_count > available then
			return nil, "not enough data"
		end

		local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( self.data, position + 1, position + byte_count )

		self.position = position + byte_count

		if byte_count == 1 and b1 ~= nil then
			return bytepack_readUnsignedFixedPoint( n, b1 ), nil
		elseif byte_count == 2 and b2 ~= nil then
			if not big_endian then
				b1, b2 = b2, b1
			end

			return bytepack_readUnsignedFixedPoint( n, b1, b2 ), nil
		elseif byte_count == 3 and b3 ~= nil then
			if not big_endian then
				b1, b2, b3 = b3, b2, b1
			end

			return bytepack_readUnsignedFixedPoint( n, b1, b2, b3 ), nil
		elseif byte_count == 4 and b4 ~= nil then
			if not big_endian then
				b1, b2, b3, b4 = b4, b3, b2, b1
			end

			return bytepack_readUnsignedFixedPoint( n, b1, b2, b3, b4 ), nil
		elseif byte_count == 5 and b5 ~= nil then
			if not big_endian then
				b1, b2, b3, b4, b5 = b5, b4, b3, b2, b1
			end

			return bytepack_readUnsignedFixedPoint( n, b1, b2, b3, b4, b5 ), nil
		elseif byte_count == 6 and b6 ~= nil then
			if not big_endian then
				b1, b2, b3, b4, b5, b6 = b6, b5, b4, b3, b2, b1
			end

			return bytepack_readUnsignedFixedPoint( n, b1, b2, b3, b4, b5, b6 ), nil
		elseif byte_count == 7 and b7 ~= nil then
			if not big_endian then
				b1, b2, b3, b4, b5, b6, b7 = b7, b6, b5, b4, b3, b2, b1
			end

			return bytepack_readUnsignedFixedPoint( n, b1, b2, b3, b4, b5, b6, b7 ), nil
		elseif byte_count == 8 and b8 ~= nil then
			if not big_endian then
				b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
			end

			return bytepack_readUnsignedFixedPoint( n, b1, b2, b3, b4, b5, b6, b7, b8 ), nil
		end

		return nil, "not enough data"
	end

end

do

	local bytepack_writeUnsignedFixedPoint = bytepack.writeUnsignedFixedPoint

	--- [SHARED AND MENU]
	---
	--- Writes unsigned fixed-point number (**UQm.n**) as binary string.
	---
	--- ### Commonly used UQm.n formats
	--- | Format  | Range                          | Precision (Step)        |
	--- |:--------|:-------------------------------|:------------------------|
	--- | UQ8.8   | `0 to 255.996`                 | 0.00390625 (1/256)      |
	--- | UQ10.6  | `0 to 1023.984375`             | 0.015625 (1/64)         |
	--- | UQ12.4  | `0 to 4095.9375`               | 0.0625 (1/16)           |
	--- | UQ16.16 | `0 to 65,535.99998`            | 0.0000152588 (1/65536)  |
	--- | UQ24.8  | `0 to 16,777,215.996`          | 0.00390625 (1/256)      |
	--- | UQ32.16 | `0 to 4,294,967,295.99998`     | 0.0000152588 (1/65536)  |
	---
	---@param value number The unsigned fixed-point number.
	---@param m integer Number of integer bits.
	---@param n integer Number of fractional bits.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string | nil binary_str The binary string.
	---@return nil | string err_msg The error message.
	local function pack_writeUnsignedFixedPoint( value, m, n, big_endian )
		local byte_count = ( m + n ) * 0.125
		if byte_count % 1 ~= 0 then
			return nil, "invalid m.n values"
		end

		if byte_count == 0 then
			return "", nil
		elseif value == 0 then
			return string_rep( "\0", byte_count ), nil
		end

		local b1, b2, b3, b4, b5, b6, b7, b8 = bytepack_writeUnsignedFixedPoint( value, m, n )

		if byte_count == 1 then
			if b1 == nil then
				return nil, "invalid value"
			end

			return string_char( b1 ), nil
		elseif byte_count == 2 then
			if b2 == nil then
				return nil, "invalid value"
			end

			if not big_endian then
				b1, b2 = b2, b1
			end

			return string_char( b1, b2 ), nil
		elseif byte_count == 3 then
			if b3 == nil then
				return nil, "invalid value"
			end

			if not big_endian then
				b1, b2, b3 = b3, b2, b1
			end

			return string_char( b1, b2, b3 ), nil
		elseif byte_count == 4 then
			if b4 == nil then
				return nil, "invalid value"
			end

			if not big_endian then
				b1, b2, b3, b4 = b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4 ), nil
		elseif byte_count == 5 then
			if b5 == nil then
				return nil, "invalid value"
			end

			if not big_endian then
				b1, b2, b3, b4, b5 = b5, b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4, b5 ), nil
		elseif byte_count == 6 then
			if b6 == nil then
				return nil, "invalid value"
			end

			if not big_endian then
				b1, b2, b3, b4, b5, b6 = b6, b5, b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4, b5, b6 ), nil
		elseif byte_count == 7 then
			if b7 == nil then
				return nil, "invalid value"
			end

			if not big_endian then
				b1, b2, b3, b4, b5, b6, b7 = b7, b6, b5, b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4, b5, b6, b7 ), nil
		elseif byte_count == 8 then
			if b8 == nil then
				return nil, "invalid value"
			end

			if not big_endian then
				b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4, b5, b6, b7, b8 ), nil
		end

		return nil, "unsupported byte count"
	end

	pack.writeUnsignedFixedPoint = pack_writeUnsignedFixedPoint

	--- [SHARED AND MENU]
	---
	--- Writes unsigned fixed-point number (**UQm.n**).
	---
	--- ### Commonly used UQm.n formats
	--- | Format  | Range                          | Precision (Step)        |
	--- |:--------|:-------------------------------|:------------------------|
	--- | UQ8.8   | `0 to 255.996`                 | 0.00390625 (1/256)      |
	--- | UQ10.6  | `0 to 1023.984375`             | 0.015625 (1/64)         |
	--- | UQ12.4  | `0 to 4095.9375`               | 0.0625 (1/16)           |
	--- | UQ16.16 | `0 to 65,535.99998`            | 0.0000152588 (1/65536)  |
	--- | UQ24.8  | `0 to 16,777,215.996`          | 0.00390625 (1/256)      |
	--- | UQ32.16 | `0 to 4,294,967,295.99998`     | 0.0000152588 (1/65536)  |
	---
	---@param value number The unsigned fixed-point number.
	---@param m integer Number of integer bits.
	---@param n integer Number of fractional bits.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	function Writer:writeUnsignedFixedPoint( value, m, n, big_endian )
		local binary_str, err_msg = pack_writeUnsignedFixedPoint( value, m, n, big_endian )
		if binary_str == nil then
			error( err_msg, 2 )
		else
			self:write( binary_str )
		end
	end

end

--- [SHARED AND MENU]
---
--- Reads signed 1-byte (8 bit) integer from binary string.
---
--- Range of values: `-128` - `127`
---
---@param binary_str string The binary string.
---@param start_position? integer The start position in binary string, default is `1`.
---@return integer | nil value The signed 1-byte integer.
---@return nil | string err_msg The error message.
function pack.readInt8( binary_str, start_position )
	local byte = string_byte( binary_str, start_position or 1 )
	if byte == nil then
		return nil, "not enough data"
	else
		return bytepack_readInt8( byte ), nil
	end
end

--- [SHARED AND MENU]
---
--- Reads signed 1-byte (8 bit) integer.
---
--- Range of values: `-128` - `127`
---
---@return integer | nil value The signed 1-byte integer.
---@return nil | string err_msg The error message.
function Reader:readI8()
	local u8, err_msg = self:readU8()
	if u8 == nil then
		return nil, err_msg
	else
		return bytepack_readInt8( u8 ), nil
	end
end

do

	--- [SHARED AND MENU]
	---
	--- Writes signed 1-byte (8 bit) integer as binary string.
	---
	--- Range of values: `-128` - `127`
	---
	---@param value integer The signed 1-byte integer.
	---@return string | nil binary_str The binary string.
	---@return nil | string err_msg The error message.
	local function pack_writeInt8( value )
		if value < -128 or value > 127 then
			return nil, "Int8 value out of range"
		else
			return string_char( bytepack_writeInt8( value ) ), nil
		end
	end

	pack.writeInt8 = pack_writeInt8

	--- [SHARED AND MENU]
	---
	--- Writes signed 1-byte (8 bit) integer.
	---
	--- Range of values: `-128` - `127`
	---
	---@param value integer The signed 1-byte integer.
	function Writer:writeI8( value )
		local binary_str, err_msg = pack_writeInt8( value )
		if binary_str == nil then
			error( err_msg, 2 )
		else
			self:write( binary_str )
		end
	end

end

--- [SHARED AND MENU]
---
--- Reads signed 2-byte (16 bit) integer as binary string.
---
--- Range of values: `-32768` - `32767`
---
---@param binary_str string The binary string.
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@param start_position? integer The start position in binary string, default is `1`.
---@return integer | nil value The signed 2-byte integer.
---@return nil | string err_msg The error message.
function pack.readInt16( binary_str, big_endian, start_position )
	if start_position == nil then
		start_position = 1
	end

	local b1, b2 = string_byte( binary_str, start_position, start_position + 1 )

	if b2 == nil then
		return nil, "not enough data"
	end

	if not big_endian then
		b1, b2 = b2, b1
	end

	return bytepack_readInt16( b1, b2 )
end

--- [SHARED AND MENU]
---
--- Reads signed 2-byte (16 bit) integer.
---
--- Range of values: `-32768` - `32767`
---
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@return integer | nil value The signed 2-byte integer.
---@return nil | string err_msg The error message.
function Reader:readI16( big_endian )
	local start_position = self.position

	local available = self.data_length - start_position
	if available <= 0 then
		return nil, "end of file"
	elseif available < 2 then
		return nil, "not enough data"
	end

	start_position = start_position + 1

	local end_position = start_position + 1
	self.position = end_position

	local b1, b2 = string_byte( self.data, start_position, end_position )

	if not big_endian then
		b1, b2 = b2, b1
	end

	return bytepack_readInt16( b1, b2 )
end

do

	--- [SHARED AND MENU]
	---
	--- Writes signed 2-byte (16 bit) integer as binary string.
	---
	--- Range of values: `-32768` - `32767`
	---
	---@param value integer The signed 2-byte integer.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string | nil binary_str The binary string.
	---@return nil | string err_msg The error message.
	local function pack_writeInt16( value, big_endian )
		if value < -32768 or value > 32767 then
			return nil, "Int16 value out of range"
		end

		local b1, b2 = bytepack_writeInt16( value )

		if not big_endian then
			b1, b2 = b2, b1
		end

		return string_char( b1, b2 )
	end

	pack.writeInt16 = pack_writeInt16

	--- [SHARED AND MENU]
	---
	--- Writes signed 2-byte (16 bit) integer.
	---
	--- Range of values: `-32768` - `32767`
	---
	---@param value integer The signed 2-byte integer.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	function Writer:writeI16( value, big_endian )
		local binary_str, err_msg = pack_writeInt16( value, big_endian )
		if binary_str == nil then
			error( err_msg, 2 )
		else
			self:write( binary_str )
		end
	end

end

--- [SHARED AND MENU]
---
--- Reads signed 3-byte (24 bit) integer as binary string.
---
--- Range of values: `-8388608` - `8388607`
---
---@param binary_str string The binary string.
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@param start_position? integer The start position in binary string, default is `1`.
---@return integer | nil value The signed 3-byte integer.
---@return nil | string err_msg The error message.
function pack.readInt24( binary_str, big_endian, start_position )
	if start_position == nil then
		start_position = 1
	end

	local b1, b2, b3 = string_byte( binary_str, start_position, start_position + 2 )

	if b3 == nil then
		return nil, "not enough data"
	end

	if not big_endian then
		b1, b2, b3 = b3, b2, b1
	end

	return bytepack_readInt24( b1, b2, b3 )
end

--- [SHARED AND MENU]
---
--- Writes signed 3-byte (24 bit) integer as binary string.
---
--- Range of values: `-8388608` - `8388607`
---
---@param value integer The signed 3-byte integer.
---@param big_endian? boolean `true` for big endian, `false` for little endian.
---@return string | nil binary_str The binary string.
---@return nil | string err_msg The error message.
function pack.writeInt24( value, big_endian )
	if value < -8388608 or value > 8388607 then
		return nil, "Int24 value out of range"
	end

	local b1, b2, b3 = bytepack_writeInt24( value )

	if not big_endian then
		b1, b2, b3 = b3, b2, b1
	end

	return string_char( b1, b2, b3 )
end

--- [SHARED AND MENU]
---
--- Reads signed 4-byte (32 bit) integer from binary string.
---
--- Range of values: `-2147483648` - `2147483647`
---
---@param binary_str string The binary string.
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@param start_position? integer The start position in binary string, default is `1`.
---@return integer | nil value The signed 4-byte integer.
---@return nil | string err_msg The error message.
function pack.readInt32( binary_str, big_endian, start_position )
	if start_position == nil then
		start_position = 1
	end

	local b1, b2, b3, b4 = string_byte( binary_str, start_position, start_position + 3 )

	if b4 == nil then
		return nil, "not enough data"
	end

	if not big_endian then
		b1, b2, b3, b4 = b4, b3, b2, b1
	end

	return bytepack_readInt32( b1, b2, b3, b4 )
end

--- [SHARED AND MENU]
---
--- Reads signed 4-byte (32 bit) integer.
---
--- Range of values: `-2147483648` - `2147483647`
---
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@return integer | nil value The signed 4-byte integer.
---@return nil | string err_msg The error message.
function Reader:readI32( big_endian )
	local start_position = self.position

	local available = self.data_length - start_position
	if available <= 0 then
		return nil, "end of file"
	elseif available < 4 then
		return nil, "not enough data"
	end

	start_position = start_position + 1

	local end_position = start_position + 3
	self.position = end_position

	local b1, b2, b3, b4 = string_byte( self.data, start_position, end_position )

	if not big_endian then
		b1, b2, b3, b4 = b4, b3, b2, b1
	end

	return bytepack_readInt32( b1, b2, b3, b4 )
end

do

	--- [SHARED AND MENU]
	---
	--- Writes signed 4-byte (32 bit) integer as binary string.
	---
	--- Range of values: `-2147483648` - `2147483647`
	---
	---@param value integer The signed 4-byte integer.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string | nil binary_str The binary string.
	---@return nil | string err_msg The error message.
	local function pack_writeInt32( value, big_endian )
		if value < -2147483648 or value > 2147483647 then
			return nil, "Int32 value out of range"
		end

		local b1, b2, b3, b4 = bytepack_writeInt32( value )

		if not big_endian then
			b1, b2, b3, b4 = b4, b3, b2, b1
		end

		return string_char( b1, b2, b3, b4 )
	end

	pack.writeInt32 = pack_writeInt32

	--- [SHARED AND MENU]
	---
	--- Writes signed 4-byte (32 bit) integer.
	---
	--- Range of values: `-2147483648` - `2147483647`
	---
	---@param value integer The signed 4-byte integer.
	function Writer:writeI32( value, big_endian )
		local binary_str, err_msg = pack_writeInt32( value, big_endian )
		if binary_str == nil then
			error( err_msg, 2 )
		else
			self:write( binary_str )
		end
	end

end

--- [SHARED AND MENU]
---
--- Reads signed 5-byte (40 bit) integer from binary string.
---
--- Range of values: `-549755813888` - `549755813887`
---
---@param binary_str string The binary string.
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@param start_position? integer The start position in binary string, default is `1`.
---@return integer | nil value The signed 5-byte integer.
---@return nil | string err_msg The error message.
function pack.readInt40( binary_str, big_endian, start_position )
	if start_position == nil then
		start_position = 1
	end

	local b1, b2, b3, b4, b5 = string_byte( binary_str, start_position, start_position + 4 )

	if b5 == nil then
		return nil, "not enough data"
	end

	if not big_endian then
		b1, b2, b3, b4, b5 = b5, b4, b3, b2, b1
	end

	return bytepack_readInt40( b1, b2, b3, b4, b5 )
end

--- [SHARED AND MENU]
---
--- Writes signed 5-byte (40 bit) integer as binary string.
---
--- Range of values: `-549755813888` - `549755813887`
---
---@param value integer The signed 5-byte integer.
---@param big_endian? boolean `true` for big endian, `false` for little endian.
---@return string | nil binary_str The binary string.
---@return nil | string err_msg The error message.
function pack.writeInt40( value, big_endian )
	if value < -549755813888 or value > 549755813887 then
		return nil, "Int40 value out of range"
	end

	local b1, b2, b3, b4, b5 = bytepack_writeInt40( value )

	if not big_endian then
		b1, b2, b3, b4, b5 = b5, b4, b3, b2, b1
	end

	return string_char( b1, b2, b3, b4, b5 )
end

--- [SHARED AND MENU]
---
--- Reads signed 6-byte (48 bit) integer from binary string.
---
--- Range of values: `-140737488355328` - `140737488355327`
---
---@param binary_str string The binary string.
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@param start_position? integer The start position in binary string, default is `1`.
---@return integer | nil value The signed 6-byte integer.
---@return nil | string err_msg The error message.
function pack.readInt48( binary_str, big_endian, start_position )
	if start_position == nil then
		start_position = 1
	end

	local b1, b2, b3, b4, b5, b6 = string_byte( binary_str, start_position, start_position + 5 )

	if b6 == nil then
		return nil, "not enough data"
	end

	if not big_endian then
		b1, b2, b3, b4, b5, b6 = b6, b5, b4, b3, b2, b1
	end

	return bytepack_readInt48( b1, b2, b3, b4, b5, b6 )
end

--- [SHARED AND MENU]
---
--- Writes signed 6-byte (48 bit) integer as binary string.
---
--- Range of values: `-140737488355328` - `140737488355327`
---
---@param value integer The signed 6-byte integer.
---@param big_endian? boolean `true` for big endian, `false` for little endian.
---@return string | nil binary_str The binary string.
---@return nil | string err_msg The error message.
function pack.writeInt48( value, big_endian )
	if value < -140737488355328 or value > 140737488355327 then
		return nil, "Int48 value out of range"
	end

	local b1, b2, b3, b4, b5, b6 = bytepack_writeInt48( value )

	if not big_endian then
		b1, b2, b3, b4, b5, b6 = b6, b5, b4, b3, b2, b1
	end

	return string_char( b1, b2, b3, b4, b5, b6 )
end

--- [SHARED AND MENU]
---
--- Reads signed 7-byte (56 bit) integer from binary string.
---
--- Range of values: `-36028797018963968` - `36028797018963967`
---
---@param binary_str string The binary string.
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@param start_position? integer The start position in binary string, default is `1`.
---@return integer | nil value The signed 7-byte integer.
---@return nil | string err_msg The error message.
function pack.readInt56( binary_str, big_endian, start_position )
	if start_position == nil then
		start_position = 1
	end

	local b1, b2, b3, b4, b5, b6, b7 = string_byte( binary_str, start_position, start_position + 6 )

	if b7 == nil then
		return nil, "not enough data"
	end

	if not big_endian then
		b1, b2, b3, b4, b5, b6, b7 = b7, b6, b5, b4, b3, b2, b1
	end

	return bytepack_readInt56( b1, b2, b3, b4, b5, b6, b7 )
end

--- [SHARED AND MENU]
---
--- Writes signed 7-byte (56 bit) integer as binary string.
---
--- Range of values: `-36028797018963968` - `36028797018963967`
---
---@param value integer The signed 7-byte integer.
---@param big_endian? boolean `true` for big endian, `false` for little endian.
---@return string | nil binary_str The binary string.
---@return nil | string err_msg The error message.
function pack.writeInt56( value, big_endian )
	if value < -36028797018963968 or value > 36028797018963967 then
		return nil, "Int56 value out of range"
	end

	local b1, b2, b3, b4, b5, b6, b7 = bytepack_writeInt56( value )

	if not big_endian then
		b1, b2, b3, b4, b5, b6, b7 = b7, b6, b5, b4, b3, b2, b1
	end

	return string_char( b1, b2, b3, b4, b5, b6, b7 )
end

--- [SHARED AND MENU]
---
--- Reads signed 8-byte (64 bit) integer from binary string.
---
--- Range of values: `-9007199254740991` - `9007199254740991`
---
--- All values above range will have problems.
---
---@param binary_str string The binary string.
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@param start_position? integer The start position in binary string, default is `1`.
---@return integer | nil value The signed 8-byte integer.
---@return nil | string err_msg The error message.
function pack.readInt64( binary_str, big_endian, start_position )
	if start_position == nil then
		start_position = 1
	end

	local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( binary_str, start_position, start_position + 7 )

	if b8 == nil then
		return nil, "not enough data"
	end

	if not big_endian then
		b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
	end

	return bytepack_readInt64( b1, b2, b3, b4, b5, b6, b7, b8 )
end

--- [SHARED AND MENU]
---
--- Reads signed 8-byte (64 bit) integer.
---
--- Range of values: `-9007199254740991` - `9007199254740991`
---
--- All values above range will have problems.
---
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@return integer | nil value The signed 8-byte integer.
---@return nil | string err_msg The error message.
function Reader:readI64( big_endian )
	local start_position = self.position

	local available = self.data_length - start_position
	if available <= 0 then
		return nil, "end of file"
	elseif available < 8 then
		return nil, "not enough data"
	end

	start_position = start_position + 1

	local end_position = start_position + 7
	self.position = end_position

	local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( self.data, start_position, end_position )

	if not big_endian then
		b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
	end

	return bytepack_readInt64( b1, b2, b3, b4, b5, b6, b7, b8 )
end

do

	--- [SHARED AND MENU]
	---
	--- Writes signed 8-byte (64 bit) integer as binary string.
	---
	--- Range of values: `-9007199254740991` - `9007199254740991`
	---
	--- All values above range will have problems.
	---
	---@param value integer The signed 8-byte integer.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string | nil binary_str The binary string.
	---@return nil | string err_msg The error message.
	local function pack_writeInt64( value, big_endian )
		if value < -9007199254740991 or value > 9007199254740991 then
			return nil, "Int64 value out of range"
		end

		local b1, b2, b3, b4, b5, b6, b7, b8 = bytepack_writeInt64( value )

		if not big_endian then
			b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
		end

		return string_char( b1, b2, b3, b4, b5, b6, b7, b8 )
	end

	pack.writeInt64 = pack_writeInt64

	--- [SHARED AND MENU]
	---
	--- Writes signed 8-byte (64 bit) integer.
	---
	--- Range of values: `-9007199254740991` - `9007199254740991`
	---
	--- All values above range will have problems.
	---
	---@param value integer The signed 8-byte integer.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	function Writer:writeI64( value, big_endian )
		local binary_str, err_msg = pack_writeInt64( value, big_endian )
		if binary_str == nil then
			error( err_msg, 2 )
		else
			self:write( binary_str )
		end
	end

end

--- [SHARED AND MENU]
---
--- Reads an signed integer with the specified number of bits.
---
--- #### Signed Integers limits by bit count
--- | Bit count | Min Value (`-2^(n - 1)`)	 | Max Value (`2^(n - 1) - 1`) |
--- |:----------|:---------------------------|:----------------------------|
--- | 1			| -1						 | 0						   |
--- | 2			| -2						 | 1						   |
--- | 4			| -8						 | 7						   |
--- | 8			| -128						 | 127						   |
--- | 12		| -2,048					 | 2,047					   |
--- | 16		| -32,768					 | 32,767					   |
--- | 24		| -8,388,608				 | 8,388,607				   |
--- | 32		| -2,147,483,648			 | 2,147,483,647			   |
--- | 40		| -549,755,813,888			 | 549,755,813,887			   |
--- | 48		| -140,737,488,355,328		 | 140,737,488,355,327		   |
--- | 64		| -9,223,372,036,854,775,808 | 9,223,372,036,854,775,807   |
---
---@param bit_count integer The number of bits to read.
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@return integer | nil value The signed integer.
---@return nil | string err_msg The error message.
function Reader:readInt( bit_count, big_endian )
	if bit_count == 0 then
		return 0, nil
	elseif bit_count < 0 then
		return nil, "invalid number of bits"
	end

	local position = self.position

	local available = self.data_length - position
	if available <= 0 then
		return nil, "end of file"
	end

	local byte_count = math_ceil( bit_count * 0.125 )
	if byte_count > available then
		return nil, "not enough data"
	end

	self.position = position + byte_count

	if byte_count == 1 then
		return string_byte( self.data, position + 1 )
	end

	local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( self.data, position + 1, position + byte_count )

	if big_endian then
		if byte_count == 2 then
			return bytepack_readInt16( b1, b2 )
		elseif byte_count == 3 then
			return bytepack_readInt24( b1, b2, b3 )
		elseif byte_count == 4 then
			return bytepack_readInt32( b1, b2, b3, b4 )
		elseif byte_count == 5 then
			return bytepack_readInt40( b1, b2, b3, b4, b5 )
		elseif byte_count == 6 then
			return bytepack_readInt48( b1, b2, b3, b4, b5, b6 )
		elseif byte_count == 7 then
			return bytepack_readInt56( b1, b2, b3, b4, b5, b6, b7 )
		else
			return bytepack_readInt64( b1, b2, b3, b4, b5, b6, b7, b8 )
		end
	elseif byte_count == 2 then
		return bytepack_readInt16( b2, b1 )
	elseif byte_count == 3 then
		return bytepack_readInt24( b3, b2, b1 )
	elseif byte_count == 4 then
		return bytepack_readInt32( b4, b3, b2, b1 )
	elseif byte_count == 5 then
		return bytepack_readInt40( b5, b4, b3, b2, b1 )
	elseif byte_count == 6 then
		return bytepack_readInt48( b6, b5, b4, b3, b2, b1 )
	elseif byte_count == 7 then
		return bytepack_readInt56( b7, b6, b5, b4, b3, b2, b1 )
	else
		return bytepack_readInt64( b8, b7, b6, b5, b4, b3, b2, b1 )
	end
end

--- [SHARED AND MENU]
---
--- Writes an signed integer with the specified number of bits.
---
--- #### Signed Integers limits by bit count
--- | Bit count | Min Value (`-2^(n - 1)`)	 | Max Value (`2^(n - 1) - 1`) |
--- |:----------|:---------------------------|:----------------------------|
--- | 1			| -1						 | 0						   |
--- | 2			| -2						 | 1						   |
--- | 4			| -8						 | 7						   |
--- | 8			| -128						 | 127						   |
--- | 12		| -2,048					 | 2,047					   |
--- | 16		| -32,768					 | 32,767					   |
--- | 24		| -8,388,608				 | 8,388,607				   |
--- | 32		| -2,147,483,648			 | 2,147,483,647			   |
--- | 40		| -549,755,813,888			 | 549,755,813,887			   |
--- | 48		| -140,737,488,355,328		 | 140,737,488,355,327		   |
--- | 64		| -9,223,372,036,854,775,808 | 9,223,372,036,854,775,807   |
---
---@param value integer The unsigned integer.
---@param bit_count integer The number of bits to write.
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
function Writer:writeInt( value, bit_count, big_endian )
	if bit_count == 0 then
		return
	elseif bit_count < 0 then
		error( "invalid number of bits", 2 )
	end

	local byte_count = math_ceil( bit_count * 0.125 )
	if byte_count == 1 then
		self:write( string_char( value ) )
	elseif byte_count == 2 then
		local b1, b2 = bytepack_writeInt16( value )

		if not big_endian then
			b1, b2 = b2, b1
		end

		self:write( string_char( b1, b2 ) )
	elseif byte_count == 3 then
		local b1, b2, b3 = bytepack_writeInt24( value )

		if not big_endian then
			b1, b2, b3 = b3, b2, b1
		end

		self:write( string_char( b1, b2, b3 ) )
	elseif byte_count == 4 then
		local b1, b2, b3, b4 = bytepack_writeInt32( value )

		if not big_endian then
			b1, b2, b3, b4 = b4, b3, b2, b1
		end

		self:write( string_char( b1, b2, b3, b4 ) )
	elseif byte_count == 5 then
		local b1, b2, b3, b4, b5 = bytepack_writeInt40( value )

		if not big_endian then
			b1, b2, b3, b4, b5 = b5, b4, b3, b2, b1
		end

		self:write( string_char( b1, b2, b3, b4, b5 ) )
	elseif byte_count == 6 then
		local b1, b2, b3, b4, b5, b6 = bytepack_writeInt48( value )

		if not big_endian then
			b1, b2, b3, b4, b5, b6 = b6, b5, b4, b3, b2, b1
		end

		self:write( string_char( b1, b2, b3, b4, b5, b6 ) )
	elseif byte_count == 7 then
		local b1, b2, b3, b4, b5, b6, b7 = bytepack_writeInt56( value )

		if not big_endian then
			b1, b2, b3, b4, b5, b6, b7 = b7, b6, b5, b4, b3, b2, b1
		end

		self:write( string_char( b1, b2, b3, b4, b5, b6, b7 ) )
	elseif byte_count == 8 then
		local b1, b2, b3, b4, b5, b6, b7, b8 = bytepack_writeInt64( value )

		if not big_endian then
			b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
		end

		self:write( string_char( b1, b2, b3, b4, b5, b6, b7, b8 ) )
	else
		error( "invalid number of bits", 2 )
	end
end

-- signed fixed-point number
do

	local bytepack_readFixedPoint = bytepack.readFixedPoint

	--- [SHARED AND MENU]
	---
	--- Reads signed fixed-point number (**Qm.n**) from binary string.
	---
	--- ### Commonly used Qm.n formats
	--- | Format | Range                          | Precision (Step)        |
	--- |:-------|:-------------------------------|:------------------------|
	--- | Q8.8   | `-128.0 to 127.996`            | 0.00390625 (1/256)      |
	--- | Q10.6  | `-512.0 to 511.984375`         | 0.015625 (1/64)         |
	--- | Q12.4  | `-2048.0 to 2047.9375`         | 0.0625 (1/16)           |
	--- | Q16.16 | `-32,768.0 to 32,767.99998`    | 0.0000152588 (1/65536)  |
	--- | Q24.8  | `-8,388,608.0 to 8,388,607.996`| 0.00390625 (1/256)      |
	--- | Q32.16 | `-2,147,483,648.0 to 2,147,483,647.99998` | 0.0000152588 (1/65536) |
	---
	---@param binary_str string The binary string to read.
	---@param m integer Number of integer bits (including sign bit).
	---@param n integer Number of fractional bits.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return number | nil value The signed fixed-point number.
	---@return nil | string err_msg The error message.
	function pack.readFixedPoint( binary_str, m, n, big_endian, start_position )
		local byte_count = ( m + n ) * 0.125
		if byte_count % 1 ~= 0 then
			return nil, "invalid m.n values"
		end

		if byte_count == 0 then
			return 0
		elseif string_byte( binary_str, 1, 1 ) == nil then
			return nil, "not enough data"
		end

		if start_position == nil then
			start_position = 1
		end

		local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( binary_str, start_position, start_position + byte_count )

		if byte_count == 1 and b1 ~= nil then
			return bytepack_readFixedPoint( n, b1 ), nil
		elseif byte_count == 2 and b2 ~= nil then
			if not big_endian then
				b1, b2 = b2, b1
			end

			return bytepack_readFixedPoint( n, b1, b2 ), nil
		elseif byte_count == 3 and b3 ~= nil then
			if not big_endian then
				b1, b2, b3 = b3, b2, b1
			end

			return bytepack_readFixedPoint( n, b1, b2, b3 ), nil
		elseif byte_count == 4 and b4 ~= nil then
			if not big_endian then
				b1, b2, b3, b4 = b4, b3, b2, b1
			end

			return bytepack_readFixedPoint( n, b1, b2, b3, b4 ), nil
		elseif byte_count == 5 and b5 ~= nil then
			if not big_endian then
				b1, b2, b3, b4, b5 = b5, b4, b3, b2, b1
			end

			return bytepack_readFixedPoint( n, b1, b2, b3, b4, b5 ), nil
		elseif byte_count == 6 and b6 ~= nil then
			if not big_endian then
				b1, b2, b3, b4, b5, b6 = b6, b5, b4, b3, b2, b1
			end

			return bytepack_readFixedPoint( n, b1, b2, b3, b4, b5, b6 ), nil
		elseif byte_count == 7 and b7 ~= nil then
			if not big_endian then
				b1, b2, b3, b4, b5, b6, b7 = b7, b6, b5, b4, b3, b2, b1
			end

			return bytepack_readFixedPoint( n, b1, b2, b3, b4, b5, b6, b7 ), nil
		elseif byte_count == 8 and b8 ~= nil then
			if not big_endian then
				b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
			end

			return bytepack_readFixedPoint( n, b1, b2, b3, b4, b5, b6, b7, b8 ), nil
		end

		return nil, "not enough data"
	end

	--- [SHARED AND MENU]
	---
	--- Reads signed fixed-point number (**Qm.n**).
	---
	--- ### Commonly used Qm.n formats
	--- | Format | Range                          | Precision (Step)        |
	--- |:-------|:-------------------------------|:------------------------|
	--- | Q8.8   | `-128.0 to 127.996`            | 0.00390625 (1/256)      |
	--- | Q10.6  | `-512.0 to 511.984375`         | 0.015625 (1/64)         |
	--- | Q12.4  | `-2048.0 to 2047.9375`         | 0.0625 (1/16)           |
	--- | Q16.16 | `-32,768.0 to 32,767.99998`    | 0.0000152588 (1/65536)  |
	--- | Q24.8  | `-8,388,608.0 to 8,388,607.996`| 0.00390625 (1/256)      |
	--- | Q32.16 | `-2,147,483,648.0 to 2,147,483,647.99998` | 0.0000152588 (1/65536) |
	---
	---@param m integer Number of integer bits (including sign bit).
	---@param n integer Number of fractional bits.
	---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
	---@return nil | number value The signed fixed-point number.
	---@return string | nil err_msg The error message.
	function Reader:readFixedPoint( n, m, big_endian )
		local byte_count = ( m + n ) * 0.125
		if byte_count % 1 ~= 0 or byte_count < 0 then
			return nil, "invalid m.n values"
		end

		if byte_count == 0 then
			return 0, nil
		end

		local position = self.position

		local available = self.data_length - position
		if available <= 0 then
			return nil, "end of file"
		elseif byte_count > available then
			return nil, "not enough data"
		end

		local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( self.data, position + 1, position + byte_count )

		self.position = position + byte_count

		if byte_count == 1 and b1 ~= nil then
			return bytepack_readFixedPoint( n, b1 ), nil
		elseif byte_count == 2 and b2 ~= nil then
			if not big_endian then
				b1, b2 = b2, b1
			end

			return bytepack_readFixedPoint( n, b1, b2 ), nil
		elseif byte_count == 3 and b3 ~= nil then
			if not big_endian then
				b1, b2, b3 = b3, b2, b1
			end

			return bytepack_readFixedPoint( n, b1, b2, b3 ), nil
		elseif byte_count == 4 and b4 ~= nil then
			if not big_endian then
				b1, b2, b3, b4 = b4, b3, b2, b1
			end

			return bytepack_readFixedPoint( n, b1, b2, b3, b4 ), nil
		elseif byte_count == 5 and b5 ~= nil then
			if not big_endian then
				b1, b2, b3, b4, b5 = b5, b4, b3, b2, b1
			end

			return bytepack_readFixedPoint( n, b1, b2, b3, b4, b5 ), nil
		elseif byte_count == 6 and b6 ~= nil then
			if not big_endian then
				b1, b2, b3, b4, b5, b6 = b6, b5, b4, b3, b2, b1
			end

			return bytepack_readFixedPoint( n, b1, b2, b3, b4, b5, b6 ), nil
		elseif byte_count == 7 and b7 ~= nil then
			if not big_endian then
				b1, b2, b3, b4, b5, b6, b7 = b7, b6, b5, b4, b3, b2, b1
			end

			return bytepack_readFixedPoint( n, b1, b2, b3, b4, b5, b6, b7 ), nil
		elseif byte_count == 8 and b8 ~= nil then
			if not big_endian then
				b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
			end

			return bytepack_readFixedPoint( n, b1, b2, b3, b4, b5, b6, b7, b8 ), nil
		end

		return nil, "not enough data"
	end

end

do

	local bytepack_writeFixedPoint = bytepack.writeFixedPoint

	--- [SHARED AND MENU]
	---
	--- Writes signed fixed-point number (**Qm.n**) as binary string.
	---
	--- ### Commonly used Qm.n formats
	--- | Format | Range                          | Precision (Step)        |
	--- |:-------|:-------------------------------|:------------------------|
	--- | Q8.8   | `-128.0 to 127.996`            | 0.00390625 (1/256)      |
	--- | Q10.6  | `-512.0 to 511.984375`         | 0.015625 (1/64)         |
	--- | Q12.4  | `-2048.0 to 2047.9375`         | 0.0625 (1/16)           |
	--- | Q16.16 | `-32,768.0 to 32,767.99998`    | 0.0000152588 (1/65536)  |
	--- | Q24.8  | `-8,388,608.0 to 8,388,607.996`| 0.00390625 (1/256)      |
	--- | Q32.16 | `-2,147,483,648.0 to 2,147,483,647.99998` | 0.0000152588 (1/65536) |
	---
	---@param value number The signed fixed-point number.
	---@param m integer Number of integer bits (including sign bit).
	---@param n integer Number of fractional bits.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string | nil binary_str The binary string.
	---@return nil | string err_msg The error message.
	local function pack_writeFixedPoint( value, m, n, big_endian )
		local byte_count = ( m + n ) * 0.125
		if byte_count % 1 ~= 0 then
			return nil, "invalid m.n values"
		end

		if byte_count == 0 then
			return "", nil
		elseif value == 0 then
			return string_rep( "\0", byte_count ), nil
		end

		local b1, b2, b3, b4, b5, b6, b7, b8 = bytepack_writeFixedPoint( value, m, n )

		if byte_count == 1 then
			if b1 == nil then
				return nil, "invalid value"
			end

			return string_char( b1 ), nil
		elseif byte_count == 2 then
			if b2 == nil then
				return nil, "invalid value"
			end

			if not big_endian then
				b1, b2 = b2, b1
			end

			return string_char( b1, b2 ), nil
		elseif byte_count == 3 then
			if b3 == nil then
				return nil, "invalid value"
			end

			if not big_endian then
				b1, b2, b3 = b3, b2, b1
			end

			return string_char( b1, b2, b3 ), nil
		elseif byte_count == 4 then
			if b4 == nil then
				return nil, "invalid value"
			end

			if not big_endian then
				b1, b2, b3, b4 = b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4 ), nil
		elseif byte_count == 5 then
			if b5 == nil then
				return nil, "invalid value"
			end

			if not big_endian then
				b1, b2, b3, b4, b5 = b5, b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4, b5 ), nil
		elseif byte_count == 6 then
			if b6 == nil then
				return nil, "invalid value"
			end

			if not big_endian then
				b1, b2, b3, b4, b5, b6 = b6, b5, b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4, b5, b6 ), nil
		elseif byte_count == 7 then
			if b7 == nil then
				return nil, "invalid value"
			end

			if not big_endian then
				b1, b2, b3, b4, b5, b6, b7 = b7, b6, b5, b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4, b5, b6, b7 ), nil
		elseif byte_count == 8 then
			if b8 == nil then
				return nil, "invalid value"
			end

			if not big_endian then
				b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
			end

			return string_char( b1, b2, b3, b4, b5, b6, b7, b8 ), nil
		end

		return nil, "unsupported byte count"
	end

	pack.writeFixedPoint = pack_writeFixedPoint

	--- [SHARED AND MENU]
	---
	--- Writes signed fixed-point number (**Qm.n**).
	---
	--- ### Commonly used Qm.n formats
	--- | Format | Range                          | Precision (Step)        |
	--- |:-------|:-------------------------------|:------------------------|
	--- | Q8.8   | `-128.0 to 127.996`            | 0.00390625 (1/256)      |
	--- | Q10.6  | `-512.0 to 511.984375`         | 0.015625 (1/64)         |
	--- | Q12.4  | `-2048.0 to 2047.9375`         | 0.0625 (1/16)           |
	--- | Q16.16 | `-32,768.0 to 32,767.99998`    | 0.0000152588 (1/65536)  |
	--- | Q24.8  | `-8,388,608.0 to 8,388,607.996`| 0.00390625 (1/256)      |
	--- | Q32.16 | `-2,147,483,648.0 to 2,147,483,647.99998` | 0.0000152588 (1/65536) |
	---
	---@param value number The signed fixed-point number.
	---@param m integer Number of integer bits (including sign bit).
	---@param n integer Number of fractional bits.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	function Writer:writeFixedPoint( value, m, n, big_endian )
		local binary_str, err_msg = pack_writeFixedPoint( value, m, n, big_endian )
		if binary_str == nil then
			error( err_msg, 2 )
		else
			self:write( binary_str )
		end
	end

end

-- float
do

	local bytepack_readFloat = bytepack.readFloat

	--- [SHARED AND MENU]
	---
	--- Reads signed 4-byte (32 bit) float from binary string.
	---
	---@param binary_str string The binary string.
	---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
	---@param start_position? integer The start position in binary string, default is `1`.
	---@return number | nil value The signed 4-byte float.
	---@return nil | string err_msg The error message.
	function pack.readFloat( binary_str, big_endian, start_position )
		if start_position == nil then
			start_position = 1
		end

		local b1, b2, b3, b4 = string_byte( binary_str, start_position, start_position + 3 )

		if b4 == nil then
			return nil, "not enough data"
		end

		if not big_endian then
			b1, b2, b3, b4 = b4, b3, b2, b1
		end

		return bytepack_readFloat( b1, b2, b3, b4 ), nil
	end

	--- [SHARED AND MENU]
	---
	--- Reads signed 4-byte (32 bit) float.
	---
	---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
	---@return number | nil value The signed 4-byte float.
	---@return nil | string err_msg The error message.
	function Reader:readFloat( big_endian )
		local start_position = self.position

		local available = self.data_length - start_position
		if available <= 0 then
			return nil, "end of file"
		elseif available < 4 then
			return nil, "not enough data"
		end

		start_position = start_position + 1

		local end_position = start_position + 3
		self.position = end_position

		local b1, b2, b3, b4 = string_byte( self.data, start_position, end_position )

		if b4 == nil then
			return nil, "not enough data"
		end

		if not big_endian then
			b1, b2, b3, b4 = b4, b3, b2, b1
		end

		return bytepack_readFloat( b1, b2, b3, b4 ), nil
	end

end

do

	local bytepack_writeFloat = bytepack.writeFloat

	--- [SHARED AND MENU]
	---
	--- Writes signed 4-byte (32 bit) float as binary string.
	---
	--- Allowable values from `1.175494351e-38` to `3.402823466e+38`.
	---
	---@param value number The signed 4-byte float.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string binary_str The binary string.
	local function pack_writeFloat( value, big_endian )
		local b1, b2, b3, b4 = bytepack_writeFloat( value )

		if not big_endian then
			b1, b2, b3, b4 = b4, b3, b2, b1
		end

		return string_char( b1, b2, b3, b4 )
	end

	pack.writeFloat = pack_writeFloat

	--- [SHARED AND MENU]
	---
	--- Writes signed 4-byte (32 bit) float.
	---
	--- Allowable values from `1.175494351e-38` to `3.402823466e+38`.
	---
	---@param value number The signed 4-byte float.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	function Writer:writeFloat( value, big_endian )
		self:write( pack_writeFloat( value, big_endian ) )
	end

end

-- double
do

	local bytepack_readDouble = bytepack.readDouble

	--- [SHARED AND MENU]
	---
	--- Reads signed 8-byte (64 bit) float (double) from binary string.
	---
	---@param binary_str string The binary string.
	---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
	---@param start_position? integer The start position in binary string, default is `1`.
	---@return number | nil value The double value.
	---@return nil | string err_msg The error message.
	function pack.readDouble( binary_str, big_endian, start_position )
		if start_position == nil then
			start_position = 1
		end

		local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( binary_str, start_position, start_position + 7 )

		if b8 == nil then
			return nil, "not enough data"
		end

		if not big_endian then
			b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
		end

		return bytepack_readDouble( b1, b2, b3, b4, b5, b6, b7, b8 )
	end

	--- [SHARED AND MENU]
	---
	--- Reads signed 8-byte (64 bit) float (double).
	---
	---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
	---@return number | nil value The double value.
	---@return nil | string err_msg The error message.
	function Reader:readDouble( big_endian )
		local start_position = self.position

		local available = self.data_length - start_position
		if available <= 0 then
			return nil, "end of file"
		elseif available < 8 then
			return nil, "not enough data"
		end

		start_position = start_position + 1

		local end_position = start_position + 7
		self.position = end_position

		local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( self.data, start_position, end_position )

		if b8 == nil then
			return nil, "not enough data"
		end

		if not big_endian then
			b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
		end

		return bytepack_readDouble( b1, b2, b3, b4, b5, b6, b7, b8 ), nil
	end

end

do

	local bytepack_writeDouble = bytepack.writeDouble

	--- [SHARED AND MENU]
	---
	--- Writes signed 8-byte (64 bit) float (double) as binary string.
	---
	---@param value number The signed 8-byte float.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string binary_str The binary string.
	local function pack_writeDouble( value, big_endian )
		local b1, b2, b3, b4, b5, b6, b7, b8 = bytepack_writeDouble( value )

		if not big_endian then
			b1, b2, b3, b4, b5, b6, b7, b8 = b8, b7, b6, b5, b4, b3, b2, b1
		end

		return string_char( b1, b2, b3, b4, b5, b6, b7, b8 )
	end

	pack.writeDouble = pack_writeDouble

	--- [SHARED AND MENU]
	---
	--- Writes signed 8-byte (64 bit) float (double).
	---
	---@param value number The signed 8-byte float.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	function Writer:writeDouble( value, big_endian )
		self:write( pack_writeDouble( value, big_endian ) )
	end

end

-- DOS date
do

	local bytepack_readDate = bytepack.readDate

	--- [SHARED AND MENU]
	---
	--- Reads DOS formatted date from binary string.
	---
	---@param binary_str string The string.
	---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
	---@param start_position? integer The start position in binary string, default is `1`.
	---@return integer | nil day The day.
	---@return integer | nil month The month.
	---@return integer | nil year The year.
	---@return nil | string err_msg The error message.
	function pack.readDate( binary_str, big_endian, start_position )
		if start_position == nil then
			start_position = 1
		end

		local b1, b2 = string_byte( binary_str, start_position, start_position + 1 )

		if b2 == nil then
			return nil, nil, nil, "not enough data"
		end

		if not big_endian then
			b1, b2 = b2, b1
		end

		return bytepack_readDate( b1, b2 )
	end

	--- [SHARED AND MENU]
	---
	--- Reads DOS formatted date.
	---
	---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
	---@return integer | nil day The day.
	---@return integer | nil month The month.
	---@return integer | nil year The year.
	---@return nil | string err_msg The error message.
	function Reader:readDate( big_endian )
		local start_position = self.position

		local available = self.data_length - start_position
		if available <= 0 then
			return nil, nil, nil, "end of file"
		elseif available < 2 then
			return nil, nil, nil, "not enough data"
		end

		start_position = start_position + 1

		local end_position = start_position + 1
		self.position = end_position

		local b1, b2 = string_byte( self.data, start_position, end_position )

		if b2 == nil then
			return nil, nil, nil, "not enough data"
		end

		if not big_endian then
			b1, b2 = b2, b1
		end

		return bytepack_readDate( b1, b2 )
	end

end

do

	local bytepack_writeDate = bytepack.writeDate

	--- [SHARED AND MENU]
	---
	--- Writes date in DOS format as binary string.
	---
	---@param day? integer The day.
	---@param month? integer The month.
	---@param year? integer The year.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string binary_str The binary string.
	local function pack_writeDate( day, month, year, big_endian )
		local b1, b2 = bytepack_writeDate( day, month, year )

		if not big_endian then
			b1, b2 = b2, b1
		end

		return string_char( b1, b2 )
	end

	pack.writeDate = pack_writeDate

	--- [SHARED AND MENU]
	---
	--- Writes date in DOS format.
	---
	---@param day? integer The day.
	---@param month? integer The month.
	---@param year? integer The year.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	function Writer:writeDate( day, month, year, big_endian )
		self:write( pack_writeDate( day, month, year, big_endian ) )
	end

end

-- time
do

	local bytepack_readTime = bytepack.readTime

	--- [SHARED AND MENU]
	---
	--- Reads DOS formatted time from binary string.
	---
	---@param binary_str string The binary string.
	---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
	---@param start_position? integer The start position in binary string, default is `1`.
	---@return integer | nil hours The number of hours.
	---@return integer | nil minutes The number of minutes.
	---@return integer | nil seconds The number of seconds, **will be rounded**.
	---@return nil | string err_msg The error message.
	function pack.readTime( binary_str, big_endian, start_position )
		if start_position == nil then
			start_position = 1
		end

		local b1, b2 = string_byte( binary_str, start_position, start_position + 1 )

		if b2 == nil then
			return nil, nil, nil, "not enough data"
		end

		if not big_endian then
			b1, b2 = b2, b1
		end

		return bytepack_readTime( b1, b2 )
	end

	--- [SHARED AND MENU]
	---
	--- Reads DOS formatted time.
	---
	---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
	---@return integer | nil hours The number of hours.
	---@return integer | nil minutes The number of minutes.
	---@return integer | nil seconds The number of seconds, **will be rounded**.
	---@return nil | string err_msg The error message.
	function Reader:readTime( big_endian )
		local start_position = self.position

		local available = self.data_length - start_position
		if available <= 0 then
			return nil, nil, nil, "end of file"
		elseif available < 2 then
			return nil, nil, nil, "not enough data"
		end

		start_position = start_position + 1

		local end_position = start_position + 1
		self.position = end_position

		local b1, b2 = string_byte( self.data, start_position, end_position )

		if b2 == nil then
			return nil, nil, nil, "not enough data"
		end

		if not big_endian then
			b1, b2 = b2, b1
		end

		return bytepack_readTime( b1, b2 )
	end

end

do

	local bytepack_writeTime = bytepack.writeTime

	--- [SHARED AND MENU]
	---
	--- Writes time in DOS format as binary string.
	---
	---@param hours? integer The number of hours.
	---@param minutes? integer The number of minutes.
	---@param seconds? integer The number of seconds, **will be rounded**.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string binary_str The binary string.
	local function pack_writeTime( hours, minutes, seconds, big_endian )
		local b1, b2 = bytepack_writeTime( hours, minutes, seconds )

		if not big_endian then
			b1, b2 = b2, b1
		end

		return string_char( b1, b2 )
	end

	pack.writeTime = pack_writeTime

	--- [SHARED AND MENU]
	---
	--- Writes time in DOS format.
	---
	---@param hours? integer The number of hours.
	---@param minutes? integer The number of minutes.
	---@param seconds? integer The number of seconds, **will be rounded**.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	function Writer:writeTime( hours, minutes, seconds, big_endian )
		self:write( pack_writeTime( hours, minutes, seconds, big_endian ) )
	end

end

--- [SHARED AND MENU]
---
--- Reads fixed-length string from binary string.
---
---@param binary_str string The binary string.
---@param length? integer The size of the string.
---@param start_position? integer The start position in binary string, default is `1`.
---@return string | nil str The fixed-length string.
---@return nil | string err_msg The error message.
local function pack_readFixedString( binary_str, length, start_position )
	if start_position == nil then
		start_position = 1
	end

	if ( string_len( binary_str ) - start_position ) < ( length - 1 ) then
		return nil, "not enough data"
	else
		return string_sub( binary_str, start_position, ( start_position - 1 ) + length ), nil
	end
end

pack.readFixedString = pack_readFixedString

--- [SHARED AND MENU]
---
--- Reads fixed-length string.
---
---@param length? integer The size of the string.
---@return string | nil str The fixed-length string.
---@return nil | string err_msg The error message.
function Reader:readFixedString( length )
	local start_position = self.position

	local available = self.data_length - start_position
	if available <= 0 then
		return nil, "end of file"
	elseif length > available then
		return nil, "not enough data"
	else
		return string_sub( self.data, start_position + 1, start_position + length ), nil
	end
end

--- [SHARED AND MENU]
---
--- Writes fixed-length string.
---
---@param str string The string to write.
---@param required_length? integer The size of the string, default is `255`.
---@return string str The fixed-length string.
local function pack_writeFixedString( str, required_length )
	if required_length == nil then
		required_length = 255
	end

	local real_length = string_len( str )

	if required_length == real_length then
		return str
	elseif required_length > real_length then
		return str .. string_rep( "\0", required_length - real_length )
	else
		return string_sub( str, 1, required_length )
	end
end

pack.writeFixedString = pack_writeFixedString

--- [SHARED AND MENU]
---
--- Writes fixed-length string.
---
---@param str string The string to write.
---@param required_length? integer The size of the string, default is `255`.
function Writer:writeFixedString( str, required_length )
	self:write( pack_writeFixedString( str, required_length ) )
end

--- [SHARED AND MENU]
---
--- Reads counted string from binary string.
---
---@param binary_str string The binary string.
---@param byte_count? integer The number of bytes to read for the length of the string, default is `1`.
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@param start_position? integer The start position in binary string, default is `1`.
---@return string | nil str The counted string.
---@return integer | nil str_length The length of the counted string.
---@return nil | string err_msg The error message.
function pack.readCountedString( binary_str, byte_count, big_endian, start_position )
	if byte_count == nil then
		byte_count = 1
	elseif byte_count == 0 then
		return "", 0
	end

	if start_position == nil then
		start_position = 1
	end

	local b1, b2, b3, b4, b5, b6, b7, b8 = string_byte( binary_str, start_position, start_position + byte_count )
	local length

	if byte_count == 1 then
		length = b1
	elseif big_endian then
		if byte_count == 2 then
			length = bytepack_readUInt16( b1, b2 )
		elseif byte_count == 3 then
			length = bytepack_readUInt24( b1, b2, b3 )
		elseif byte_count == 4 then
			length = bytepack_readUInt32( b1, b2, b3, b4 )
		elseif byte_count == 5 then
			length = bytepack_readUInt40( b1, b2, b3, b4, b5 )
		elseif byte_count == 6 then
			length = bytepack_readUInt48( b1, b2, b3, b4, b5, b6 )
		elseif byte_count == 7 then
			length = bytepack_readUInt56( b1, b2, b3, b4, b5, b6, b7 )
		else
			length = bytepack_readUInt64( b1, b2, b3, b4, b5, b6, b7, b8 )
		end
	elseif byte_count == 2 then
		length = bytepack_readUInt16( b2, b1 )
	elseif byte_count == 3 then
		length = bytepack_readUInt24( b3, b2, b1 )
	elseif byte_count == 4 then
		length = bytepack_readUInt32( b4, b3, b2, b1 )
	elseif byte_count == 5 then
		length = bytepack_readUInt40( b5, b4, b3, b2, b1 )
	elseif byte_count == 6 then
		length = bytepack_readUInt48( b6, b5, b4, b3, b2, b1 )
	elseif byte_count == 7 then
		length = bytepack_readUInt56( b7, b6, b5, b4, b3, b2, b1 )
	else
		length = bytepack_readUInt64( b8, b7, b6, b5, b4, b3, b2, b1 )
	end

	if length == 0 then
		return "", 0
	else
		return pack_readFixedString( binary_str, length, byte_count + ( start_position - 1 ) + 1 ), length
	end
end

--- [SHARED AND MENU]
---
--- Reads counted string from binary string.
---
---@param bit_count? integer The number of bits to read for the length of the string, default is `8`.
---@param big_endian? boolean `true` for big endian, `false` for little endian, default is `false`.
---@return string | nil str The counted string.
---@return integer | nil str_length The length of the counted string.
---@return nil | string err_msg The error message.
function Reader:readCountedString( bit_count, big_endian )
	local length, err_msg = self:readUInt( bit_count or 8, big_endian )
	if length == nil then
		return nil, nil, err_msg
	else
		return self:readFixedString( length ), length
	end
end

do

	--- [SHARED AND MENU]
	---
	--- Writes counted string as binary string.
	---
	---@param str string The counted string.
	---@param byte_count? integer The number of bytes to read.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	---@return string | nil binary_str The binary string.
	---@return integer | nil binary_str_length The length of the binary string.
	---@return nil | string err_msg The error message.
	local function pack_writeCountedString( str, byte_count, big_endian )
		if byte_count == nil then
			byte_count = 1
		elseif byte_count < 1 then
			return nil, nil, "invalid number of bytes"
		end

		local length = string_len( str )
		if length == 0 then
			return string_rep( "\0", byte_count ), byte_count
		elseif length > 2 ^ ( 8 * byte_count ) - 1 then
			return nil, nil, "string too long to pack in " .. byte_count .. " bytes."
		end

		local uint_str
		if byte_count == 1 then
			uint_str = string_char( length )
		elseif big_endian then
			if byte_count == 2 then
				uint_str = string_char( bytepack_writeUInt16( length ) )
			elseif byte_count == 3 then
				uint_str = string_char( bytepack_writeUInt24( length ) )
			elseif byte_count == 4 then
				uint_str = string_char( bytepack_writeUInt32( length ) )
			elseif byte_count == 5 then
				uint_str = string_char( bytepack_writeUInt40( length ) )
			elseif byte_count == 6 then
				uint_str = string_char( bytepack_writeUInt48( length ) )
			elseif byte_count == 7 then
				uint_str = string_char( bytepack_writeUInt56( length ) )
			else
				uint_str = string_char( bytepack_writeUInt64( length ) )
			end
		elseif byte_count == 2 then
			local b1, b2 = bytepack_writeUInt16( length )
			uint_str = string_char( b2, b1 )
		elseif byte_count == 3 then
			local b1, b2, b3 = bytepack_writeUInt24( length )
			uint_str = string_char( b3, b2, b1 )
		elseif byte_count == 4 then
			local b1, b2, b3, b4 = bytepack_writeUInt32( length )
			uint_str = string_char( b4, b3, b2, b1 )
		elseif byte_count == 5 then
			local b1, b2, b3, b4, b5 = bytepack_writeUInt40( length )
			uint_str = string_char( b5, b4, b3, b2, b1 )
		elseif byte_count == 6 then
			local b1, b2, b3, b4, b5, b6 = bytepack_writeUInt48( length )
			uint_str = string_char( b6, b5, b4, b3, b2, b1 )
		elseif byte_count == 7 then
			local b1, b2, b3, b4, b5, b6, b7 = bytepack_writeUInt56( length )
			uint_str = string_char( b7, b6, b5, b4, b3, b2, b1 )
		elseif byte_count == 8 then
			local b1, b2, b3, b4, b5, b6, b7, b8 = bytepack_writeUInt64( length )
			uint_str = string_char( b8, b7, b6, b5, b4, b3, b2, b1 )
		else
			return nil, nil, "unsupported number of bytes"
		end

		return uint_str .. pack_writeFixedString( str, length ), length + byte_count, nil
	end

	pack.writeCountedString = pack_writeCountedString

	--- [SHARED AND MENU]
	---
	--- Writes counted string.
	---
	---@param str string The counted string.
	---@param bit_count? integer The number of bits to read.
	---@param big_endian? boolean `true` for big endian, `false` for little endian.
	function Writer:writeCountedString( str, bit_count, big_endian )
		if bit_count == 0 then
			return
		elseif bit_count < 0 then
			error( "invalid number of bits", 2 )
		end

		local binary_str, _, err_msg = pack_writeCountedString( str, math_ceil( bit_count * 0.125 ), big_endian )
		if binary_str == nil then
			error( err_msg, 2 )
		else
			self:write( binary_str )
		end
	end

end

--- [SHARED AND MENU]
---
--- Reads null-terminated string from binary string.
---
---@param binary_str string The binary string.
---@param start_position? integer The start position in binary string, default is `1`.
---@return string result The null-terminated string.
---@return integer length The length of the null-terminated string.
function pack.readNullTerminatedString( binary_str, start_position )
	if start_position == nil then
		start_position = 1
	end

	local end_position = start_position

	while string_byte( binary_str, end_position ) ~= 0 do
		end_position = end_position + 1
	end

	if end_position == start_position then
		return "", 0
	else
		return string_sub( binary_str, start_position, end_position - 1 ), end_position - start_position
	end
end

--- [SHARED AND MENU]
---
--- Writes null-terminated string as binary string.
---
---@param str string The null-terminated string.
---@return string result The binary string.
function pack.writeNullTerminatedString( str )
	return str .. "\0"
end

-- TODO: Zip
