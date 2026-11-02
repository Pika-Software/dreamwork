local dreamwork_engine = dreamwork.engine

local engine_console = dreamwork_engine.console
local console_messageColored = engine_console.messageColored

---@class dreamwork.std
local std = dreamwork.std

local debug = std.debug
local debug_Stack = debug.Stack

local string = std.string
local string_format = string.format

local unicode = std.unicode

local time = std.time
local time_format = time.format

local color = std.color
local color_Scheme = color.Scheme

local class = std.class

local represent = std.represent
local tostring = std.tostring
local type = std.type
local is = std.is


local COLOR_WHITE_SMOKE = color_Scheme.white_smoke
local COLOR_SUVA_GRAY   = color_Scheme.suva_gray
local COLOR_SANDSTONE   = color_Scheme.sandstone
local COLOR_SPRAY       = color_Scheme.spray
local COLOR_MONA_LISA   = color_Scheme.mona_lisa
local COLOR_LIGHT_GRAY  = color_Scheme.light_gray
local COLOR_ERROR       = color_Scheme.error


--- [SHARED AND MENU]
---
--- The base error object used throughout `dreamwork`.
---
--- An `Error` wraps a `dreamwork.std.debug.Stack` of call frames captured
--- at (or before) the point the error was raised, and provides helpers to
--- turn that stack into a human-readable string (`toString`/`__tostring`)
--- or print it directly to the console with colors (`display`).
---
---@class dreamwork.std.Error : dreamwork.std.Object
---@field __class dreamwork.std.ErrorClass
---@field stack dreamwork.std.debug.Stack | nil The captured call stack this error carries.
---@field message string | nil The error message to display. Defaults to `"unknown error"` if omitted.
---@field protected __message fun( self: dreamwork.std.Error, error_message: ( string | nil ) ): string
---@field protected __head fun( self: dreamwork.std.Error, frame: ( dreamwork.std.debug.StackLevel | nil ) )
---@field protected __frame fun( self: dreamwork.std.Error, frame: dreamwork.std.debug.StackLevel )
---@field protected __tail fun( self: dreamwork.std.Error )
---@operator concat( any ): string
local Error = std.Error and std.Error.__base or class.base( "Error", false, nil )

---@param message string | nil
---@protected
function Error:__init( message )
    self.message = message
end

---@return integer size
---@protected
function Error:__len()
    local stack = self.stack
    if stack == nil then
        return 0
    end

    return stack.size
end

---@return string
---@protected
function Error:__tostring()
    local error_message = self.message

    local message_fn = self.__message
    if message_fn ~= nil then
        return message_fn( self, error_message )
    elseif error_message == nil then
        return "unknown error"
    end

    return error_message
end

---@return string
---@protected
function Error:__represent()
    return string_format( "%s: %p [%s]", type( self ), self, self.message )
end

---@return string
---@protected
function Error:__concat( other )
    return tostring( self ) .. tostring( other )
end

--- [SHARED AND MENU]
---
--- Checks whether the error's stack has no captured frames.
---
---@return boolean is_empty Returns `true` if no frames have been captured, otherwise `false`.
---@nodiscard
function Error:isEmpty()
    local stack = self.stack
    if stack == nil then
        return true
    end

    return stack.size == 0
end

--- [SHARED AND MENU]
---
--- Removes all entries from the stack, leaving it empty.
---
function Error:reset()
    self.stack = nil
end

--- [SHARED AND MENU]
---
--- Captures the current call stack into this error, merging it into
--- whatever frames are already stored (see `dreamwork.std.debug.Stack:capture`).
---
---@param stack_level? integer  Levels to skip to reach the caller (same as before).
---@param head_skip? integer    Constant frames to drop from the innermost end (e.g. 1 for the bare `error` C frame).
---@param tail_skip? integer    Constant frames to drop from the outermost end (e.g. your xpcall/wrapper frames).
function Error:capture( stack_level, head_skip, tail_skip )
    if stack_level == nil then
        stack_level = 2
    else
        stack_level = stack_level + 1
    end

    local stack = self.stack
    if stack == nil then
        stack = debug_Stack()
        self.stack = stack
    end

    stack:capture( stack_level, head_skip, tail_skip )
end

do

    local realm_name = unicode.capitalize( std.LUA_REALM )

    --- [SHARED AND MENU]
    ---
    --- Prints the error and its captured call stack directly to the console
    --- using `engine.consoleMessageColored`, with colored segments for the
    --- realm, error type, message, source locations and function references.
    ---
    --- This is a display-only counterpart to `toString`: it writes straight to
    --- the console instead of building and returning a string.
    ---
    function Error:display()
        console_messageColored( time_format( "\n┌> {day}-{month}-{year} - {hours}:{minutes}:{seconds}.{milliseconds}\n" ), COLOR_SUVA_GRAY )

        console_messageColored( "[", COLOR_WHITE_SMOKE )
        console_messageColored( realm_name, COLOR_ERROR )
        console_messageColored( "/", COLOR_SUVA_GRAY )
        console_messageColored( type( self ), COLOR_MONA_LISA )
        console_messageColored( "] ", COLOR_WHITE_SMOKE )

        console_messageColored( tostring( self ) .. "\n", COLOR_MONA_LISA )

        local stack = self.stack
        if stack == nil then
            local head_fn = self.__head
            if head_fn ~= nil then
                head_fn( self, nil )
            end

            return
        end

        local stack_size = stack.size

        local top_frame = stack:peek()
        if top_frame ~= nil then
            ---@type string | nil
            local file_path = top_frame.source

            ---@type function | nil
            local func = top_frame.func
            if func ~= nil and file_path == nil then
                file_path = debug.getfsource( func )
            end

            console_messageColored( "  thrown at ", COLOR_SUVA_GRAY )
            console_messageColored( file_path or "=[C]", COLOR_SANDSTONE )

            console_messageColored( ":", COLOR_SUVA_GRAY )

            console_messageColored( tostring( top_frame.currentline or -1 ), COLOR_SPRAY )
            console_messageColored( "\n", COLOR_SUVA_GRAY )

            -- TODO: Add error source, aka addon/package/folder in basic error throw info
            -- create std.File.get( path_to_file ).mount / `whereis` alternative

            -- console_messageColored( "  thrown by ", COLOR_SUVA_GRAY )
            -- console_messageColored( file_path or "=[C]", COLOR_SANDSTONE )
        end

        local head_fn = self.__head
        if head_fn ~= nil then
            head_fn( self, top_frame )
        end

        if stack_size > 0 then
            console_messageColored( "\n  call stack:\n", COLOR_SUVA_GRAY )
        end

        for index = 1, stack_size, 1 do
            console_messageColored( "  " .. index, COLOR_SANDSTONE )

            ---@type dreamwork.std.debug.StackLevel
            local frame = stack[ (stack_size - index) + 1 ]

            ---@type string | nil
            local name = frame.name

            ---@type string | nil
            local file_path = frame.source

            ---@type function | nil
            local func = frame.func
            if func ~= nil and file_path == nil then
                file_path = debug.getfsource( func )
            end

            console_messageColored( ". ", COLOR_SUVA_GRAY )

            if name == nil then
                console_messageColored( "<unknown>", COLOR_LIGHT_GRAY )
            else
                console_messageColored( name, COLOR_WHITE_SMOKE )
            end

            console_messageColored( " [", COLOR_SUVA_GRAY )

            if func == nil then
                console_messageColored( "=[C]", COLOR_SPRAY )
            else
                console_messageColored( tostring( func ), COLOR_SPRAY )
            end

            console_messageColored( "]:\n     file: ", COLOR_SUVA_GRAY )
            console_messageColored( file_path or "=[C]", COLOR_SANDSTONE )

            console_messageColored( ":", COLOR_SUVA_GRAY )
            console_messageColored( tostring( frame.currentline or -1 ) .. "\n", COLOR_SPRAY )

            local frame_fn = self.__frame
            if frame_fn ~= nil then
                frame_fn( self, frame )
            end
        end

        local tail_fn = self.__tail
        if tail_fn ~= nil then
            tail_fn( self )
        end

        console_messageColored( "\n", COLOR_WHITE_SMOKE )
    end

end

--- [SHARED AND MENU]
---
--- The class used to create new `Error` instances.
---
---@class dreamwork.std.ErrorClass : dreamwork.std.Error, dreamwork.std.Class
---@field __base dreamwork.std.Error
---@overload fun( message: ( string | nil ) ): dreamwork.std.Error
local ErrorClass = std.Error or class.create( Error )
std.Error = ErrorClass

--- [SHARED AND MENU]
---
--- Returns whether the given value is an error.
---
---@param value any
---@return boolean is_error
---@nodiscard
function std.isError( value )
    return is( value, ErrorClass )
end

--- [SHARED AND MENU]
---
--- An error raised for generic runtime failures that don't fall into
--- any more specific error category.
---
---@class dreamwork.std.RuntimeError : dreamwork.std.Error
---@field __class dreamwork.std.RuntimeErrorClass
---@field __parent dreamwork.std.Error
---@field message string | nil The error message to display.
local RuntimeError = class.base( "RuntimeError", false, ErrorClass )

--- [SHARED AND MENU]
---
--- The class used to create new `RuntimeError` instances.
---
---@class dreamwork.std.RuntimeErrorClass : dreamwork.std.RuntimeError, dreamwork.std.ErrorClass
---@field __base dreamwork.std.RuntimeError
---@field __parent dreamwork.std.ErrorClass
---@overload fun( message: ( string | nil ) ): dreamwork.std.RuntimeError
std.RuntimeError = class.create( RuntimeError )

--- [SHARED AND MENU]
---
--- An error raised when a called feature, method, or function
--- has not been implemented yet.
---
---@class dreamwork.std.NotImplementedError : dreamwork.std.Error
---@field __class dreamwork.std.NotImplementedErrorClass
---@field __parent dreamwork.std.Error
---@field message string | nil The error message to display.
local NotImplementedError = class.base( "NotImplementedError", false, ErrorClass )

---@param error_message string | nil
---@return string
---@protected
function NotImplementedError:__message( error_message )
    local stack = self.stack
    if stack ~= nil then
        local top_frame = stack:peek()
        if top_frame ~= nil then
            ---@type string | nil
            local name = top_frame.name
            if name ~= nil then
                if error_message == nil then
                    return string_format( "`%s` is not implemented.", name )
                end

                return string_format( "`%s` is not implemented, because %s.", name, error_message )
            end
        end
    end

    if error_message == nil then
        return "This feature is not implemented."
    end

    return string_format( "This feature is not implemented, because %s.", error_message )
end

--- [SHARED AND MENU]
---
--- The class used to create new `NotImplementedError` instances.
---
---@class dreamwork.std.NotImplementedErrorClass : dreamwork.std.NotImplementedError, dreamwork.std.ErrorClass
---@field __base dreamwork.std.NotImplementedError
---@field __parent dreamwork.std.ErrorClass
---@overload fun( message: ( string | nil ) ): dreamwork.std.NotImplementedError
std.NotImplementedError = class.create( NotImplementedError )

--- [SHARED AND MENU]
---
--- An error raised during asynchronous/coroutine execution, whose
--- traceback additionally reports the thread it occurred in.
---
---@class dreamwork.std.AsyncError : dreamwork.std.Error
---@field __class dreamwork.std.AsyncErrorClass
---@field __parent dreamwork.std.Error
---@field message string | nil The error message to display.
local AsyncError = class.base( "AsyncError", false, ErrorClass )

---@param top_frame dreamwork.std.debug.StackLevel | nil
---@protected
function AsyncError:__head( top_frame )
    console_messageColored( "         in ", COLOR_SUVA_GRAY )

    if top_frame ~= nil then
        local thread = top_frame.thread
        if thread ~= nil then
            console_messageColored( represent( top_frame.thread ) .. "\n", COLOR_SPRAY )
            return
        end
    end

    console_messageColored( "main\n", COLOR_LIGHT_GRAY )
end

---@param frame dreamwork.std.debug.StackLevel
---@protected
function AsyncError:__frame( frame )
    local thread = frame.thread
    if thread == nil then
        console_messageColored( "     thread: ", COLOR_SUVA_GRAY )
        console_messageColored( "main\n", COLOR_LIGHT_GRAY )
    else
        console_messageColored( "     thread: ", COLOR_SUVA_GRAY )
        console_messageColored( string_format( "%p\n", thread ), COLOR_SPRAY )
    end
end

--- [SHARED AND MENU]
---
--- The class used to create new `AsyncError` instances.
---
---@class dreamwork.std.AsyncErrorClass : dreamwork.std.AsyncError, dreamwork.std.ErrorClass
---@field __base dreamwork.std.AsyncError
---@field __parent dreamwork.std.ErrorClass
---@overload fun( message: ( string | nil ) ): dreamwork.std.AsyncError
std.AsyncError = class.create( AsyncError )

--- [SHARED AND MENU]
---
--- An error raised when a value does not match the type
--- expected by an operation, function argument, or field.
---
---@class dreamwork.std.TypeError : dreamwork.std.Error
---@field __class dreamwork.std.TypeErrorClass
---@field __parent dreamwork.std.Error
---@field index integer
---@field value any
---@field value_name string | nil
---@field function_name string | nil
---@field expected_type string The type that was expected.
---@field received_type string The type that was actually received.
local TypeError = class.base( "TypeError", false, ErrorClass )

---@param index integer
---@param value any
---@param value_name string | nil
---@param expected_type string
---@param function_name string
---@protected
function TypeError:__init( index, value, expected_type, value_name, function_name )
    self.index = index
    self.value = value
    self.expected_type = expected_type

    self.value_name = value_name
    self.function_name = function_name or "<unknown>"

    self.received_type = type( value )
end

---@protected
function TypeError:__head()
    console_messageColored( "  value info:\n", COLOR_SUVA_GRAY )

    console_messageColored( "    index: ", COLOR_SUVA_GRAY )
    console_messageColored( self.index .. "\n", COLOR_LIGHT_GRAY )

    console_messageColored( "    type: ", COLOR_SUVA_GRAY )
    console_messageColored( "\"" .. self.received_type .. "\"\n", COLOR_SANDSTONE )

    console_messageColored( "    name: ", COLOR_SUVA_GRAY )

    local value_name = self.value_name
    if value_name == nil then
        console_messageColored( "<unknown>\n", COLOR_LIGHT_GRAY )
    else
        console_messageColored( "\"" .. value_name .. "\"\n", COLOR_SANDSTONE )
    end

    console_messageColored( "    value: ", COLOR_SUVA_GRAY )
    console_messageColored( represent( self.value ) .. "\n", COLOR_SPRAY )
end

---@return string
---@protected
function TypeError:__message()
    return string_format(
        "bad argument #%d to `%s` (`%s` expected, got `%s`)",
        self.index or 0,
        self.function_name,
        self.expected_type,
        self.received_type
    )
end

--- [SHARED AND MENU]
---
--- The class used to create new `TypeError` instances.
---
---@class dreamwork.std.TypeErrorClass : dreamwork.std.TypeError, dreamwork.std.ErrorClass
---@field __base dreamwork.std.TypeError
---@field __parent dreamwork.std.ErrorClass
---@overload fun( index: integer, value: any, expected_type: string, value_name: ( string | nil ), function_name: ( string | nil ) ): dreamwork.std.TypeError
std.TypeError = class.create( TypeError )

--- [SHARED AND MENU]
---
--- An error raised when a value has the correct type but is
--- otherwise invalid or out of the accepted range for an operation.
---
---@class dreamwork.std.ValueError : dreamwork.std.Error
---@field __class dreamwork.std.ValueErrorClass
---@field __parent dreamwork.std.Error
---@field message string | nil Optional explanation of why the value is invalid.
---@field value any The invalid value.
local ValueError = class.base( "ValueError", false, ErrorClass )

---@param value any
---@param message string | nil
---@protected
function ValueError:__init( value, message )
    self.value = value
    Error.__init( self, message )
end

---@param error_message string | nil
---@return string
---@protected
function ValueError:__message( error_message )
    if self.value ~= nil then
        if error_message == nil then
            return string_format( "invalid value `%s`", represent( self.value ) )
        end

        return string_format( "invalid value `%s`: %s", represent( self.value ), error_message )
    end

    return "an invalid value was provided"
end

--- [SHARED AND MENU]
---
--- The class used to create new `ValueError` instances.
---
---@class dreamwork.std.ValueErrorClass : dreamwork.std.ValueError, dreamwork.std.ErrorClass
---@field __base dreamwork.std.ValueError
---@field __parent dreamwork.std.ErrorClass
---@overload fun( value: any, message: ( string | nil ) ): dreamwork.std.ValueError
std.ValueError = class.create( ValueError )

--- [SHARED AND MENU]
---
--- An error raised when a read operation unexpectedly reaches
--- the end of a stream, file, or buffer before completing.
---
---@class dreamwork.std.EndOfFileError : dreamwork.std.Error
---@field __class dreamwork.std.EndOfFileErrorClass
---@field __parent dreamwork.std.Error
---@field position integer | nil Byte offset at which EOF was hit.
---@field expected integer | nil Number of bytes that were expected to be read.
local EndOfFileError = class.base( "EndOfFileError", false, ErrorClass )

---@param position integer | nil
---@param expected integer | nil
---@protected
function EndOfFileError:__init( position, expected )
    self.position = position
    self.expected = expected
end

---@return string
---@protected
function EndOfFileError:__message()
    if self.position ~= nil and self.expected ~= nil then
        return string_format( "unexpected end of data at byte %d (expected %d more byte%s)",
            self.position, self.expected, self.expected == 1 and "" or "s" )
    elseif self.position ~= nil then
        return string_format( "unexpected end of data at byte %d", self.position )
    end

    return "unexpected end of data"
end

--- [SHARED AND MENU]
---
--- The class used to create new `EndOfFileError` instances.
---
---@class dreamwork.std.EndOfFileErrorClass : dreamwork.std.EndOfFileError, dreamwork.std.ErrorClass
---@field __base dreamwork.std.EndOfFileError
---@field __parent dreamwork.std.ErrorClass
---@overload fun( position: ( integer | nil ), expected: ( integer | nil ) ): dreamwork.std.EndOfFileError
std.EndOfFileError = class.create( EndOfFileError )

--- [SHARED AND MENU]
---
--- An error raised when encoded data (JSON, VDF, ...) cannot be decoded
--- because it is malformed.
---
---@class dreamwork.std.DecodeError : dreamwork.std.Error
---@field __class dreamwork.std.DecodeErrorClass
---@field __parent dreamwork.std.Error
---@field message string | nil The reason the data could not be decoded.
---@field position integer | nil Byte offset in the input where decoding failed.
local DecodeError = class.base( "DecodeError", false, ErrorClass )

---@param message string | nil
---@param position integer | nil
---@protected
function DecodeError:__init( message, position )
    self.message = message
    self.position = position
end

---@param error_message string | nil
---@return string
---@protected
function DecodeError:__message( error_message )
    if error_message == nil then
        error_message = "malformed data"
    end

    if self.position == nil then
        return error_message
    end

    return string_format( "%s at position %d", error_message, self.position )
end

--- [SHARED AND MENU]
---
--- The class used to create new `DecodeError` instances.
---
---@class dreamwork.std.DecodeErrorClass : dreamwork.std.DecodeError, dreamwork.std.ErrorClass
---@field __base dreamwork.std.DecodeError
---@field __parent dreamwork.std.ErrorClass
---@overload fun( message: ( string | nil ), position: ( integer | nil ) ): dreamwork.std.DecodeError
std.DecodeError = class.create( DecodeError )

--- [SHARED AND MENU]
---
--- An error raised when a value cannot be encoded into a data format
--- (JSON, VDF, ...) because the format cannot represent it.
---
---@class dreamwork.std.EncodeError : dreamwork.std.Error
---@field __class dreamwork.std.EncodeErrorClass
---@field __parent dreamwork.std.Error
---@field message string | nil The reason the value could not be encoded.
---@field value any The value that could not be encoded.
local EncodeError = class.base( "EncodeError", false, ErrorClass )

---@param message string | nil
---@param value any
---@protected
function EncodeError:__init( message, value )
    self.message = message
    self.value = value
end

---@param error_message string | nil
---@return string
---@protected
function EncodeError:__message( error_message )
    if error_message == nil then
        return string_format( "unable to encode `%s`", represent( self.value ) )
    end

    return error_message
end

--- [SHARED AND MENU]
---
--- The class used to create new `EncodeError` instances.
---
---@class dreamwork.std.EncodeErrorClass : dreamwork.std.EncodeError, dreamwork.std.ErrorClass
---@field __base dreamwork.std.EncodeError
---@field __parent dreamwork.std.ErrorClass
---@overload fun( message: ( string | nil ), value: any ): dreamwork.std.EncodeError
std.EncodeError = class.create( EncodeError )

--- [SHARED AND MENU]
---
--- An error that occurs when the compiler encounters an issue.
---
---@class dreamwork.std.CompileError : dreamwork.std.Object
---@field __class dreamwork.std.CompileErrorClass
---@field __parent dreamwork.std.Error
local CompileError = class.base( "CompileError" )

--- [SHARED AND MENU]
---
--- The class used to create new `CompileError` instances.
---
---@class dreamwork.std.CompileErrorClass : dreamwork.std.CompileError, dreamwork.std.ErrorClass
---@field __base dreamwork.std.CompileError
---@field __parent dreamwork.std.ErrorClass
---@overload fun(): dreamwork.std.CompileError
std.CompileError = class.create( CompileError )

-- TODO: CompileError, requires vfs to get file contents

--- [SHARED AND MENU]
---
--- An error raised when an asynchronous file system operation fails.
---
---@class dreamwork.std.AsyncFileSystemError : dreamwork.std.Error
---@field __class dreamwork.std.AsyncFileSystemErrorClass
---@field __parent dreamwork.std.Error
---@field message string | nil The error message to display.
---@field Messages table<integer, string> The error message lookup table.
local AsyncFileSystemError = class.base( "AsyncFileSystemError", false, ErrorClass )

do

    ---@type table<integer, string>
    local status_messages = {
        [ -16 ] = "failed, unknown error",
        [ -8 ]  = "failed, file name is not part of the file system; please try another one",
        [ -7 ]  = "failed, please retry later. (network problems, etc)",
        [ -6 ]  = "failed, read parameters are invalid for unbuffered I/O",
        [ -5 ]  = "failed, hard subsystem failure",
        [ -4 ]  = "failed, read error on file",
        [ -3 ]  = "failed, not enough memory",
        [ -2 ]  = "failed, identifier provided by caller is not recognized",
        [ -1 ]  = "failed, file could not be opened (bad path, not exist, etc)",
        [ 0 ]   = "was successfully completed",
        [ 1 ]   = "has been properly queued and awaiting for service",
        [ 2 ]   = "is being accessed",
        [ 3 ]   = "has been interrupted by caller",
        [ 4 ]   = "has not yet been queued"
    }

    AsyncFileSystemError.Messages = status_messages

    ---@param error_id integer
    ---@param is_writing? boolean
    ---@protected
    function AsyncFileSystemError:__init( error_id, is_writing )
        self.message = (is_writing and "writing " or "reading ") .. (status_messages[ error_id ] or status_messages[ -16 ])
    end

end

--- [SHARED AND MENU]
---
--- The class used to create new `AsyncFileSystemError` instances.
---
---@class dreamwork.std.AsyncFileSystemErrorClass : dreamwork.std.AsyncFileSystemError, dreamwork.std.ErrorClass
---@field __base dreamwork.std.AsyncFileSystemError
---@field __parent dreamwork.std.ErrorClass
---@overload fun( error_id: integer, is_writing: ( boolean | nil ) ): dreamwork.std.AsyncFileSystemError
std.AsyncFileSystemError = class.create( AsyncFileSystemError )

--- [SHARED AND MENU]
---
--- An error raised when an HTTP request fails or its response has an unexpected status code.
---
--- `status` is `nil` when no response was received (connection, TLS, timeout, ...).
---
--- ```lua
--- std.HTTPError( 404, "https://example.com/a" ) -- "HTTP 404 Not Found - Resource not found (url: https://example.com/a)"
--- std.HTTPError( nil, "https://example.com/a", "Timeout was reached" ) -- "HTTP request failed: Timeout was reached (url: https://example.com/a)"
--- std.HTTPError.Messages[ 429 ] -- "Too Many Requests - Rate limit exceeded"
--- ```
---
---@class dreamwork.std.HTTPError : dreamwork.std.Error
---@field __class dreamwork.std.HTTPErrorClass
---@field __parent dreamwork.std.Error
---@field message string | nil The reason of the failure, or extra details about the status code.
---@field status integer | nil The response status code, `nil` if no response was received.
---@field url string | nil The URL of the request.
---@field Messages table<integer, string> The status code description lookup table.
local HTTPError = class.base( "HTTPError", false, ErrorClass )

do

    ---@type table<integer, string>
    local status_messages = {
        [ 100 ] = "Continue - Request headers received, send the body",
        [ 101 ] = "Switching Protocols - Server is switching to the protocol from the Upgrade header",
        [ 102 ] = "Processing - Request received and is still being processed (WebDAV)",
        [ 103 ] = "Early Hints - Preload hints sent before the final response",

        [ 200 ] = "OK - Request succeeded",
        [ 201 ] = "Created - Resource successfully created",
        [ 202 ] = "Accepted - Request accepted but not completed",
        [ 203 ] = "Non-Authoritative Information - Metadata comes from a third party copy",
        [ 204 ] = "No Content - No content to send for this request",
        [ 205 ] = "Reset Content - Client should reset the document view",
        [ 206 ] = "Partial Content - Only part of the resource was returned",
        [ 207 ] = "Multi-Status - Multiple status codes in the body (WebDAV)",
        [ 208 ] = "Already Reported - Members were already listed in a previous reply (WebDAV)",
        [ 226 ] = "IM Used - Instance manipulations applied to the resource",

        [ 300 ] = "Multiple Choices - Multiple options available",
        [ 301 ] = "Moved Permanently - Resource has been permanently moved",
        [ 302 ] = "Found - Resource temporarily moved",
        [ 303 ] = "See Other - See another URI using GET",
        [ 304 ] = "Not Modified - Resource not modified since last request",
        [ 305 ] = "Use Proxy - Deprecated, resource must be accessed through a proxy",
        [ 307 ] = "Temporary Redirect - Resource temporarily moved, use original method",
        [ 308 ] = "Permanent Redirect - Resource moved permanently, use original method",

        [ 400 ] = "Bad Request - Malformed syntax or invalid request",
        [ 401 ] = "Unauthorized - Authentication required",
        [ 402 ] = "Payment Required - Payment is needed to access the resource",
        [ 403 ] = "Forbidden - Server understood the request but refuses to authorize it",
        [ 404 ] = "Not Found - Resource not found",
        [ 405 ] = "Method Not Allowed - HTTP method not allowed",
        [ 406 ] = "Not Acceptable - No acceptable representation available",
        [ 407 ] = "Proxy Authentication Required - Authentication with the proxy required",
        [ 408 ] = "Request Timeout - Client took too long",
        [ 409 ] = "Conflict - Request conflicts with current state",
        [ 410 ] = "Gone - Resource permanently unavailable",
        [ 411 ] = "Length Required - Content-Length header required",
        [ 412 ] = "Precondition Failed - Request preconditions not met",
        [ 413 ] = "Content Too Large - Request body exceeds the server limit",
        [ 414 ] = "URI Too Long - Request URI exceeds the server limit",
        [ 415 ] = "Unsupported Media Type - Content type not supported",
        [ 416 ] = "Range Not Satisfiable - Requested range is outside the resource",
        [ 417 ] = "Expectation Failed - Expect header cannot be met",
        [ 418 ] = "I'm a teapot - Server refuses to brew coffee with a teapot (RFC 2324)",
        [ 421 ] = "Misdirected Request - Server cannot respond for this host",
        [ 422 ] = "Unprocessable Content - Request is well-formed but has semantic errors",
        [ 423 ] = "Locked - Resource is locked (WebDAV)",
        [ 424 ] = "Failed Dependency - A previous request failed (WebDAV)",
        [ 425 ] = "Too Early - Request might be replayed",
        [ 426 ] = "Upgrade Required - Switch to another protocol",
        [ 428 ] = "Precondition Required - Request must be conditional",
        [ 429 ] = "Too Many Requests - Rate limit exceeded",
        [ 431 ] = "Request Header Fields Too Large - Headers exceed the server limit",
        [ 451 ] = "Unavailable For Legal Reasons - Resource blocked for legal reasons",

        [ 500 ] = "Internal Server Error - Generic server error",
        [ 501 ] = "Not Implemented - Server doesn't support requested feature",
        [ 502 ] = "Bad Gateway - Invalid response from upstream server",
        [ 503 ] = "Service Unavailable - Server temporarily overloaded or down",
        [ 504 ] = "Gateway Timeout - Upstream server failed to respond in time",
        [ 505 ] = "HTTP Version Not Supported - Unsupported HTTP version",
        [ 506 ] = "Variant Also Negotiates - Server content negotiation misconfigured",
        [ 507 ] = "Insufficient Storage - Server cannot store the representation (WebDAV)",
        [ 508 ] = "Loop Detected - Infinite loop detected while processing (WebDAV)",
        [ 510 ] = "Not Extended - Further extensions to the request are required",
        [ 511 ] = "Network Authentication Required - Authentication to access the network required"
    }

    HTTPError.Messages = status_messages

    ---@param status integer | nil
    ---@param url string | nil
    ---@param message string | nil
    ---@protected
    function HTTPError:__init( status, url, message )
        self.status = status
        self.url = url
        self.message = message
    end

    ---@param error_message string | nil
    ---@return string
    ---@protected
    function HTTPError:__message( error_message )
        ---@type string
        local message

        local status = self.status
        if status == nil then
            message = "HTTP request failed: " .. (error_message or "no response received")
        else
            message = string_format( "HTTP %d %s", status, status_messages[ status ] or "Unknown Status" )
            if error_message ~= nil then
                message = message .. ": " .. error_message
            end
        end

        local url = self.url
        if url == nil then
            return message
        end

        return string_format( "%s (url: %s)", message, url )
    end

end

--- [SHARED AND MENU]
---
--- The class used to create new `HTTPError` instances.
---
---@class dreamwork.std.HTTPErrorClass : dreamwork.std.HTTPError, dreamwork.std.ErrorClass
---@field __base dreamwork.std.HTTPError
---@field __parent dreamwork.std.ErrorClass
---@overload fun( status: ( integer | nil ), url: ( string | nil ), message: ( string | nil ) ): dreamwork.std.HTTPError
std.HTTPError = class.create( HTTPError )

-- TODO: Error hashing to decrease spam ( __hash? )
