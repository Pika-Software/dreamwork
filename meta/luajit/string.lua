---@meta string

---
---
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-string)
---
---@class stringlib
string = {}

---
---Returns the internal numeric codes of the characters `s[i], s[i+1], ..., s[j]`.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-string.byte)
---
---@param s  string|number
---@param i? integer
---@param j? integer
---@return integer ...
---@nodiscard
function string.byte( s, i, j ) end

---
---Returns a string with length equal to the number of arguments, in which each character has the internal numeric code equal to its corresponding argument.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-string.char)
---
---@param byte integer
---@param ... integer
---@return string
---@nodiscard
function string.char( byte, ... ) end

---
---Returns a string containing a binary representation (a *binary chunk*) of the given function.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-string.dump)
---
---@param f      async fun(...):...
---@param strip? boolean
---@return string
---@nodiscard
function string.dump( f, strip ) end

---
---Looks for the first match of `pattern` (see [§6.4.1](http://www.lua.org/manual/5.1/manual.html#6.4.1)) in the string.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-string.find)
---
---@param s       string|number
---@param pattern string|number
---@param init?   integer
---@param plain?  boolean
---@return integer|nil start
---@return integer|nil end
---@return any|nil ... captured
---@nodiscard
function string.find( s, pattern, init, plain ) end

---
---Returns a formatted version of its variable number of arguments following the description given in its first argument.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-string.format)
---
---@param s string|number
---@param ... any
---@return string
---@nodiscard
function string.format( s, ... ) end

---
---Returns an iterator function. Each call to that iterator continues matching `pattern` (see [§6.4.1](http://www.lua.org/manual/5.1/manual.html#6.4.1)) over s and returns all captures.
---
---The following example iterates over all words in string s, printing one per line:
---```lua
---    s =
---"hello world from Lua"
---    for w in string.gmatch(s, "%a+") do
---        print(w)
---    end
---```
---
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-string.gmatch)
---
---@param s       string|number
---@param pattern string|number
---@return fun():string, ...
---@nodiscard
function string.gmatch( s, pattern ) end

---
---Returns a copy of s where all occurrences of `pattern` (or the first n occurrences if n is given) are replaced by repl (see [§6.4.1](http://www.lua.org/manual/5.1/manual.html#6.4.1)).
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-string.gsub)
---
---@param s       string|number
---@param pattern string|number
---@param repl    string|number|table|function
---@param n?      integer
---@return string
---@return integer count
function string.gsub( s, pattern, repl, n ) end

---
---Returns its length.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-string.len)
---
---@param s string|number
---@return integer
---@nodiscard
function string.len( s ) end

---
---Returns a copy of this string with all uppercase letters changed to lowercase.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-string.lower)
---
---@param s string|number
---@return string
---@nodiscard
function string.lower( s ) end

--- [SHARED AND MENU]
---
--- Looks for the first match of `pattern` (see [§6.4.1](http://www.lua.org/manual/5.1/manual.html#6.4.1)) in the string.
---
--- If it finds one, `match` returns the captures; otherwise it returns nil.
---
--- | Key  | Description                             |
--- |:-----|:----------------------------------------|
--- | `x`  | (where x is not one of the magic characters ^$()%.[]*+-?) represents the character x itself. |
--- | `.`  | (a dot) represents all characters.      |
--- | `%a` | Represents all letters.                 |
--- | `%c` | Represents all control characters.      |
--- | `%d` | Represents all digits.                  |
--- | `%l` | Represents all lowercase letters.       |
--- | `%p` | Represents all punctuation characters.  |
--- | `%s` | Represents all space characters.        |
--- | `%S` | Represents all non-space characters.    |
--- | `%u` | Represents all uppercase letters.       |
--- | `%w` | Represents all alphanumeric characters. |
--- | `%x` | Represents all hexadecimal digits.      |
--- | `%z` | Represents the character with representation 0. |
--- | `%x` | (where x is any non-alphanumeric character) represents the character x. This is the standard way to escape the magic characters. Any punctuation character (even the non magic) can be preceded by a '%' when used to represent itself in a pattern. |
--- | `[set]` | Represents the class which is the union of all characters in set. A range of characters can be specified by separating the end characters of the range with a '-'. All classes %x described above can also be used as components in set. All other characters in set represent themselves. For example, [%w_] (or [_%w]) represents all alphanumeric characters plus the underscore, [0-7] represents the octal digits, and [0-7%l%-] represents the octal digits plus the lowercase letters plus the '-' character. |
--- | `[^set]` | Represents the complement of set, where set is interpreted as above. |
---
--- > The interaction between ranges and classes is not defined. Therefore, patterns like `[%a-z]` or `[a-%%]` have no meaning.
---
--- For all classes represented by single letters (`%a`, `%c`, etc.), the corresponding uppercase letter represents the complement of the class.
---
--- The definitions of letter, space, and other character groups depend on the current locale.
---
--- In particular, the class `[a-z]` may not be equivalent to `%l`.
---
--- [View documents](http://www.lua.org/manual/5.1/manual.html#pdf-string.match)
---
---@param str string | number
---@param pattern string | number
---@param start_position? integer
---@return any ...
---@nodiscard
function string.match( str, pattern, start_position ) end

---@version >5.3
---
---Returns a binary string containing the values `v1`, `v2`, etc. packed (that is, serialized in binary form) according to the format string `fmt` (see [§6.4.2](http://www.lua.org/manual/5.1/manual.html#6.4.2)).
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-string.pack)
---
---@param fmt string
---@param v1  string|number
---@param v2? string|number
---@param ... string|number
---@return string binary
---@nodiscard
function string.pack( fmt, v1, v2, ... ) end

---@version >5.3
---
---Returns the length of a string resulting from `string.pack` with the given format string `fmt`. The format string cannot contain the variable-length options `s` or `z` (see [§6.4.2](http://www.lua.org/manual/5.1/manual.html#6.4.2)).
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-string.packsize)
---
---@param fmt string
---@return integer
---@nodiscard
function string.packsize( fmt ) end

---
---Returns a string that is the concatenation of `n` copies of the string `s` separated by the string `sep`.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-string.rep)
---
---@param s    string|number
---@param n    integer
---@param sep? string|number
---@return string
---@nodiscard
function string.rep( s, n, sep ) end

---
---Returns a string that is the string `s` reversed.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-string.reverse)
---
---@param s string|number
---@return string
---@nodiscard
function string.reverse( s ) end

---
---Returns the substring of the string that starts at `i` and continues until `j`.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-string.sub)
---
---@param s  string|number
---@param i  integer
---@param j? integer
---@return string
---@nodiscard
function string.sub( s, i, j ) end

---@version >5.3
---
---Returns the values packed in string according to the format string `fmt` (see [§6.4.2](http://www.lua.org/manual/5.1/manual.html#6.4.2)) .
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-string.unpack)
---
---@param fmt  string
---@param s    string
---@param pos? integer
---@return any ...
---@nodiscard
function string.unpack( fmt, s, pos ) end

---
---Returns a copy of this string with all lowercase letters changed to uppercase.
---
---[View documents](http://www.lua.org/manual/5.1/manual.html#pdf-string.upper)
---
---@param s string|number
---@return string
---@nodiscard
function string.upper( s ) end

return string
