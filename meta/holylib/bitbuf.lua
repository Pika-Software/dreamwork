---@meta holylib.bitbuf


--- [SHARED AND MENU]
---
--- This library adds the `bf_read` and `bf_write` classes.
---
--- Supports: Linux32 | Linux64 | Windows32 | Windows64
---
---@class holylib.bitbuf
bitbuf = {}

--- [SHARED AND MENU]
---
--- Copies the given buffer into a new one.
--- Useful if you want to save the data received by a client.
---
--- > **NOTE**: The size is clamped internally between a minimum of `4` bytes and a maximum of `262144` bytes.
---
---@param buffer holylib.bf_read
---@return holylib.bf_read result
function bitbuf.CopyReadBuffer( buffer ) end

--- [SHARED AND MENU]
---
--- Creates a read buffer from the given data.
--- Useful if you want to read the userdata of the instancebaseline stringtable.
---
--- > **NOTE**: The size is clamped internally between a minimum of `4` bytes and a maximum of `262144` bytes.
---
---@param data string
---@return holylib.bf_read result
function bitbuf.CreateReadBuffer( data ) end

--- [SHARED AND MENU]
---
--- Create a write buffer with the given size or with the given data.
---
--- > **NOTE**: The size is clamped internally between a minimum of `4` bytes and a maximum of `262144` bytes.
---
---@param sizeOrData integer | string
---@return holylib.bf_write result
function bitbuf.CreateWriteBuffer( sizeOrData ) end

--- [SHARED AND MENU]
---
--- Creates a read buffer from the given data allocated on the stack making it faster.
--- Useful if you want to read the userdata of the instancebaseline stringtable.
---
--- > **WARNING**: The buffer will be stack allocated, do NOT call this function recursively and the buffer is **only** valid inside the callback function.
--- > This is because you could cause a crash if you were to create too many stack allocated buffers!
---
--- > **NOTE**: The size is clamped internally between a minimum of `4` bytes and a maximum of `65536` bytes on Linux and to `8192` on Windows.
---
---@param data string
---@param callback fun( buffer: holylib.bf_read )
---@return holylib.bf_read result
function bitbuf.CreateStackReadBuffer( data, callback ) end

--- [SHARED AND MENU]
---
--- Create a write buffer with the given size or with the given data allocated on the stack making it faster.
---
--- > **WARNING**: The buffer will be stack allocated, do NOT call this function recursively and the buffer is **only** valid inside the callback function.
--- > This is because you could cause a crash if you were to create too many stack allocated buffers!
---
--- > **NOTE**: The size is clamped internally between a minimum of `4` bytes and a maximum of `65536` bytes on Linux and to `8192` on Windows.
---
---@param sizeOrData integer | string
---@param callback fun( buffer: holylib.bf_write )
---@return holylib.bf_write result
function bitbuf.CreateStackWriteBuffer( sizeOrData, callback ) end

--- [SHARED AND MENU]
---
--- A bit buffer that data can be read from.
--- It will later be used to read net messages from HLTV clients.
---
---@class holylib.bf_read
local bf_read = {}

--- [SHARED AND MENU]
---
--- Returns the a formatted string.
--- Format: `bf_read [%i]`
--- `%i` -> size of data in bits.
---
---@return string result
function bf_read:__tostring() end

--- [SHARED AND MENU]
---
--- Deletes the buffer internally.
function bf_read:__gc() end

--- [SHARED AND MENU]
---
--- Internally implemented and will set the values into the lua table.
---
---@param key string
---@param value any
function bf_read:__newindex( key, value ) end

--- [SHARED AND MENU]
---
--- Internally searches first in the metatable table for the key.
--- If it fails to find it, it will search in the lua table before returning.
--- If you try to get multiple values from the lua table, just use `bf_read:GetTable()`.
---
---@param key string
---@return any result
function bf_read:__index( key ) end

--- [SHARED AND MENU]
---
--- Returns the lua table of this object.
--- You can store variables into it.
---
---@return table result
function bf_read:GetTable() end

--- [SHARED AND MENU]
---
--- Returns the number of bits left.
---
---@return integer result
function bf_read:GetNumBitsLeft() end

--- [SHARED AND MENU]
---
--- Returns the number of bits read.
---
---@return integer result
function bf_read:GetNumBitsRead() end

--- [SHARED AND MENU]
---
--- Returns the size of the data in bits.
---
---@return integer result
function bf_read:GetNumBits() end

--- [SHARED AND MENU]
---
--- Returns the number of bytes left.
---
---@return integer result
function bf_read:GetNumBytesLeft() end

--- [SHARED AND MENU]
---
--- Returns the number of bytes read.
---
---@return integer result
function bf_read:GetNumBytesRead() end

--- [SHARED AND MENU]
---
--- Returns the size of the data in bytes.
---
---@return integer result
function bf_read:GetNumBytes() end

--- [SHARED AND MENU]
---
--- Returns the current position/bit.
---
---@return integer result
function bf_read:GetCurrentBit() end

--- [SHARED AND MENU]
---
--- Returns `true` if the buffer is overflowed.
---
---@return boolean result
function bf_read:IsOverflowed() end

--- [SHARED AND MENU]
---
--- Peeks the given number of bits (doesn't change the current position) and returns the value.
---
---@param bits integer
---@return integer result
function bf_read:PeekUBitLong( bits ) end

--- [SHARED AND MENU]
---
--- Reads an angle encoded with the given number of bits.
---
---@param bits integer
---@return number result
function bf_read:ReadBitAngle( bits ) end

--- [SHARED AND MENU]
---
--- Reads and Angle.
---
---@return garrysmod.Angle result
function bf_read:ReadBitAngles() end

--- [SHARED AND MENU]
---
--- > **NOTE**: This is only available for the 32x!
---
---@return number result
function bf_read:ReadBitCoord() end

--- [SHARED AND MENU]
---
--- > **NOTE**: This is only available for the 32x!
---
---@return integer result
function bf_read:ReadBitCoordBits() end

--- [SHARED AND MENU]
---
--- > **NOTE**: This is only available for the 32x!
---
---@param integral boolean? Defaults to `false`.
---@param lowPrecision boolean? Defaults to `false`.
---@return number result
function bf_read:ReadBitCoordMP( integral, lowPrecision ) end

--- [SHARED AND MENU]
---
--- > **NOTE**: This is only available for the 32x!
---
---@param integral boolean? Defaults to `false`.
---@param lowPrecision boolean? Defaults to `false`.
---@return integer result
function bf_read:ReadBitCoordMPBits( integral, lowPrecision ) end

--- [SHARED AND MENU]
---
---@return number result
function bf_read:ReadBitFloat() end

--- [SHARED AND MENU]
---
--- Reads a number with the given number of bits.
---
--- > **NOTE**: This is only available for the 32x!
---
---@param bits integer
---@param signed boolean? Defaults to `false`.
---@return integer result
function bf_read:ReadBitLong( bits, signed ) end

--- [SHARED AND MENU]
---
---@return number result
function bf_read:ReadBitNormal() end

--- [SHARED AND MENU]
---
--- Reads the given number of bits.
---
---@param bits integer
---@return string result
function bf_read:ReadBits( bits ) end

--- [SHARED AND MENU]
---
--- Reads a Vector.
---
---@return garrysmod.Vector result
function bf_read:ReadBitVec3Coord() end

--- [SHARED AND MENU]
---
--- Reads a normalizted Vector.
---
---@return garrysmod.Vector result
function bf_read:ReadBitVec3Normal() end

--- [SHARED AND MENU]
---
--- Reads a byte.
---
---@return integer result
function bf_read:ReadByte() end

--- [SHARED AND MENU]
---
--- Reads the given number of bytes.
---
---@param bytes integer
---@return string result
function bf_read:ReadBytes( bytes ) end

--- [SHARED AND MENU]
---
--- Reads a char.
---
---@return integer result
function bf_read:ReadChar() end

--- [SHARED AND MENU]
---
--- Reads a float.
---
---@return number result
function bf_read:ReadFloat() end

--- [SHARED AND MENU]
---
--- Reads a long.
---
---@return integer result
function bf_read:ReadLong() end

--- [SHARED AND MENU]
---
--- Reads a long long.
---
---@return string result
function bf_read:ReadLongLong() end

--- [SHARED AND MENU]
---
--- Reads one bit.
---
---@return boolean result
function bf_read:ReadOneBit() end

--- [SHARED AND MENU]
---
--- Reads a number with the given amount of bits.
---
---@param bits integer
---@return integer result
function bf_read:ReadSBitLong( bits ) end

--- [SHARED AND MENU]
---
--- Reads a short.
---
---@return integer result
function bf_read:ReadShort() end

--- [SHARED AND MENU]
---
---@return integer result
function bf_read:ReadSignedVarInt32() end

--- [SHARED AND MENU]
---
---@return integer result
function bf_read:ReadSignedVarInt64() end

--- [SHARED AND MENU]
---
--- Reads a null terminated string.
---
---@return string result
function bf_read:ReadString() end

--- [SHARED AND MENU]
---
--- Read a number with the given amount of bits.
---
---@param bits integer
---@return integer result
function bf_read:ReadUBitLong( bits ) end

--- [SHARED AND MENU]
---
---@return integer result
function bf_read:ReadUBitVar() end

--- [SHARED AND MENU]
---
---@return integer result
function bf_read:ReadVarInt32() end

--- [SHARED AND MENU]
---
---@return integer result
function bf_read:ReadVarInt64() end

--- [SHARED AND MENU]
---
---@return integer result
function bf_read:ReadWord() end

--- [SHARED AND MENU]
---
--- Resets the current position and resets the overflow flag.
function bf_read:Reset() end

--- [SHARED AND MENU]
---
--- Sets the current position to the given position.
--- Returns `true` on success.
---
---@param pos integer
---@return boolean result
function bf_read:Seek( pos ) end

--- [SHARED AND MENU]
---
--- Sets the current position to the given position relative to the current position.
--- Basically `newPosition = currentPosition + iPos`
--- Returns `true` on success.
---
---@param pos integer
---@return boolean result
function bf_read:SeekRelative( pos ) end

--- [SHARED AND MENU]
---
--- A bit buffer that data can be written to.
---
---@class holylib.bf_write
local bf_write = {}

--- [SHARED AND MENU]
---
--- Returns the a formatted string.
--- Format: `bf_write [%i]`
--- `%i` -> size of data in bits.
---
---@return string result
function bf_write:__tostring() end

--- [SHARED AND MENU]
---
--- Deletes the buffer internally.
function bf_write:__gc() end

--- [SHARED AND MENU]
---
--- Internally implemented and will set the values into the lua table.
---
---@param key string
---@param value any
function bf_write:__newindex( key, value ) end

--- [SHARED AND MENU]
---
--- Internally searches first in the metatable table for the key.
--- If it fails to find it, it will search in the lua table before returning.
--- If you try to get multiple values from the lua table, just use `bf_write:GetTable()`.
---
---@param key string
---@return any result
function bf_write:__index( key ) end

--- [SHARED AND MENU]
---
--- Returns the lua table of this object.
--- You can store variables into it.
---
---@return table result
function bf_write:GetTable() end

--- [SHARED AND MENU]
---
--- returns `true` if the buffer is still valid.
---
---@return boolean result
function bf_write:IsValid() end

--- [SHARED AND MENU]
---
--- Returns the written data.
---
---@return string result
function bf_write:GetData() end

--- [SHARED AND MENU]
---
--- Returns the number of bytes written.
---
---@return integer result
function bf_write:GetNumBytesWritten() end

--- [SHARED AND MENU]
---
--- Returns the number of bytes that are unwritten.
---
---@return integer result
function bf_write:GetNumBytesLeft() end

--- [SHARED AND MENU]
---
--- Returns the number of bits written.
---
---@return integer result
function bf_write:GetNumBitsWritten() end

--- [SHARED AND MENU]
---
--- Returns the number of bits left.
---
---@return integer result
function bf_write:GetNumBitsLeft() end

--- [SHARED AND MENU]
---
--- Returns the maximum number of bits that can be written.
---
---@return integer result
function bf_write:GetMaxNumBits() end

--- [SHARED AND MENU]
---
--- Returns `true` if the buffer is overflowed.
---
---@return boolean result
function bf_write:IsOverflowed() end

--- [SHARED AND MENU]
---
--- Resets the buffer.
function bf_write:Reset() end

--- [SHARED AND MENU]
---
--- Returns the debug name.
---
---@return string result
function bf_write:GetDebugName() end

--- [SHARED AND MENU]
---
--- Sets the debug name.
---
--- > **WARNING**: You should keep a reference to the string.
--- > If the GC removes the string, you will experience that GetDebugName will return junk!
---
---@param debugName string
function bf_write:SetDebugName( debugName ) end

--- [SHARED AND MENU]
---
--- Seeks to the given bit.
---
---@param bit integer
function bf_write:SeekToBit( bit ) end

--- [SHARED AND MENU]
---
--- Writes a float.
---
---@param value integer
function bf_write:WriteFloat( value ) end

--- [SHARED AND MENU]
---
--- Writes a char.
---
---@param value integer
function bf_write:WriteChar( value ) end

--- [SHARED AND MENU]
---
--- Writes a byte.
---
---@param value integer
function bf_write:WriteByte( value ) end

--- [SHARED AND MENU]
---
--- Writes a long.
---
---@param value integer
function bf_write:WriteLong( value ) end

--- [SHARED AND MENU]
---
--- Writes a long long.
---
---@param value integer | string
function bf_write:WriteLongLong( value ) end

--- [SHARED AND MENU]
---
--- Writes the given bytes.
---
---@param data string
function bf_write:WriteBytes( data ) end

--- [SHARED AND MENU]
---
--- Writes one bit.
---
---@param value boolean? Defaults to `false`.
function bf_write:WriteOneBit( value ) end

--- [SHARED AND MENU]
---
--- Sets the given bit to the given value.
---
---@param bit integer
---@param value boolean? Defaults to `false`.
function bf_write:WriteOneBitAt( bit, value ) end

--- [SHARED AND MENU]
---
--- Writes a short.
---
---@param value integer
function bf_write:WriteShort( value ) end

--- [SHARED AND MENU]
---
--- Writes a word.
---
---@param value integer
function bf_write:WriteWord( value ) end

--- [SHARED AND MENU]
---
---@param value integer
function bf_write:WriteSignedVarInt32( value ) end

--- [SHARED AND MENU]
---
---@param value integer
function bf_write:WriteSignedVarInt64( value ) end

--- [SHARED AND MENU]
---
---@param value integer
function bf_write:WriteVarInt32( value ) end

--- [SHARED AND MENU]
---
---@param value integer
function bf_write:WriteVarInt64( value ) end

--- [SHARED AND MENU]
---
---@param value integer
function bf_write:WriteUBitVar( value ) end

--- [SHARED AND MENU]
---
---@param value integer
---@param bits integer
---@param signed boolean? Defaults to `false`.
function bf_write:WriteUBitLong( value, bits, signed ) end

--- [SHARED AND MENU]
---
---@param value integer
---@param bits integer
function bf_write:WriteBitAngle( value, bits ) end

--- [SHARED AND MENU]
---
--- Writes a Angle. (`QAngle` internally).
---
---@param ang garrysmod.Angle
function bf_write:WriteBitAngles( ang ) end

--- [SHARED AND MENU]
---
--- Writes a Vector.
---
---@param vec garrysmod.Vector
function bf_write:WriteBitVec3Coord( vec ) end

--- [SHARED AND MENU]
---
--- Writes a normalized Vector
---
---@param vec garrysmod.Vector
function bf_write:WriteBitVec3Normal( vec ) end

--- [SHARED AND MENU]
---
--- Writes the given number of bits from the data into this buffer.
--- Returns `true` on success.
---
---@param data string
---@param bits integer
---@return boolean result
function bf_write:WriteBits( data, bits ) end

--- [SHARED AND MENU]
---
--- Writes the given number of bits from the given buffer into this buffer.
--- Returns `true` on success.
---
--- > **NOTE**: The current position for the given buffer will change as we internally read from it!
---
---@param buffer holylib.bf_read
---@param bits integer
---@return boolean result
function bf_write:WriteBitsFromBuffer( buffer, bits ) end

--- [SHARED AND MENU]
---
---@param value integer
function bf_write:WriteBitNormal( value ) end

--- [SHARED AND MENU]
---
---@param value integer
function bf_write:WriteBitLong( value ) end

--- [SHARED AND MENU]
---
---@param value integer
function bf_write:WriteBitFloat( value ) end

--- [SHARED AND MENU]
---
---@param value integer
function bf_write:WriteBitCoord( value ) end

--- [SHARED AND MENU]
---
---@param value integer
---@param integral boolean? Defaults to `false`.
---@param lowPrecision boolean? Defaults to `false`.
function bf_write:WriteBitCoordMP( value, integral, lowPrecision ) end

--- [SHARED AND MENU]
---
--- Writes a null terminated string
---
---@param value string
function bf_write:WriteString( value ) end
