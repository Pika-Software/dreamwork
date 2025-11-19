---@class dreamwork.std
local std = _G.dreamwork.std

local debug = std.debug
local table = std.table

---@alias dreamwork.std.Hook.Type
---| `-2` # PRE_HOOK - This hook is guaranteed to be called under all circumstances, and cannot be interrupted by a return statement. You can rely on its consistent execution.
---| `-1` # PRE_HOOK_RETURN - Consider a scenario where you have an admin mod that checks for "!menu". In this case, your hook might not be called before it.
---| `0`  # NORMAL_HOOK - This hook is called after the normal hook, but before the post hook.
---| `1`  # POST_HOOK_RETURN - This allows for the modification of results returned from preceding hooks!
---| `2`  # POST_HOOK - This hook is guaranteed to be called under all circumstances, and cannot be interrupted by a return statement. You can rely on its consistent execution.

---@class dreamwork.std.Hook.query_data
---@field [1] boolean `true` to attach, `false` to detach.
---@field [2] any The identifier of the callback.
---@field [3] nil | dreamwork.std.Hook | fun( ...: any ): any The callback function or the hook to attach.
---@field [4] nil | dreamwork.std.Hook.Type The type of the hook.

--- [SHARED AND MENU]
---
--- Hook object.
---
---@class dreamwork.std.Hook : dreamwork.Object
---@field __class dreamwork.std.HookClass
---@field name string The name of the hook. **READ-ONLY**
---@field is_running boolean Whether the hook is running. **READ-ONLY**
---@field return_vararg boolean Whether the hook returns vararg. **READ-ONLY**
---@field mixer_fn nil | fun( old_value: any, new_value: any ): any The mixer function for the hook.
---@field protected queues dreamwork.std.Hook.query_data[] The queue of queries.
---@operator call: any
local Hook = std.class.base( "Hook" )

---@alias Hook dreamwork.std.Hook

--- [SHARED AND MENU]
---
--- Hook class.
---
---@class dreamwork.std.HookClass : dreamwork.std.Hook
---@field __base dreamwork.std.Hook
---@overload fun( name: string?, return_vararg: boolean? ): dreamwork.std.Hook
local HookClass = std.class.create( Hook )
std.Hook = HookClass

---@protected
function Hook:__tostring()
    return std.string.format( "Hook: %p [%s][%s]", self, self.name, self.is_running and "running" or "stopped" )
end

---@param name? string The name of the hook.
---@param return_vararg? boolean Whether the hook returns vararg.
---@protected
function Hook:__init( name, return_vararg )
    self.is_running = false
    self.name = name or "unnamed"
    self.return_vararg = return_vararg == true
end

do

    local debug_fempty = debug.fempty
    local table_eject = table.eject

    --- [SHARED AND MENU]
    ---
    --- Detaches a callback function from the hook.
    ---
    ---@param identifier string | Hook | any The unique name of the callback, Hook or object with `__isvalid` function in metatable.
    ---@return boolean detached Returns `true` if the callback was detached, otherwise `false`.
    function Hook:detach( identifier )
        if identifier == nil then return false end

        for i = #self - 2, 1, -3 do
            if self[ i ] == identifier then
                if self.is_running then
                    self[ i + 1 ] = debug_fempty

                    local queue = self.queues
                    if queue == nil then
                        self.queues = { { false, identifier } }
                    else
                        queue[ #queue + 1 ] = { false, identifier }
                    end
                else
                    table_eject( self, i, i + 2 )
                end

                return true
            end
        end

        return false
    end

end

do

    local string_meta = debug.findmetatable( "string" )
    local debug_getmetatable = debug.getmetatable
    local math_clamp = std.math.clamp
    local math_floor = std.math.floor
    local table_inject = table.inject
    local isNumber = std.isNumber

    --- [SHARED AND MENU]
    ---
    --- Attaches a callback function to the hook.
    ---
    ---@param fn function | Hook | nil The callback function or the hook to attach.
    ---@param identifier dreamwork.std.Hook.Type | any The unique identifier of the callback, object with `__isvalid` function in metatable or the type of the hook if `fn` is a Hook.
    ---@param hook_type dreamwork.std.Hook.Type | nil The type of the hook, default is `0`, can be `nil` if `fn` is a Hook and `identifier` is the type of the hook.
    function Hook:attach( fn, identifier, hook_type )
        if identifier == nil then
            identifier = "nil"
        end

        if debug_getmetatable( fn ) == Hook then
            ---@cast fn dreamwork.std.Hook

            if isNumber( identifier ) then
                ---@cast identifier number
                ---@diagnostic disable-next-line: cast-local-type
                hook_type = math_floor( identifier )
            elseif not isNumber( hook_type ) then
                ---@diagnostic disable-next-line: cast-local-type
                hook_type = 0
            end

            identifier = fn
        end

        local metatable = debug_getmetatable( identifier )
        if metatable == nil then
            error( "callback identifier has no metatable", 2 )
            return
        end

        if metatable ~= string_meta then
            ---@cast identifier any
            ---@cast fn function

            local isvalid = metatable.__isvalid
            if isvalid == nil then
                error( "callback identifier has no `__isvalid` function", 2 )
                return
            end

            if not isvalid( identifier ) then
                self:detach( identifier )
                return
            end

            local real_fn = fn
            function fn( ... )
                if isvalid( identifier ) then
                    return real_fn( identifier, ... )
                end

                self:detach( identifier )
            end
        end

        if hook_type == nil then
            ---@diagnostic disable-next-line: cast-local-type
            hook_type = 0
        else
            ---@diagnostic disable-next-line: cast-local-type
            hook_type = math_clamp( math_floor( hook_type ), -2, 2 )
        end

        for i = #self - 2, 1, -3 do
            if self[ i ] == identifier then
                if self[ i + 2 ] == hook_type then
                    self[ i + 1 ] = fn
                    return
                end

                self:detach( identifier )
                break
            end
        end

        if self.is_running then
            local queue = self.queues
            if queue == nil then
                ---@diagnostic disable-next-line: assign-type-mismatch
                self.queues = { { true, identifier, fn, hook_type } }
            else
                ---@diagnostic disable-next-line: assign-type-mismatch
                queue[ #queue + 1 ] = { true, identifier, fn, hook_type }
            end

            return
        end

        local callback_count = #self

        local index = callback_count
        for i = 3, callback_count, 3 do
            if self[ i ] > hook_type then
                index = ( i - 3 )
                break
            end
        end

        table_inject( self, { identifier, fn, hook_type }, index + 1, 1, 3 )
    end

end

--- [SHARED AND MENU]
---
--- Checks if the hook is running.
---
---@return boolean is_running Returns `true` if the hook is running, otherwise `false`.
function Hook:isRunning()
    return self.is_running
end

do

    --- [SHARED AND MENU]
    ---
    --- Stops the hook.
    ---@return boolean stopped Returns `true` if the hook was stopped, `false` if it was already stopped.
    local function hook_stop( self )
        if not self.is_running then return false end
        self.is_running = false

        local queue = self.queues
        if queue ~= nil then
            self.queues = nil

            for i = 1, #queue, 1 do
                local args = queue[ i ]
                if args[ 1 ] then
                    self:attach( args[ 2 ], args[ 3 ], args[ 4 ] )
                else
                    self:detach( args[ 2 ] )
                end
            end
        end

        return true
    end

    --- [SHARED AND MENU]
    ---
    --- Clears the hook from all callbacks.
    ---
    function Hook:clear()
        hook_stop( self )

        for i = 1, #self, 1 do
            self[ i ] = nil
        end
    end

    Hook.stop = hook_stop

    --- hook call without mixer and vararg
    local function call_without_mixer_and_vararg( self, ... )
        local result
        for index = 3, #self, 3 do
            if not self.is_running then break end

            local hook_type = self[ index ]
            if hook_type == -2 then -- pre hook
                self[ index - 1 ]( ... )
            elseif hook_type == 1 then -- post hook return
                local value = self[ index - 1 ]( result, ... )
                if value ~= nil then result = value end
            elseif hook_type ~= 2 then -- pre hook return and normal hook
                local value = self[ index - 1 ]( ... )
                if value ~= nil then result = value end
            end
        end

        hook_stop( self )

        for index = 3, #self, 3 do
            if self[ index ] == 2 then -- post hook
                self[ index - 1 ]( result, ... )
            end
        end

        return result
    end

    --- hook call without mixer but with vararg
    local function call_without_mixer( self, ... )
        local r1, r2, r3, r4, r5, r6
        for index = 3, #self, 3 do
            if not self.is_running then break end

            local hook_type = self[ index ]
            if hook_type == -2 then -- pre hook
                self[ index - 1 ]( ... )
            elseif hook_type == 1 then -- post hook return
                local v1, v2, v3, v4, v5, v6 = self[ index - 1 ]( { r1, r2, r3, r4, r5, r6 }, ... )
                if v1 ~= nil then r1, r2, r3, r4, r5, r6 = v1, v2, v3, v4, v5, v6 end
            elseif hook_type ~= 2 then -- pre hook return and normal hook
                local v1, v2, v3, v4, v5, v6 = self[ index - 1 ]( ... )
                if v1 ~= nil then r1, r2, r3, r4, r5, r6 = v1, v2, v3, v4, v5, v6 end
            end
        end

        hook_stop( self )

        for index = 3, #self, 3 do
            if self[ index ] == 2 then -- post hook
                self[ index - 1 ]( { r1, r2, r3, r4, r5, r6 }, ... )
            end
        end

        return r1, r2, r3, r4, r5, r6
    end

    --- hook call with mixer and without vararg
    local function call_with_mixer( self, mixer_fn, ... )
        local result
        for index = 3, #self, 3 do
            if not self.is_running then break end

            local hook_type = self[ index ]
            if hook_type == -2 then -- pre hook
                self[ index - 1 ]( ... )
            elseif hook_type == 1 then -- post hook return
                local value = self[ index - 1 ]( result, ... )
                if value ~= nil then result = value end
            elseif hook_type ~= 2 then -- pre hook return and normal hook
                local value = self[ index - 1 ]( ... )
                if value ~= nil then
                    local mixed = mixer_fn( result, value )
                    if mixed == nil then
                        result = value
                    else
                        result = mixed
                    end
                end
            end
        end

        hook_stop( self )

        for index = 3, #self, 3 do
            if self[ index ] == 2 then -- post hook
                self[ index - 1 ]( result, ... )
            end
        end

        return result
    end

    --- hook call with mixer and vararg
    local function call_with_mixer_and_vararg( self, mixer_fn, ... )
        local r1, r2, r3, r4, r5, r6
        for index = 3, #self, 3 do
            if not self.is_running then break end

            local hook_type = self[ index ]
            if hook_type == -2 then -- pre hook
                self[ index - 1 ]( ... )
            elseif hook_type == 1 then -- post hook return
                local v1, v2, v3, v4, v5, v6 = self[ index - 1 ]( { r1, r2, r3, r4, r5, r6 }, ... )
                if v1 ~= nil then r1, r2, r3, r4, r5, r6 = v1, v2, v3, v4, v5, v6 end
            elseif hook_type ~= 2 then -- pre hook return and normal hook
                local v1, v2, v3, v4, v5, v6 = self[ index - 1 ]( ... )
                if v1 ~= nil then
                    local m1, m2, m3, m4, m5, m6 = mixer_fn( { r1, r2, r3, r4, r5, r6 }, { v1, v2, v3, v4, v5, v6 } )
                    if m1 == nil then
                        r1, r2, r3, r4, r5, r6 = v1, v2, v3, v4, v5, v6
                    else
                        r1, r2, r3, r4, r5, r6 = m1, m2, m3, m4, m5, m6
                    end
                end
            end
        end

        hook_stop( self )

        for index = 3, #self, 3 do
            if self[ index ] == 2 then -- post hook
                self[ index - 1 ]( { r1, r2, r3, r4, r5, r6 }, ... )
            end
        end

        return r1, r2, r3, r4, r5, r6
    end

    --- [SHARED AND MENU]
    ---
    --- Calls the hook.
    ---
    ---@param ... any The arguments to pass to the hook.
    ---@return any ... The return values from the hook.
    function Hook:call( ... )
        if self.is_running then return end
        self.is_running = true

        local mixer_fn = self.mixer_fn
        if mixer_fn == nil then
            if self.return_vararg then
                return call_without_mixer( self, ... )
            else
                return call_without_mixer_and_vararg( self, ... )
            end
        elseif self.return_vararg then
            return call_with_mixer_and_vararg( self, mixer_fn, ... )
        else
            return call_with_mixer( self, mixer_fn, ... )
        end
    end

    Hook.__call = Hook.call

end

--- [SHARED AND MENU]
---
--- Sets the mixer function for the hook.
---
--- This function will be called after pre
--- and normal callbacks that changes the
--- return value of the hook,
--- and can change that value.
---
---@param mixer_fn nil | fun( old_value, new_value ): any The function to perform mixing, `nil` if no mixing is required.
function Hook:mixer( mixer_fn )
    self.mixer_fn = mixer_fn
end

do

    local uuid_v7 = std.uuid.v7

    --- [SHARED AND MENU]
    ---
    --- Attaches a callback function to the hook.
    ---
    ---@param fn function | dreamwork.std.Hook.Type The callback function or the type of the hook if `identifier` is a Hook.
    ---@param hook_type? dreamwork.std.Hook.Type The type of the hook, default is `0`.
    function Hook:once( fn, hook_type )
        local identifier = uuid_v7()
        self:attach( function( ... )
            self:detach( identifier )
            return fn( ... )
        end,  identifier, hook_type )
    end

end

do

    local futures_Future = std.futures.Future

    --- [SHARED AND MENU]
    ---
    --- Waits for the hook to finish.
    ---
    ---@param hook_type dreamwork.std.Hook.Type? The type of the hook, default is `0`.
    ---@return any ... The return values from the hook.
    ---@async
    function Hook:wait( hook_type )
        local f = futures_Future()

        self:once( function( ... )
            f:setResult( { ... } )
        end, hook_type )

        return f:await()
    end

end
