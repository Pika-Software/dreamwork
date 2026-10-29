---@meta jit.util


--- [SHARED AND MENU]
---
--- The LuaJIT internal introspection library, used by `jit.v`, `jit.dump` and `jit.bc` modules.
---
--- Undocumented and not stable LuaJIT API, may change between LuaJIT versions.
---
local util = {}
jit.util = util

--- [SHARED AND MENU]
---
--- The trace number.
---
---@alias jit.trace integer

--- [SHARED AND MENU]
---
--- The information about a Lua function.
---
---@class jit.funcinfo.lua
local funcinfo = {
    --- The line where the function is defined.
    linedefined = 0,
    --- The line where the function definition ends.
    lastlinedefined = 0,
    --- The number of stack slots used by the function.
    stackslots = 0,
    --- The number of fixed parameters.
    params = 0,
    --- The number of bytecode instructions.
    bytecodes = 0,
    --- The number of GC constants (strings, tables, child prototypes, etc.).
    gcconsts = 0,
    --- The number of number constants.
    nconsts = 0,
    --- The number of upvalues.
    upvalues = 0,
    --- The line of the bytecode at the given `pc`, otherwise `linedefined`.
    currentline = 0,
    --- `true` if the function is vararg.
    isvararg = false,
    --- `true` if the function has child prototypes (nested functions).
    children = false,
    --- The source of the function, e.g. `"@lua/autorun/init.lua"`.
    source = "",
    --- The short location of the function, e.g. `"init.lua:10"`.
    loc = ""
}

--- [SHARED AND MENU]
---
--- The information about a C function.
---
---@class jit.funcinfo.c
---@field ffid integer | nil The fast function id, only present for builtin fast functions (e.g. `print`, `pairs`, `math.floor`).
local funcinfo2 = {
    --- The address of the C function.
    addr = 0,
    --- The number of upvalues.
    upvalues = 0,
}

--- [SHARED AND MENU]
---
--- Returns the information about the given function.
---
---@param func function The function to get the information about.
---@param pc? integer The bytecode position, affects `currentline` and `loc`.
---@return jit.funcinfo.c | jit.funcinfo.lua info The function information.
function util.funcinfo( func, pc ) end

--- [SHARED AND MENU]
---
--- Returns the bytecode instruction at the given position of the given Lua function.
---
---@param func function The Lua function.
---@param pc integer The bytecode position, starting from `0`.
---@return integer? ins The raw 32-bit bytecode instruction, `nil` if out of range.
---@return integer? m The opcode mode flags of the instruction.
function util.funcbc( func, pc ) end

--- [SHARED AND MENU]
---
--- Returns the constant at the given index of the given Lua function.
---
--- Non-negative indices are for number constants, negative indices are for GC constants.
---
---@param func function The Lua function.
---@param idx integer The index of the constant.
---@return any? k The constant value, `nil` if out of range.
function util.funck( func, idx ) end

--- [SHARED AND MENU]
---
--- Returns the name of the upvalue at the given index of the given function.
---
---@param func function The function.
---@param idx integer The index of the upvalue, starting from `0`.
---@return string? name The name of the upvalue, `nil` if out of range.
function util.funcuvname( func, idx ) end

--- [SHARED AND MENU]
---
--- The information about a trace.
---
---@class jit.traceinfo
---@field linktype "none" | "root" | "loop" | "tail-recursion" | "up-recursion" | "down-recursion" | "interpreter" | "return" | "stitch" The type of the trace link.
local traceinfo = {
    --- The number of IR instructions.
    nins = 0,
    --- The number of IR constants (negative).
    nk = 0,
    --- The number of the linked trace, `0` if none.
    link = 0,
    --- The number of exits.
    nexit = 0
}

--- [SHARED AND MENU]
---
--- Returns the information about the given trace.
---
---@param tr jit.trace The trace number.
---@return jit.traceinfo? info The trace information, `nil` if the trace does not exist.
function util.traceinfo( tr ) end

--- [SHARED AND MENU]
---
--- Returns the IR instruction at the given reference of the given trace.
---
---@param tr jit.trace The trace number.
---@param ref integer The IR instruction reference.
---@return integer? m The IR mode flags of the instruction, `nil` if out of range.
---@return integer? ot The opcode and type of the instruction.
---@return integer? op1 The first operand.
---@return integer? op2 The second operand.
---@return integer? prev The previous instruction in the chain.
function util.traceir( tr, ref ) end

--- [SHARED AND MENU]
---
--- Returns the IR constant at the given index of the given trace.
---
---@param tr jit.trace The trace number.
---@param idx integer The IR constant reference.
---@return any? k The constant value, `nil` if out of range.
---@return integer? t The IR type of the constant.
---@return integer? slot The stack slot, only for `KSLOT` constants.
function util.tracek( tr, idx ) end

--- [SHARED AND MENU]
---
--- The snapshot of a trace.
---
--- `[0]` is the IR reference, `[1]` is the number of slots, the rest are the snapshot map entries.
---
---@class jit.snap : integer[]

--- [SHARED AND MENU]
---
--- Returns the snapshot at the given index of the given trace.
---
---@param tr jit.trace The trace number.
---@param sn integer The snapshot index, starting from `0`.
---@return jit.snap? snap The snapshot, `nil` if out of range.
function util.tracesnap( tr, sn ) end

--- [SHARED AND MENU]
---
--- Returns the machine code of the given trace.
---
---@param tr jit.trace The trace number.
---@return string? mcode The machine code, `nil` if the trace does not exist.
---@return integer? addr The address of the machine code.
---@return integer? loop The offset of the loop start in the machine code.
function util.tracemc( tr ) end

--- [SHARED AND MENU]
---
--- Returns the address of the exit stub for the given exit number.
---
---@overload fun( exitno: integer ): integer?
---@param tr jit.trace The trace number.
---@param exitno integer The exit number.
---@return integer? addr The address of the exit stub, `nil` if out of range.
function util.traceexitstub( tr, exitno ) end

--- [SHARED AND MENU]
---
--- Returns the address of the IR call target at the given index.
---
---@param idx integer The IR call index.
---@return integer? addr The address of the call target, `nil` if out of range.
function util.ircalladdr( idx ) end

return util
