---@meta _

---@class dreamwork.exceptions
local dreamwork_exceptions = {}

--- [SHARED AND MENU]
---
--- The base error object used throughout `dreamwork`.
---
--- An `Error` wraps a `dreamwork.exceptions.Stack` of call frames captured
--- at (or before) the point the error was raised, and provides helpers to
--- turn that stack into a human-readable string (`toString`/`__tostring`)
--- or print it directly to the console with colors (`display`).
---
---@class Error : Object
---@field __class ErrorClass
---@field stack dreamwork.exceptions.Stack | nil The captured call stack this error carries.
---@field message string | nil The error message to display. Defaults to `"unknown error"` if omitted.
---@field protected __message fun( self: Error, error_message: ( string | nil ) ): string
---@field protected __head fun( self: Error, frame: ( dreamwork.exceptions.StackLevel | nil ) )
---@field protected __frame fun( self: Error, frame: dreamwork.exceptions.StackLevel )
---@field protected __tail fun( self: Error )
---@operator concat( any ): string
local __Error = {}

---@param message string | nil
---@protected
function __Error:__init(message) end

---@return integer size
---@protected
function __Error:__len() end

---@return string
---@protected
function __Error:__tostring() end

---@return string
---@protected
function __Error:__represent() end

---@return string
---@protected
function __Error:__concat(other) end

--- [SHARED AND MENU]
---
--- Checks whether the error's stack has no captured frames.
---
---@return boolean is_empty Returns `true` if no frames have been captured, otherwise `false`.
---@nodiscard
function __Error:isEmpty() end

--- [SHARED AND MENU]
---
--- Removes all entries from the stack, leaving it empty.
---
function __Error:reset() end

--- [SHARED AND MENU]
---
--- Captures the call stack of the calling function into the error, replacing the previous one.
---
--- Hidden frames are left out, the same way `error` captures them.
---
---@param stack_level integer? The level of the first captured frame, `1` (the caller) by default.
function __Error:capture(stack_level) end

--- [SHARED AND MENU]
---
--- Prints the error and its captured call stack directly to the console
--- using `engine.consoleMessageColored`, with colored segments for the
--- realm, error type, message, source locations and function references.
---
--- This is a display-only counterpart to `toString`: it writes straight to
--- the console instead of building and returning a string.
---
function __Error:display() end

--- [SHARED AND MENU]
---
--- The class used to create new `Error` instances.
---
---@class ErrorClass : Error, Class
---@field __base Error
---@overload fun( message: ( string | nil ) ): Error
Error = {}

--- [SHARED AND MENU]
---
--- Returns whether the given value is an error.
---
---@param value any
---@return boolean is_error
---@nodiscard
function isError(value) end

--- [SHARED AND MENU]
---
--- An error raised for generic runtime failures that don't fall into
--- any more specific error category.
---
---@class RuntimeError : Error
---@field __class RuntimeErrorClass
---@field __parent Error
---@field message string | nil The error message to display.
local __RuntimeError = {}

--- [SHARED AND MENU]
---
--- The class used to create new `RuntimeError` instances.
---
---@class RuntimeErrorClass : RuntimeError, ErrorClass
---@field __base RuntimeError
---@field __parent ErrorClass
---@overload fun( message: ( string | nil ) ): RuntimeError
RuntimeError = {}

--- [SHARED AND MENU]
---
--- Converts any error value into an `Error` and captures its call stack if it has none yet.
---
--- Can be passed to `xpcall` directly as a message handler.
---
---@param error_value any The error value to convert.
---@param error_class ErrorClass? The class used to wrap values that are not errors, called with the message only. Defaults to `RuntimeError`.
---@return Error error_object
---@nodiscard
function toError(error_value, error_class) end

--- [SHARED AND MENU]
---
--- `xpcall` message handler for errors that are going to be rethrown.
---
--- Works like `toError`, but values that are neither errors nor strings
--- (signals like `ACTION_CANCEL`) are returned as is, so rethrowing them keeps their identity,
--- the same way `error` throws them.
---
---@param error_value any The error value to handle.
---@return Error | any error_object
---@nodiscard
function dreamwork_exceptions.catch(error_value) end

--- [SHARED AND MENU]
---
--- `xpcall` message handler that converts the error into an `Error`, displays it and returns it.
---
---@param error_value any The error value to handle.
---@return Error error_object
function dreamwork_exceptions.handler(error_value) end

--- [SHARED AND MENU]
---
--- Calls the function in protected mode, errors are displayed and do not propagate.
---
--- Same as `xpcall( fn, dreamwork.exceptions.handler, ... )`, use it for callbacks
--- whose errors must not break the caller (hooks, timers, network receivers, ...).
---
---@param fn function The function to call.
---@param ... any The arguments to pass to the function.
---@return boolean success `true` if the function did not raise an error.
---@return any ... The function results on success, the displayed `Error` otherwise.
function dreamwork_exceptions.call(fn, ...) end

--- [SHARED AND MENU]
---
--- Converts any error value into an error of this class, see `toError`.
---
--- Values that already are an `Error` are returned as is, keeping their own class.
---
---@param value any The error value to convert.
---@return Error error_object
---@nodiscard
function __Error:from(value) end

--- [SHARED AND MENU]
---
--- Calls the function in protected mode, converting a raised error into an `Error`.
---
--- Unlike `pcall`, the error value is always an `Error` with the call stack of the place it was raised,
--- signals like `ACTION_CANCEL` are converted too, use `xpcall` with `dreamwork.exceptions.catch` to keep them.
---
---@param fn function The function to call.
---@param ... any The arguments to pass to the function.
---@return boolean success `true` if the function did not raise an error.
---@return any ... The function results on success, the `Error` otherwise.
function try(fn, ...) end

--- [SHARED AND MENU]
---
--- Displays the error with its call stack without throwing it, the current code keeps running.
---
---@param value any? The error value to display.
---@param stack_level integer? The stack level the error is blamed on.
---@return Error error_object The displayed error.
function warn(value, stack_level) end

--- [SHARED AND MENU]
---
--- Throws an error with the specified message and level.
---
--- An `Error` that already has a call stack is rethrown as is; if it was captured in another
--- thread (e.g. inside a resumed coroutine) the frames leading here are added below it.
--- Call `Error:reset` before throwing the same object again to capture a fresh stack.
---
--- Values that are neither errors nor strings (signals like `ACTION_CANCEL`) are thrown as is
--- inside protected calls and coroutines, so they keep their identity.
---
---@param value any? The error value to throw.
---@param stack_level integer? The stack level to throw the error.
function error(value, stack_level) end

--- [SHARED AND MENU]
---
--- Throws an error with a formatted message, blamed on the caller of the function that calls `errorf`.
---
--- Use `error( string.format( fmt, ... ), stack_level )` to pick another level.
---
---@param fmt string The error message format.
---@param ... any The error message arguments to format/interpolate.
function errorf(fmt, ...) end

--- [SHARED AND MENU]
---
--- Throws an error if the value is `false` or `nil`, otherwise returns all its arguments, like `assert`.
---
--- The message can be:
--- * `nil`, which throws `"assertion failed!"`;
--- * a string, formatted with the remaining arguments when there are any;
--- * an `Error`, which is thrown as is;
--- * an error class, created with the string formatted from the remaining arguments.
---
--- ```lua
--- local file = assert( open( path ), "cannot open '%s'", path )
--- assert( size >= 0, ValueError, "size must be positive, got %d", size )
--- ```
---
---@generic T
---@param value T The value to check.
---@param message ( string | Error | ErrorClass )? The error message, error object or error class.
---@param ... any The message format arguments.
---@return T value
---@return any ...
function assert(value, message, ...) end

--- [SHARED AND MENU]
---
--- An error raised when a called feature, method, or function
--- has not been implemented yet.
---
---@class NotImplementedError : Error
---@field __class NotImplementedErrorClass
---@field __parent Error
---@field message string | nil The error message to display.
local __NotImplementedError = {}

---@param error_message string | nil
---@return string
---@protected
function __NotImplementedError:__message(error_message) end

--- [SHARED AND MENU]
---
--- The class used to create new `NotImplementedError` instances.
---
---@class NotImplementedErrorClass : NotImplementedError, ErrorClass
---@field __base NotImplementedError
---@field __parent ErrorClass
---@overload fun( message: ( string | nil ) ): NotImplementedError
NotImplementedError = {}

--- [SHARED AND MENU]
---
--- An error raised during asynchronous/coroutine execution, whose
--- traceback additionally reports the thread it occurred in.
---
---@class AsyncError : Error
---@field __class AsyncErrorClass
---@field __parent Error
---@field message string | nil The error message to display.
local __AsyncError = {}

--- [SHARED AND MENU]
---
--- The class used to create new `AsyncError` instances.
---
---@class AsyncErrorClass : AsyncError, ErrorClass
---@field __base AsyncError
---@field __parent ErrorClass
---@overload fun( message: ( string | nil ) ): AsyncError
AsyncError = {}

--- [SHARED AND MENU]
---
--- An error raised when a value does not match the type
--- expected by an operation, function argument, or field.
---
---@class TypeError : Error
---@field __class TypeErrorClass
---@field __parent Error
---@field index integer
---@field value any
---@field value_name string | nil
---@field function_name string | nil
---@field expected_type string The type that was expected.
---@field received_type string The type that was actually received.
local __TypeError = {}

---@param index integer
---@param value any
---@param value_name string | nil
---@param expected_type string
---@param function_name string
---@protected
function __TypeError:__init(index, value, expected_type, value_name, function_name) end

---@protected
function __TypeError:__head() end

---@return string
---@protected
function __TypeError:__message() end

--- [SHARED AND MENU]
---
--- The class used to create new `TypeError` instances.
---
---@class TypeErrorClass : TypeError, ErrorClass
---@field __base TypeError
---@field __parent ErrorClass
---@overload fun( index: integer, value: any, expected_type: string, value_name: ( string | nil ), function_name: ( string | nil ) ): TypeError
TypeError = {}

--- [SHARED AND MENU]
---
--- An error raised when a value has the correct type but is
--- otherwise invalid or out of the accepted range for an operation.
---
---@class ValueError : Error
---@field __class ValueErrorClass
---@field __parent Error
---@field message string | nil Optional explanation of why the value is invalid.
---@field value any The invalid value.
local __ValueError = {}

---@param value any
---@param message string | nil
---@protected
function __ValueError:__init(value, message) end

---@param error_message string | nil
---@return string
---@protected
function __ValueError:__message(error_message) end

--- [SHARED AND MENU]
---
--- The class used to create new `ValueError` instances.
---
---@class ValueErrorClass : ValueError, ErrorClass
---@field __base ValueError
---@field __parent ErrorClass
---@overload fun( value: any, message: ( string | nil ) ): ValueError
ValueError = {}

--- [SHARED AND MENU]
---
--- An error raised when a read operation unexpectedly reaches
--- the end of a stream, file, or buffer before completing.
---
---@class EndOfFileError : Error
---@field __class EndOfFileErrorClass
---@field __parent Error
---@field position integer | nil Byte offset at which EOF was hit.
---@field expected integer | nil Number of bytes that were expected to be read.
local __EndOfFileError = {}

---@param position integer | nil
---@param expected integer | nil
---@protected
function __EndOfFileError:__init(position, expected) end

---@return string
---@protected
function __EndOfFileError:__message() end

--- [SHARED AND MENU]
---
--- The class used to create new `EndOfFileError` instances.
---
---@class EndOfFileErrorClass : EndOfFileError, ErrorClass
---@field __base EndOfFileError
---@field __parent ErrorClass
---@overload fun( position: ( integer | nil ), expected: ( integer | nil ) ): EndOfFileError
EndOfFileError = {}

--- [SHARED AND MENU]
---
--- An error raised when encoded data (JSON, VDF, ...) cannot be decoded
--- because it is malformed.
---
---@class DecodeError : Error
---@field __class DecodeErrorClass
---@field __parent Error
---@field message string | nil The reason the data could not be decoded.
---@field position integer | nil Byte offset in the input where decoding failed.
local __DecodeError = {}

---@param message string | nil
---@param position integer | nil
---@protected
function __DecodeError:__init(message, position) end

---@param error_message string | nil
---@return string
---@protected
function __DecodeError:__message(error_message) end

--- [SHARED AND MENU]
---
--- The class used to create new `DecodeError` instances.
---
---@class DecodeErrorClass : DecodeError, ErrorClass
---@field __base DecodeError
---@field __parent ErrorClass
---@overload fun( message: ( string | nil ), position: ( integer | nil ) ): DecodeError
DecodeError = {}

--- [SHARED AND MENU]
---
--- An error raised when a value cannot be encoded into a data format
--- (JSON, VDF, ...) because the format cannot represent it.
---
---@class EncodeError : Error
---@field __class EncodeErrorClass
---@field __parent Error
---@field message string | nil The reason the value could not be encoded.
---@field value any The value that could not be encoded.
local __EncodeError = {}

---@param message string | nil
---@param value any
---@protected
function __EncodeError:__init(message, value) end

---@param error_message string | nil
---@return string
---@protected
function __EncodeError:__message(error_message) end

--- [SHARED AND MENU]
---
--- The class used to create new `EncodeError` instances.
---
---@class EncodeErrorClass : EncodeError, ErrorClass
---@field __base EncodeError
---@field __parent ErrorClass
---@overload fun( message: ( string | nil ), value: any ): EncodeError
EncodeError = {}

--- [SHARED AND MENU]
---
--- An error that occurs when the compiler encounters an issue.
---
---@class CompileError : Object
---@field __class CompileErrorClass
---@field __parent Error
local __CompileError = {}

--- [SHARED AND MENU]
---
--- The class used to create new `CompileError` instances.
---
---@class CompileErrorClass : CompileError, ErrorClass
---@field __base CompileError
---@field __parent ErrorClass
---@overload fun(): CompileError
CompileError = {}

--- [SHARED AND MENU]
---
--- An error raised when an asynchronous file system operation fails.
---
---@class AsyncFileSystemError : Error
---@field __class AsyncFileSystemErrorClass
---@field __parent Error
---@field message string | nil The error message to display.
---@field Messages table<integer, string> The error message lookup table.
local __AsyncFileSystemError = {}

---@type table<integer, string>
__AsyncFileSystemError.Messages = nil

---@param error_id integer
---@param is_writing boolean?
---@protected
function __AsyncFileSystemError:__init(error_id, is_writing) end

--- [SHARED AND MENU]
---
--- The class used to create new `AsyncFileSystemError` instances.
---
---@class AsyncFileSystemErrorClass : AsyncFileSystemError, ErrorClass
---@field __base AsyncFileSystemError
---@field __parent ErrorClass
---@overload fun( error_id: integer, is_writing: ( boolean | nil ) ): AsyncFileSystemError
AsyncFileSystemError = {}

--- [SHARED AND MENU]
---
--- An error raised when an HTTP request fails or its response has an unexpected status code.
---
--- `status` is `nil` when no response was received (connection, TLS, timeout, ...).
---
--- ```lua
--- HTTPError( 404, "https://example.com/a" ) -- "HTTP 404 Not Found - Resource not found (url: https://example.com/a)"
--- HTTPError( nil, "https://example.com/a", "Timeout was reached" ) -- "HTTP request failed: Timeout was reached (url: https://example.com/a)"
--- HTTPError.Messages[ 429 ] -- "Too Many Requests - Rate limit exceeded"
--- ```
---
---@class HTTPError : Error
---@field __class HTTPErrorClass
---@field __parent Error
---@field message string | nil The reason of the failure, or extra details about the status code.
---@field status integer | nil The response status code, `nil` if no response was received.
---@field url string | nil The URL of the request.
---@field Messages table<integer, string> The status code description lookup table.
local __HTTPError = {}

---@type table<integer, string>
__HTTPError.Messages = nil

---@param status integer | nil
---@param url string | nil
---@param message string | nil
---@protected
function __HTTPError:__init(status, url, message) end

---@param error_message string | nil
---@return string
---@protected
function __HTTPError:__message(error_message) end

--- [SHARED AND MENU]
---
--- The class used to create new `HTTPError` instances.
---
---@class HTTPErrorClass : HTTPError, ErrorClass
---@field __base HTTPError
---@field __parent ErrorClass
---@overload fun( status: ( integer | nil ), url: ( string | nil ), message: ( string | nil ) ): HTTPError
HTTPError = {}
