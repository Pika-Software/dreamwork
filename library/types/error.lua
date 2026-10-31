---@meta _

--- [SHARED AND MENU]
---
--- The base error object used throughout `dreamwork`.
---
--- An `Error` wraps a `debug.Stack` of call frames captured
--- at (or before) the point the error was raised, and provides helpers to
--- turn that stack into a human-readable string (`toString`/`__tostring`)
--- or print it directly to the console with colors (`display`).
---
---@class Error : Object
---@field __class ErrorClass
---@field stack debug.Stack | nil The captured call stack this error carries.
---@field message string | nil The error message to display. Defaults to `"unknown error"` if omitted.
---@field protected __message fun( self: Error, error_message: ( string | nil ) ): string
---@field protected __head fun( self: Error, frame: ( debug.StackLevel | nil ) )
---@field protected __frame fun( self: Error, frame: debug.StackLevel )
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
--- Captures the current call stack into this error, merging it into
--- whatever frames are already stored (see `debug.Stack:capture`).
---
---@param stack_level? integer  Levels to skip to reach the caller (same as before).
---@param head_skip? integer    Constant frames to drop from the innermost end (e.g. 1 for the bare `error` C frame).
---@param tail_skip? integer    Constant frames to drop from the outermost end (e.g. your xpcall/wrapper frames).
function __Error:capture(stack_level, head_skip, tail_skip) end

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
---@class ErrorClass : Error
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
---@class RuntimeErrorClass : RuntimeError
---@field __base RuntimeError
---@field __parent ErrorClass
---@overload fun( message: ( string | nil ) ): RuntimeError
RuntimeError = {}

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
---@class NotImplementedErrorClass : NotImplementedError
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

---@param top_frame debug.StackLevel | nil
---@protected
function __AsyncError:__head(top_frame) end

---@param frame debug.StackLevel
---@protected
function __AsyncError:__frame(frame) end

--- [SHARED AND MENU]
---
--- The class used to create new `AsyncError` instances.
---
---@class AsyncErrorClass : AsyncError
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
---@class TypeErrorClass : TypeError
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
---@class ValueErrorClass : ValueError
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
---@class EndOfFileErrorClass : EndOfFileError
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
---@class DecodeErrorClass : DecodeError
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
---@class EncodeErrorClass : EncodeError
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
---@class CompileErrorClass : CompileError
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
---@param is_writing? boolean
---@protected
function __AsyncFileSystemError:__init(error_id, is_writing) end

--- [SHARED AND MENU]
---
--- The class used to create new `AsyncFileSystemError` instances.
---
---@class AsyncFileSystemErrorClass : AsyncFileSystemError
---@field __base AsyncFileSystemError
---@field __parent ErrorClass
---@overload fun( error_id: integer, is_writing: ( boolean | nil ) ): AsyncFileSystemError
AsyncFileSystemError = {}
