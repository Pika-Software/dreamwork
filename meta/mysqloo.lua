---@meta gm_mysqloo


--- [SHARED AND MENU]
---
--- Database connection state, returned by `Database:status`.
---
---@alias mysqloo.DatabaseStatus
---| `mysqloo.DATABASE_CONNECTED` # Database is connected.
---| `mysqloo.DATABASE_NOT_CONNECTED` # Database is not connected.
---| `mysqloo.DATABASE_INTERNAL_ERROR` # Internal error.

--- [SHARED AND MENU]
---
--- Query state (`mysqloo.QUERY_*`).
---
---@alias mysqloo.QueryStatus
---| `mysqloo.QUERY_NOT_RUNNING` # Query is not running.
---| `mysqloo.QUERY_WAITING` # Query is queued/started.
---| `mysqloo.QUERY_RUNNING` # Query is being processed (on the database server).
---| `mysqloo.QUERY_COMPLETE` # Query is complete.
---| `mysqloo.QUERY_ABORTED` # Query was aborted.

--- [SHARED AND MENU]
---
--- Query option, used by `Query:setOption`.
---
---@alias mysqloo.QueryOption
---| `mysqloo.OPTION_NUMERIC_FIELDS` # Rows are arrays of values instead of key value pairs.
---| `mysqloo.OPTION_NAMED_FIELDS` # Not used anymore.
---| `mysqloo.OPTION_INTERPRET_DATA` # Not used anymore.
---| `mysqloo.OPTION_CACHE` # Not used anymore.

--- [SHARED AND MENU]
---
--- SSL mode, used by `Database:setSSLMode`.
---
--- See: https://dev.mysql.com/doc/refman/9.1/en/connection-options.html#option_general_ssl-mode
---
---@alias mysqloo.SSLMode
---| `mysqloo.SSL_MODE_DISABLED` # SSL is disabled.
---| `mysqloo.SSL_MODE_PREFERRED` # SSL is preferred if the server supports it.
---| `mysqloo.SSL_MODE_REQUIRED` # SSL is required, fails the connection otherwise.
---| `mysqloo.SSL_MODE_VERIFY_CA` # Like `REQUIRED`, but also verifies the CA.
---| `mysqloo.SSL_MODE_VERIFY_IDENTITY` # Like `VERIFY_CA`, but also performs host name verification.

--- [SHARED AND MENU]
---
--- A single result row, a key value table (`field_name = field_value`),
--- or an array of values if `mysqloo.OPTION_NUMERIC_FIELDS` is enabled.
---
---@alias mysqloo.Row table<string | integer, string | number | boolean | nil>

--- [SHARED AND MENU]
---
--- MySQLOO, a binary module for asynchronous MySQL access, available after `require( "mysqloo" )`.
---
--- [View documents](https://github.com/FredyH/MySQLOO)
---
---@class mysqloo
---@field VERSION string Current MySQLOO version (currently `"9"`).
---@field MINOR_VERSION string Minor version of this library.
---@field DATABASE_CONNECTED integer Database is connected.
---@field DATABASE_NOT_CONNECTED integer Database is not connected.
---@field DATABASE_INTERNAL_ERROR integer Internal error.
---@field QUERY_NOT_RUNNING integer Query is not running.
---@field QUERY_WAITING integer Query is queued/started.
---@field QUERY_RUNNING integer Query is being processed (on the database server).
---@field QUERY_COMPLETE integer Query is complete.
---@field QUERY_ABORTED integer Query was aborted.
---@field OPTION_NUMERIC_FIELDS integer Instead of rows being key value pairs, this makes them just be an array of values.
---@field OPTION_NAMED_FIELDS integer Not used anymore.
---@field OPTION_INTERPRET_DATA integer Not used anymore.
---@field OPTION_CACHE integer Not used anymore.
---@field SSL_MODE_DISABLED integer SSL is disabled.
---@field SSL_MODE_PREFERRED integer SSL is preferred if the server supports it.
---@field SSL_MODE_REQUIRED integer SSL is required, fails the connection otherwise.
---@field SSL_MODE_VERIFY_CA integer Like `REQUIRED`, but also verifies the CA.
---@field SSL_MODE_VERIFY_IDENTITY integer Like `VERIFY_CA`, but also performs host name verification.
mysqloo = {}

--- [SHARED AND MENU]
---
--- Initializes the database object, note that this does not actually connect to the database.
---
--- Call `Database:connect` to establish the connection.
---
---@param host string The host name or IP address of the MySQL server.
---@param username string The user name.
---@param password string The user password.
---@param database string The name of the database (schema) to use.
---@param port? integer The port of the MySQL server, `3306` by default.
---@param socket? string The path of the unix socket to use instead of TCP.
---@return mysqloo.Database database The database object.
function mysqloo.connect( host, username, password, database, port, socket ) end

--- [SHARED AND MENU]
---
--- Database object.
---
---@class mysqloo.Database
local Database = {}

--- [SHARED AND MENU]
---
--- Connects to the database (non blocking).
---
--- Calls the `onConnected` or `onConnectionFailed` callback when finished.
---
function Database:connect() end

--- [SHARED AND MENU]
---
--- Disconnects from the database.
---
--- Calls the `onDisconnected` callback if it existed on the database before the database was connected.
---
---@param shouldWait? boolean If `true`, waits for all queries to finish before disconnecting.
function Database:disconnect( shouldWait ) end

--- [SHARED AND MENU]
---
--- Initializes a query to the database, the query is not started until `Query:start` is called.
---
---@param sql string The SQL query to run.
---@return mysqloo.Query query The query object.
function Database:query( sql ) end

--- [SHARED AND MENU]
---
--- Creates a prepared query associated with the database.
---
---@param sql string The parameterized SQL query, e.g. `"INSERT INTO users (`steamid`, `nick`) VALUES(?,?)"`.
---@return mysqloo.PreparedQuery query The prepared query object.
function Database:prepare( sql ) end

--- [SHARED AND MENU]
---
--- Creates a transaction that executes multiple statements atomically.
---
--- See: https://en.wikipedia.org/wiki/ACID
---
---@return mysqloo.Transaction transaction The transaction object.
function Database:createTransaction() end

--- [SHARED AND MENU]
---
--- Escapes a string so that it is safe to use in a query.
---
--- If the character set of the database is changed after connecting, this might not work properly anymore.
---
---@param str string The string to escape.
---@return string escaped The escaped string.
function Database:escape( str ) end

--- [SHARED AND MENU]
---
--- Aborts all waiting (`mysqloo.QUERY_WAITING`) queries.
---
---@return integer count The amount of queries aborted successfully.
function Database:abortAllQueries() end

--- [SHARED AND MENU]
---
--- Checks the connection state of the database.
---
--- This shouldn't be used to detect timeouts to the server anymore (it's not possible anymore).
---
---@return mysqloo.DatabaseStatus status The connection state.
function Database:status() end

--- [SHARED AND MENU]
---
--- Enables or disables the autoreconnect feature of mysqloo (enabled by default).
---
--- This may only be called before `Database:connect`.
---
---@param shouldReconnect boolean If `false`, the connection is not restored automatically.
function Database:setAutoReconnect( shouldReconnect ) end

--- [SHARED AND MENU]
---
--- Enables or disables multi statements (`"SELECT 1; SELECT 2;"`).
---
--- This may only be called before `Database:connect`.
---
---@param useMultiStatements boolean If `false`, multi statements are disabled.
function Database:setMultiStatements( useMultiStatements ) end

--- [SHARED AND MENU]
---
--- Enables or disables caching of prepared query handles.
---
--- Disabling it reduces the performance of prepared queries that are being reused,
--- set it to `false` if you run into the prepared query limit imposed by the server.
---
---@param cachePreparedStatements boolean If `false`, caching is disabled.
function Database:setCachePreparedStatements( cachePreparedStatements ) end

--- [SHARED AND MENU]
---
--- Forces the server to wait for the connection to finish (might cause deadlocks).
---
--- This may only be called after `Database:connect`.
---
function Database:wait() end

--- [SHARED AND MENU]
---
--- Gets the MySQL server version.
---
---@return integer version The server version number, e.g. `80033`.
function Database:serverVersion() end

--- [SHARED AND MENU]
---
--- Gets the fancy string of the MySQL server version.
---
---@return string info The server version string.
function Database:serverInfo() end

--- [SHARED AND MENU]
---
--- Gets information about the connection.
---
---@return string info The host information string.
function Database:hostInfo() end

--- [SHARED AND MENU]
---
--- Gets the amount of queries waiting to be processed.
---
---@return integer size The queue size.
function Database:queueSize() end

--- [SHARED AND MENU]
---
--- Actively checks if the database connection is still up and attempts to reconnect if it is down.
---
--- This will freeze your server for at least 2 times the ping time to the database server if the connection is down.
---
---@return boolean isUp `true` if the connection is still up, `false` otherwise.
function Database:ping() end

--- [SHARED AND MENU]
---
--- Attempts to set the character set of the connection.
---
--- Please note that this blocks the main server thread if there is a query currently being run.
---
---@param charSetName string The name of the character set, e.g. `"utf8mb4"`.
---@return boolean success `true` on success, `false` on failure.
function Database:setCharacterSet( charSetName ) end

--- [SHARED AND MENU]
---
--- Sets the SSL mode of the database object.
---
--- This needs to be called before `Database:connect`.
---
---@param mode mysqloo.SSLMode The SSL mode (`mysqloo.SSL_MODE_*`).
function Database:setSSLMode( mode ) end

--- [SHARED AND MENU]
---
--- Sets the SSL configuration of the database object, this allows you to enable secure connections over the internet using TLS.
---
--- Every parameter is optional and can be omitted (set to `nil`) if not required.
---
--- See: https://dev.mysql.com/doc/c-api/8.0/en/mysql-ssl-set.html
---
---@param key? string The path to the key file.
---@param cert? string The path to the certificate file.
---@param ca? string The path to the certificate authority file.
---@param capath? string The path to the directory that contains trusted CA certificates.
---@param cipher? string The list of permissible ciphers for SSL encryption.
function Database:setSSLSettings( key, cert, ca, capath, cipher ) end

--- [SHARED AND MENU]
---
--- Sets the timeout for reading from the server.
---
--- The timeout value needs to be at least `1`. If this is not called, the default value is used.
---
--- See: https://dev.mysql.com/doc/c-api/8.0/en/mysql-options.html
---
---@param timeout integer The timeout in seconds.
function Database:setReadTimeout( timeout ) end

--- [SHARED AND MENU]
---
--- Sets the timeout for writing to the server.
---
--- The timeout value needs to be at least `1`. If this is not called, the default value is used.
---
--- See: https://dev.mysql.com/doc/c-api/8.0/en/mysql-options.html
---
---@param timeout integer The timeout in seconds.
function Database:setWriteTimeout( timeout ) end

--- [SHARED AND MENU]
---
--- Sets the timeout for connecting to the server.
---
--- The timeout value needs to be at least `1`. If this is not called, the default value is used.
---
--- See: https://dev.mysql.com/doc/c-api/8.0/en/mysql-options.html
---
---@param timeout integer The timeout in seconds.
function Database:setConnectTimeout( timeout ) end

--- [SHARED AND MENU]
---
--- Called when the connection to the MySQL server is successful.
---
---@type nil | fun( db: mysqloo.Database )
Database.onConnected = nil

--- [SHARED AND MENU]
---
--- Called when the connection to the MySQL server fails.
---
---@type nil | fun( db: mysqloo.Database, err: string )
Database.onConnectionFailed = nil

--- [SHARED AND MENU]
---
--- Called after `Database:disconnect` has been called and all queries have finished executing.
---
--- You have to set this callback before calling `Database:connect` or it will not be called.
---
---@type nil | fun( db: mysqloo.Database )
Database.onDisconnected = nil

--- [SHARED AND MENU]
---
--- Query object, `mysqloo.PreparedQuery` and `mysqloo.Transaction` also inherit all of its functions (some have no effect though).
---
--- **Always** set the callbacks before you start the query or you might run into issues.
---
---@class mysqloo.Query
---@field onAborted nil | fun( q: mysqloo.Query ) Called when the query is aborted.
---@field onError nil | fun( q: mysqloo.Query, err: string, sql: string ) Called when the query errors, `err` is the error and `sql` is the SQL query that caused it.
---@field onSuccess nil | fun( q: mysqloo.Query, data: mysqloo.Row[] ) Called when the query is successful, `data` is the data the query returned.
---@field onData nil | fun( q: mysqloo.Query, row: mysqloo.Row ) Called when the query retrieves a row of data. If the query returns multiple results, this is only called for the first result set.
local Query = {}

--- [SHARED AND MENU]
---
--- Starts the query.
---
function Query:start() end

--- [SHARED AND MENU]
---
--- Checks if the query is running or waiting.
---
---@return boolean isRunning `true` if the query is running or waiting, `false` if it isn't.
function Query:isRunning() end

--- [SHARED AND MENU]
---
--- Gets the data the query returned from the server.
---
--- Format: `{ row1, row2, row3, ... }`
---
--- Row format: `{ field_name = field_value }`, or `{ first_field, second_field, ... }` if `mysqloo.OPTION_NUMERIC_FIELDS` is enabled.
---
---@return mysqloo.Row[] | nil data The rows, or `nil` if the query errored or was aborted.
function Query:getData() end

--- [SHARED AND MENU]
---
--- Attempts to abort the query if it is still in the state `mysqloo.QUERY_WAITING`.
---
---@return boolean aborted `true` if at least one running instance of the query was aborted successfully, `false` otherwise.
function Query:abort() end

--- [SHARED AND MENU]
---
--- Gets the autoincrement index of the last inserted row of the current result set.
---
---@return integer id The last insert id.
function Query:lastInsert() end

--- [SHARED AND MENU]
---
--- Gets the number of rows the query has affected (of the current result set).
---
---@return integer count The amount of affected rows.
function Query:affectedRows() end

--- [SHARED AND MENU]
---
--- Changes how the query returns data.
---
---@param option mysqloo.QueryOption The option (`mysqloo.OPTION_*`).
function Query:setOption( option ) end

--- [SHARED AND MENU]
---
--- Forces the server to wait for the query to finish.
---
--- This should only ever be used if it is really necessary, since it can cause lag.
---
---@param shouldSwap? boolean If `true`, the query is swapped to the front of the queue, making it the next query to be executed.
function Query:wait( shouldSwap ) end

--- [SHARED AND MENU]
---
--- Gets the error caused by the query.
---
---@return string err The error, or `""` if there was no error.
function Query:error() end

--- [SHARED AND MENU]
---
--- Checks if the query still has more data associated with it (which means `Query:getNextResults` can be called).
---
--- This function works differently than one would expect: it returns `true` if there is currently
--- a result that can be popped, rather than if there is an additional result that has data.
--- However, this does make for nicer code that handles multiple results.
---
--- **Important:** returns `false` if the query was aborted or errored.
---
---@return boolean hasMore `true` if a result set can be popped.
function Query:hasMoreResults() end

--- [SHARED AND MENU]
---
--- Pops the current result set, changing the results of `Query:lastInsert`, `Query:affectedRows` and `Query:getData` to those of the next result set.
---
--- Raises an error if called when there is no result set left to be popped.
---
---@return mysqloo.Row[] data The rows of the next result set, in the same format as `Query:getData`.
function Query:getNextResults() end

--- [SHARED AND MENU]
---
--- Prepared query object.
---
--- A prepared query uses a prepared statement: instead of having the actual values in the query itself,
--- it uses parameters (`?`) that are set using the appropriate methods, e.g. `"INSERT INTO users (`steamid`, `nick`) VALUES(?,?)"`.
---
--- Prepared statements make SQL injections pretty much impossible since the data is sent separately from the query,
--- and make it easy to reuse one query several times to insert/update/delete multiple rows.
---
--- A few types of queries might not work with prepared statements.
---
--- See: https://en.wikipedia.org/wiki/Prepared_statement
---
---@class mysqloo.PreparedQuery : mysqloo.Query
local PreparedQuery = {}

--- [SHARED AND MENU]
---
--- Sets the parameter at the index to be of type `double`.
---
---@param index integer The parameter index (1-based).
---@param number number The value.
function PreparedQuery:setNumber( index, number ) end

--- [SHARED AND MENU]
---
--- Sets the parameter at the index to be of type `string`.
---
--- The string should **not** be escaped.
---
---@param index integer The parameter index (1-based).
---@param str string The value.
function PreparedQuery:setString( index, str ) end

--- [SHARED AND MENU]
---
--- Sets the parameter at the index to be of type `boolean`.
---
---@param index integer The parameter index (1-based).
---@param bool boolean The value.
function PreparedQuery:setBoolean( index, bool ) end

--- [SHARED AND MENU]
---
--- Sets the parameter at the index to be `NULL`.
---
---@param index integer The parameter index (1-based).
function PreparedQuery:setNull( index ) end

--- [SHARED AND MENU]
---
--- Clears all currently set parameters inside the prepared statement.
---
function PreparedQuery:clearParameters() end

--- [SHARED AND MENU]
---
--- Transaction object.
---
--- Transactions are used to group several separate queries or prepared queries together.
--- Either all queries in the transaction are executed successfully or none of them are.
---
--- Single queries are already transactions by themselves, so it usually only makes sense to have transactions with at least two queries.
---
--- Since mysqloo works asynchronously, much of the power of transactions (such as manually rolling back a transaction)
--- cannot be used properly, but there are still many areas where they are useful.
---
--- **Important:** callbacks of individual queries that are part of the transaction are not run (both in the error and the successful case),
--- use the callbacks of the transaction instead.
---
--- See: https://en.wikipedia.org/wiki/ACID
---
---@class mysqloo.Transaction : mysqloo.Query
---@field onError nil | fun( tr: mysqloo.Transaction, err: string ) Called when any of the queries caused an error, no queries will have had any effect.
---@field onSuccess nil | fun( tr: mysqloo.Transaction ) Called when all queries in the transaction have been executed successfully.
local Transaction = {}

--- [SHARED AND MENU]
---
--- Adds a query to the transaction, the callbacks of the added query will not be called.
---
---@param query mysqloo.Query | mysqloo.PreparedQuery The query to add, either a regular or a prepared query.
function Transaction:addQuery( query ) end

--- [SHARED AND MENU]
---
--- Gets all queries that have been added to this transaction.
---
---@return mysqloo.Query[] queries The added queries.
function Transaction:getQueries() end
