--[[
	-- NamedSignal --
	
	v2.3.1

	A Signal implementation for Luau, with a nice balance of ergonomics, performance, and features.
	Most notably, you can use function types to get named parameters!

	Comprehensive documentation and additional info is available at:
		https://personal.averlyst.dev/NamedSignal

	This software is licensed under the MIT License:
		https://github.com/averlyst/NamedSignal/blob/main/LICENSE

		MIT License

		Copyright (c) 2026 Averlyst

		Permission is hereby granted, free of charge, to any person obtaining a copy
		of this software and associated documentation files (the "Software"), to deal
		in the Software without restriction, including without limitation the rights
		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
		copies of the Software, and to permit persons to whom the Software is
		furnished to do so, subject to the following conditions:

		The above copyright notice and this permission notice shall be included in all
		copies or substantial portions of the Software.

		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
		SOFTWARE.
]]

--!strict
--!optimize 2

-- Configuration --
--[[
	> [!WARNING] No Stability Guarantee
	> Flags are unstable and subject to change or removal.
	> They are set to the recommended values by default, only change these if you know what you're doing.
]]

--[[
	Controls the quality of error information provided in the output in exchange for performance.
	- "Auto" uses "Full" in Roblox Studio, and "Warn" in production.
	- "Full" uses task.spawn when available, providing the full error traceback with jump-to functionality, at the cost of worse performance.
	- "Warn" uses coroutine.resume but outputs the error message with a simplified traceback. Better performance than "Full".
	- "None" uses coroutine.resume but provides no error information. Best performance but not recommended for typical use.
	"Full" is the recommended default.

	> [!CAUTION] Here be dragons!
	> Switching to modes other than "Full" may lead to unexpected C-side issues in rare cases.
	> It's strongly recommended that you do not change this unless you really need the extra performance and are aware of the risks.
]]
const ERROR_INFO_MODE: "Auto" | "Full" | "Warn" | "None"
	= "Full"

-- Imports --
const Types = require("@self/Types")

-- Deferred Mutation Helpers --

--[[
	Returns the next node pointer of the preserved tail connection while clearing its reference.
]]
const function getPreservedTailNext(signal: InternalSignal): (InternalConnection?)
	const pTail = signal._pTail
	if not pTail then return nil end

	signal._pTail = nil
	return pTail and pTail._next
end

--[[
	Removes the next node pointer of the preserved tail connection.
]]
const function removePreservedTailNext(signal: InternalSignal): ()
	const existingPTail = signal._pTail
	if existingPTail then
		existingPTail._next = nil
	end
end

--[[
	Queues a mutation at the last mutation level, or creates a new one if one does not exist.
]]
const function enqueueMutation(mutationList: {{Types.SignalMutation}}, mutation: Types.SignalMutation): ()
	const levels = #mutationList
	const lastMutations = mutationList[levels]

	if lastMutations then
		table.insert(lastMutations, mutation) -- add mutation to existing last level
	else
		mutationList[1] = {mutation}
	end
end

--[[
	Queues a mutation and starts a new mutation level.
]]
const function enqueueMutationLevel(mutationList: {{Types.SignalMutation}}, mutation: Types.SignalMutation): ()
	const levels = #mutationList
	const lastMutations = mutationList[levels]

	if lastMutations then
		table.insert(lastMutations, mutation) -- add mutation to existing last level
		mutationList[levels + 1] = {}
	else
		mutationList[1] = {mutation}
		mutationList[2] = {} -- new level
	end
end

-- Thread Logic --

--[[
	Creates a thread and resumes it immediately with itself as the only argument, then returns it.
]]
const function spawnThreadWithSelf(func: (...any) -> (...any)): (thread)
	const thread = coroutine.create(func)
	coroutine.resume(thread, thread)
	return thread
end

--[[
	Returns a boolean indicating if the given thread is resumable.
]]
const function isThreadResumable(co: thread): (boolean)
	return coroutine.status(co) == "suspended"
end

local threadL1: thread?
const threadL2: {thread?} = {}

--[[
	Adds a free thread to the cache.
]]
const function cacheThread(co: thread): ()
	if not threadL1 then
		threadL1 = co
	else
		table.insert(threadL2, co)
	end
end

--[[
	Runs a single listener cycle on the current thread.
]]
const function runListenerCycle(state: {InternalConnection}, signal: InternalSignal, ...: any): ()
	local node = state[1]
	while node do
		state[1] = node._next or getPreservedTailNext(signal)

		node.Callback(...)

		-- Iterate to next node
		node = state[1]
	end
end

--[[
	Indefinitely looping function body of dispatcher coroutines.
]]
const function dispatcherBody(co: thread): ()
	while true do
		runListenerCycle(coroutine.yield())
		cacheThread(co)
	end
end

--[[
	Returns a dispatch thread, grabbing from cache or creating a new one.
	Resume with a table with index 1 being the Connection node, Signal, and fire arguments.
]]
const function getDispatchThread(): (thread)
	local thread: thread?
	if threadL1 then
		thread = threadL1
		threadL1 = nil
	else
		const poolSize = #threadL2
		if poolSize ~= 0 then
			thread = threadL2[poolSize]
			threadL2[poolSize] = nil
		end
	end

	if not thread then
		return spawnThreadWithSelf(dispatcherBody)
	end

	-- Threads can be closed externally! Check before reuse.
	if not isThreadResumable(thread) then
		return spawnThreadWithSelf(dispatcherBody)
	end

	return thread
end

const resumeThread = if task and (
	if ERROR_INFO_MODE == "Full"
	or ERROR_INFO_MODE == "Auto" and typeof(game) == "Instance" and game:GetService("RunService"):IsStudio()
		then task.spawn
	else nil -- Fallback to below
) or (
	if ERROR_INFO_MODE == "Warn" then
		(function(): ((thread, ...any) -> ()) -- "Auto" in production or "Warn" ERROR_INFO_MODE
			const log = warn or print -- Portability, the environment might not have warn.

			return function(co: thread, ...: any): ()
				const success, err = coroutine.resume(co, ...)
				if success then return end

				-- About as close as we can get to normal error semantics, just with some minor styling differences.
				-- Avoiding tostring conversions to get proper outputs of non-string error messages.
				log(
					"Error occurred during invocation:",
					if err ~= nil then err else "Error occurred, no output from Luau.",
					debug.traceback(co, "\nStack Begin") .. "Stack End"
				)
			end
		end)()
	else
		coroutine.resume
)

-- Connection Class --
const Connection = {}
Connection.__index = Connection

export type Connection<Signature = Types.DefaultSignature> = Types.Connection<Signature>
export type GenericConnection<Params...> = Types.GenericConnection<Params...>
export type WrapConnection<OtherSignal> = Types.WrapConnection<OtherSignal>
type InternalConnection = Types.InternalConnection

const function baseLinkConnection(connection: InternalConnection, signal: InternalSignal, tail: InternalConnection?): ()
	if tail then -- Link the connection to the tail connection if it exists
		tail._next = connection
		connection._prev = tail
	else -- Otherwise, this is the first connection, set signal head to this.
		signal._head = connection
	end

	signal._tail = connection
end

--[[
	Links the connection to the end of the signal.
]]
const function linkConnection(connection: InternalConnection, signal: InternalSignal): ()
	if connection.Connected then return end
	connection.Connected = true

	baseLinkConnection(connection, signal, signal._tail)
end

--[[
	A variant of <code>linkConnection</code> that handles iterator invalidation edge cases.
]]
const function linkConnectionNow(connection: InternalConnection, signal: InternalSignal): ()
	if connection.Connected then return end
	connection.Connected = true

	local tail = signal._tail
	if tail then
		baseLinkConnection(connection, signal, tail)
	else
		tail = signal._pTail
		if tail then
			if not tail._prev then
				signal._head = connection
			end
			
			tail._next = connection
		elseif not connection._prev then
			signal._head = connection
		end

		signal._tail = connection
	end
end

const function baseUnlinkConnection(prv: InternalConnection?, nxt: InternalConnection?, signal: InternalSignal): ()
	if prv then
		prv._next = nxt
	else -- This was the first link in the list, set head to next
		signal._head = nxt
	end
end

--[[
	Unlinks the connection from the signal.
]]
const function unlinkConnection(connection: InternalConnection, signal: InternalSignal): ()
	if not connection.Connected then return end
	connection.Connected = false

	-- Bridge gaps, set prev next to this one's next and vice versa.
	-- Do NOT clear pointers, as it can cause iterator invalidation.
	const prv, nxt = connection._prev, connection._next

	baseUnlinkConnection(prv, nxt, signal)

	if nxt then
		nxt._prev = prv
	else -- This was the last link in the list, set tail to previous
		signal._tail = prv
	end
end

--[[
	A variant of <code>unlinkConnection</code> that handles iterator invalidation edge cases.
]]
const function unlinkConnectionNow(connection: InternalConnection, signal: InternalSignal): ()
	if not connection.Connected then return end
	connection.Connected = false
	
	-- Bridge gaps, set prev next to this one's next and vice versa.
	-- Do NOT clear pointers, as it can cause iterator invalidation.
	const prv, nxt = connection._prev, connection._next

	baseUnlinkConnection(prv, nxt, signal)

	if nxt then
		nxt._prev = prv
	else -- This was the last link in the list, set tail to previous
		if not prv then
			removePreservedTailNext(signal)
			signal._pTail = connection
		end
		
		signal._tail = prv
	end
end

function Connection.Disconnect(self: InternalConnection): ()
	const signal = self.Signal
	if signal._firing then
		enqueueMutation(signal._mutations, {
			f = unlinkConnection :: any, c = self
		})
	else
		unlinkConnection(self, signal)
	end
end

function Connection.DisconnectNow(self: InternalConnection): ()
	const signal = self.Signal
	if signal._firing then
		unlinkConnectionNow(self, signal)
	else
		unlinkConnection(self, signal)
	end
end

function Connection.Reconnect(self: InternalConnection): ()
	const signal = self.Signal
	if signal._firing then
		enqueueMutation(signal._mutations, {
			f = linkConnection :: any, c = self,
		})
	else
		linkConnection(self, signal)
	end
end

function Connection.ReconnectNow(self: InternalConnection): ()
	const signal = self.Signal
	if signal._firing then
		linkConnectionNow(self, self.Signal)
	else
		linkConnection(self, signal)
	end
end

const function destroyConnection(connection: InternalConnection): ()
	unlinkConnection(connection, connection.Signal)
	table.clear(connection)
	setmetatable(connection, nil)
end

function Connection.Destroy(self: InternalConnection): ()
	const signal = self.Signal
	if signal._firing then
		enqueueMutation(signal._mutations, {
			f = destroyConnection :: any, c = self
		})
	else
		destroyConnection(self)
	end
end

function Connection.DestroyNow(self: InternalConnection): ()
	const signal = self.Signal
	if signal._firing then
		unlinkConnectionNow(self, signal)

		-- We can't clear the table now, as it may be the active node and cause iterator invalidation.
		-- Schedule it to be cleared after dispatch.
		enqueueMutation(signal._mutations, {
			f = table.clear :: any, c = self
		})

		setmetatable(self, nil)
	else
		destroyConnection(self, signal)
	end
end

-- Signal Class --
const Signal = {}
Signal.__index = Signal

export type Signal<Signature = Types.DefaultSignature> = Types.Signal<Signature>
export type GenericSignal<Params...> = Types.GenericSignal<Params...>
export type WrapSignal<OtherSignal> = Types.WrapSignal<OtherSignal>
type InternalSignal = Types.InternalSignal

function Signal.GetConnections(self: InternalSignal): ({Connection})
	const connectionList: {InternalConnection} = {}
	local connection = self._head
	while connection do
		table.insert(connectionList, connection)
		connection = connection._next -- We don't need to account for pTails as we don't dispatch any listeners here.
	end

	return connectionList :: {Connection}
end

const function cancelAllMutations(self: InternalSignal): ()
	if not self._firing then return end

	const mutations = self._mutations

	-- Make sure to clear the first level if one exists, so any active process gets cancelled.
	const firstLevel = mutations[1]
	if firstLevel then
		table.clear(firstLevel)
	end

	table.clear(mutations)
end

Signal.CancelAllMutations = cancelAllMutations

const function disconnectAll(signal: InternalSignal): ()
	local connection = signal._head
	while connection do
		connection.Connected = false
		connection = connection._next -- Iterate
	end

	signal._head = nil
	signal._tail = nil
end

function Signal.DisconnectAll(self: InternalSignal): ()
	if self._firing then
		enqueueMutation(self._mutations, {
			f = disconnectAll :: any
		})
	else
		disconnectAll(self)
	end
end

--[[
	Disconnects all connections from the signal.
	
	Doesn't clear _head and _tail.
	Sets _next to nil to intentionally interrupt dispatch.
]]
const function breakConnectionList(signal: InternalSignal): ()
	local connection = signal._head
	while connection do
		connection.Connected = false
		connection._next, connection = nil, connection._next -- Remove _next and iterate
	end
end

function Signal.DisconnectAllNow(self: InternalSignal): ()
	if self._firing then
		breakConnectionList(self)
		removePreservedTailNext(self)
		self._head = nil

		const tail = self._tail
		if tail then
			self._pTail = tail
			self._tail = nil
		end
	else
		disconnectAll(self)
	end
end

const function destroySignal(signal: InternalSignal): ()
	const wrapConnection = signal._wrapConnection
	if wrapConnection then
		wrapConnection:Disconnect()
	end

	cancelAllMutations(signal)
	breakConnectionList(signal)

	table.clear(signal)
	setmetatable(signal, nil)
end

function Signal.Destroy(self: InternalSignal): ()
	if self._firing then
		enqueueMutation(self._mutations, {
			f = destroySignal :: any
		})
	else
		destroySignal(self)
	end
end

Signal.DestroyNow = destroySignal

--[[
	Returns a new unlinked Connection, used for deferred connections that are scheduled to connect at a later time.
]]
const function newUnlinkedConnection(signal: InternalSignal, func: (...any) -> ()): (InternalConnection)
	return setmetatable({
		Connected = false,
		Callback = func,
		Signal = signal,
	}, Connection) :: any
end

--[[
	Returns a new linked Connection.
]]
const function newLinkedConnection(signal: InternalSignal, func: (...any) -> ()): (InternalConnection)
	const tail = signal._tail
	const connection: InternalConnection = setmetatable({
		Connected = true,
		Callback = func,
		Signal = signal,
		_prev = tail,
	}, Connection) :: any

	if tail then
		tail._next = connection
	else
		signal._head = connection
	end

	signal._tail = connection

	return connection
end

--[[
	A variant of <code>newLinkedConnection</code> that handles iterator invalidation edge cases.
]]
const function newLinkedConnectionNow(signal: InternalSignal, func: (...any) -> ()): (InternalConnection)
	local tail = signal._tail
	const connection: InternalConnection = setmetatable({
		Connected = true,
		Callback = func,
		Signal = signal,
		_prev = tail,
	}, Connection) :: any

	if tail then
		tail._next = connection
	else
		tail = signal._pTail
		signal._head = connection
		
		if tail then
			tail._next = connection
		end
	end

	signal._tail = connection

	return connection
end

--[[
	Connects the given function to the <code>Signal</code> and returns a <code>Connection</code> that represents it.
	Depending on the signal's fire state, returns a queued unlinked connection, or an immediately linked connection.
]]
const function signalConnect(signal: InternalSignal, func: (...any) -> ()): (InternalConnection)
	if signal._firing then
		const unlinked = newUnlinkedConnection(signal, func)
		enqueueMutation(signal._mutations, {
			f = linkConnection :: any, c = unlinked
		})

		return unlinked
	else
		return newLinkedConnection(signal, func)
	end
end

--[[
	A variant of <code>signalConnect</code> that handles iterator invalidation edge cases.
]]
const function signalConnectNow(signal: InternalSignal, func: (...any) -> ()): (InternalConnection)
	if signal._firing then
		return newLinkedConnectionNow(signal, func)
	else
		return newLinkedConnection(signal, func)
	end
end

Signal.Connect = signalConnect
Signal.ConnectNow = signalConnectNow

const function signalOnce(signal: InternalSignal, func: (...any) -> ()): (InternalConnection)
	local connection: InternalConnection
	connection = signalConnect(signal, function(...: any): ()
		-- Even though this is not the immediate-mode method, we still use unlinkConnectionNow, as the disconnection
		-- happens during dispatch-time (it's effectively equivalent to DisconnectNow).
		unlinkConnectionNow(connection :: InternalConnection, signal)
		func(...)
	end)

	return connection
end

const function signalOnceNow(signal: InternalSignal, func: (...any) -> ()): (InternalConnection)
	local connection: InternalConnection
	connection = signalConnectNow(signal, function(...: any): ()
		unlinkConnectionNow(connection :: InternalConnection, signal)
		func(...)
	end)

	return connection
end

Signal.Once = signalOnce
Signal.OnceNow = signalOnceNow

--[[
	Yields the running thread, then unlinks the given connection from the signal, and returns any arguments returned from <code>coroutine.yield</code>.
]]
const function safeAwaitSignal(connection: InternalConnection, signal: InternalSignal): (...any)
	const args = {coroutine.yield()}
	unlinkConnectionNow(connection, signal) -- Unlink after resuming to account for external resumption
	return table.unpack(args)
end

const function resumeAwaiting(thread: thread, ...: any): ()
	-- Check that the thread is resumable to avoid nuisance errors.
	if isThreadResumable(thread) then
		resumeThread(thread, ...)
	end
end

function Signal.Wait(self: InternalSignal): (...any)
	const thisThread = coroutine.running()
	return safeAwaitSignal(signalOnce(self, function(...: any): ()
		resumeAwaiting(thisThread, ...)
	end), self)
end

function Signal.WaitNow(self: InternalSignal): (...any)
	const thisThread = coroutine.running()
	return safeAwaitSignal(signalOnceNow(self, function(...: any): ()
		resumeAwaiting(thisThread, ...)
	end), self)
end

--[[
	Calls all currently connected functions and processes first-level mutations.
]]
const function processDispatch(signal: InternalSignal, mutationList: {{Types.SignalMutation}}, ...: any): ()
	const state = {signal._head}
	while state[1] do
		resumeThread(getDispatchThread(), state, signal, ...)
	end

	-- Apply first-level mutations.
	-- While table.remove would return the firstMutations array if it exists, the majority of use cases will see no
	-- mutations, so it would generally be more performant to index first, then call `table.remove`.
	const firstMutations = mutationList[1]
	if not firstMutations then return end

	table.remove(mutationList, 1)

	for _, mutation in firstMutations do
		const func = mutation.f
		if not func then
			-- The function is only undefined for re-entrant firing.
			-- As re-entrant firing creates a new mutation level, no more mutations will be on this level.
			processDispatch(signal, mutationList, table.unpack(mutation.a :: any))
			return
		end

		const conn = mutation.c
		if conn then
			func(conn, signal)
		else
			func(signal)
		end
	end
end

function Signal.Fire(self: InternalSignal, ...: any): ()
	const mutations = self._mutations
	if self._firing then
		enqueueMutationLevel(mutations, {
			a = {...}
		})
	else
		self._firing = true
		processDispatch(self, mutations, ...)

		-- Only the first non-reentrant fire is not queued, and as it's "blocking" we can safely clear _firing
		-- unconditionally since all other operations will have completed during invocation.
		self._firing = nil
	end
end

function Signal.FireNow(self: InternalSignal, ...: any): ()
	self._firing = true

	const mutations = self._mutations
	processDispatch(self, mutations, ...)

	-- FireNow cannot unconditionally clear _firing because it skips re-entrancy, and as such can return before other
	-- invocations complete. Check that there are no more mutations before resetting the flag.
	if not mutations[1] then
		self._firing = nil
	end
end

-- Interface --
const NamedSignal = {}

type function unknownFallback(ty: type, fallback: type): (type)
	return if ty.tag == "unknown" then fallback else ty
end

--[[
	Returns a new <code>Signal</code>.
]]
function NamedSignal.new<Signature>(): (Signal<unknownFallback<Signature, Types.DefaultSignature>>)
	return setmetatable({
		_mutations = {},
	}, Signal) :: any
end

--[[
	Returns a new <code>Signal</code> that fires when the given <code>RBXScriptSignal</code> fires.
]]
function NamedSignal.wrap<OtherSignal>(otherSignal: OtherSignal & RBXScriptSignal): (WrapSignal<OtherSignal>)
	const signal: InternalSignal = setmetatable({
		_mutations = {},
	}, Signal) :: any

	signal._wrapConnection = otherSignal:Connect(function(...: any): ()
		signal:Fire(...)
	end)

	return signal :: any
end

return NamedSignal