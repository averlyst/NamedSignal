--[[
	-- NamedSignal --
	
	v2.0.0-rc.1

	A Signal implementation for Luau, with a nice balance of ergonomics, performance, and features.
	Most notably, you can use function types to get named parameters!

	Comprehensive documentation and additional info is available at:
		https://Nowoshire.github.io/NamedSignal

	This software is licensed under the MIT License:
		https://github.com/Nowoshire/NamedSignal/blob/main/LICENSE

		MIT License

		Copyright (c) 2026 Nowoshire

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

-- Constants --
-- Controls whether event handlers are fired immediately or deferred.
-- "Immediate" is the recommended default for performance reasons.
const SIGNAL_BEHAVIOR: "Immediate" | "Deferred"
	= "Immediate"

-- Whether to use the Roblox task library to handle invocations when available.
-- Only applicable when using Immediate signal behavior, always uses task.defer on Deferred mode when available.
-- Using the task library results in a roughly 2-4x worse firing performance, but provides error information in output.
const USE_TASK_LIBRARY = true

-- Function used for resuming threads used for invocation, switched based on signal behavior and task library availability.
const resumeInvokeThread = task and (
	SIGNAL_BEHAVIOR == "Deferred" and task.defer or USE_TASK_LIBRARY and task.spawn
) or coroutine.resume

-- Imports --
const Types = require("@self/Types")

-- Thread Recycling --
--[[
	Spawns a thread faster than the task library, only returns the created thread.
]]
const function spawnThread <A..., R...>(func: (A...) -> (R...), ...: A...): (thread)
	const thread = coroutine.create(func)
	coroutine.resume(thread, ...)
	return thread
end

-- "Fast" thread cache, slightly improves the performance of non-yielding dispatch.
local tL1: thread?

-- "Slow" thread cache
const threadPool = {} :: {thread}

--[[
	Calls the given callback with the given arguments, then adds the thread into the cache for reuse.
]]
const function callOnAndCacheThread(thread: thread, callback: (...any) -> (), ...: any): ()
	callback(...)

	-- Callback finished running, this thread is free again, add it back to the cache
	if tL1 then
		table.insert(threadPool, thread)
	else
		tL1 = thread
	end
end

--[[
	Indefinitely looping function body of event handler coroutines.
	Gets resumed with functions to run followed by arguments to run them with.
]]
const function eventHandlerRoutine(): ()
	while true do
		callOnAndCacheThread(coroutine.yield())
	end
end

--[[
	Returns an available thread.
]]
const function getAvailableThread(): (thread)
	local thread: thread
	if tL1 then -- Check fast cache
		thread = tL1
		tL1 = nil
	else
		-- Check slow cache
		const numThreads = #threadPool
		if numThreads == 0 then
			-- No thread is available in pool, return a new one.
			return spawnThread(eventHandlerRoutine)
		end

		thread = threadPool[numThreads]
		threadPool[numThreads] = nil -- Remove from free threads
	end

	-- Fix an edge case where if the cached handler thread is not suspended, the first listener will not run on the next invocation.
	if coroutine.status(thread) ~= "suspended" then
		return spawnThread(eventHandlerRoutine)
	end

	return thread
end

-- Deferred Mutation Helpers --

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

-- Connection Class --
const Connection = {}
Connection.__index = Connection

export type Connection<Signature = () -> ()> = Types.Connection<Signature>
type InternalConnection = Types.InternalConnection

--[[
	Links the connection to the end of the signal.
]]
const function linkConnection(connection: InternalConnection, signal: InternalSignal): ()
	if connection.Connected then return end
	connection.Connected = true

	const tail = signal._tail

	-- Link the connection to the tail connection if it exists
	if tail then
		tail._next = connection
		connection._prev = tail
	else -- Otherwise, this is the first connection, set signal head to this.
		signal._head = connection
	end

	signal._tail = connection
end

--[[
	Unlinks the connection from the signal.
]]
const function unlinkConnection(connection: InternalConnection, signal: InternalSignal): ()
	if not connection.Connected then return end
	connection.Connected = false

	-- Bridge gaps, set prev next to this one's next and vice versa.
	const prv, nxt = connection._prev, connection._next

	if prv then
		prv._next = nxt
	else -- This was the first link in the list, set to next
		signal._head = nxt
	end

	if nxt then
		nxt._prev = prv
	else -- This was the last link in the list, set to previous
		signal._tail = prv
	end
end

function Connection.Disconnect(self: InternalConnection): ()
	const signal = self.Signal
	if signal._firing then
		enqueueMutation(signal._mutations, {
			f = unlinkConnection :: any,
			c = self
		})
		return
	end

	unlinkConnection(self, signal)
end

function Connection.DisconnectNow(self: InternalConnection): ()
	unlinkConnection(self, self.Signal)
end

function Connection.Reconnect(self: InternalConnection): ()
	const signal = self.Signal
	if signal._firing then
		enqueueMutation(signal._mutations, {
			f = linkConnection :: any,
			c = self,
		})
		return
	end

	linkConnection(self, signal)
end

function Connection.ReconnectNow(self: InternalConnection): ()
	linkConnection(self, self.Signal)
end

-- No "-Now" variation is provided for `Connection:Destroy()`, as that would cause issues with deferred mutations.

function Connection.Destroy(self: InternalConnection): ()
	unlinkConnection(self, self.Signal)
	table.clear(self)
	setmetatable(self, nil)
end

-- Signal Class --
const Signal = {}
Signal.__index = Signal

-- NOTE: UDTFs currently can't serialize recursive types, use the GenericSignal type instead if you run into such issues.
export type Signal<Signature = (...unknown) -> ()> = Types.Signal<Signature>

-- A generics-only alternative as a workaround for types that UDTFs can't serialize, or for compatibility with other signal implementations.
export type GenericSignal<Params...> = Types.GenericSignal<Params...>

type InternalSignal = Types.InternalSignal

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

const function baseDisconnectAll(signal: InternalSignal): ()
	local connection = signal._head
	while connection do
		connection.Connected = false
		connection = connection._next -- Iterate
	end
end

const function baseDisconnectAllRemoveNext(signal: InternalSignal): ()
	local connection = signal._head
	while connection do
		connection.Connected = false
		connection._next, connection = nil, connection._next -- Iterate and also remove _next to stop fire iteration
	end
end

const function disconnectAll(signal: InternalSignal): ()
	baseDisconnectAll(signal)
	signal._head = nil
	signal._tail = nil
end

function Signal.DisconnectAll(self: InternalSignal): ()
	if self._firing then
		enqueueMutation(self._mutations, {
			f = disconnectAll :: any
		})
		return
	end

	disconnectAll(self)
end

function Signal.DisconnectAllNow(self: InternalSignal): ()
	baseDisconnectAllRemoveNext(self)
	self._head = nil
	self._tail = nil	
end

const function destroy(signal: InternalSignal): ()
	cancelAllMutations(signal)
	baseDisconnectAll(signal)
	
	table.clear(signal)
	setmetatable(signal, nil)
end

function Signal.Destroy(self: InternalSignal): ()
	if self._firing then
		enqueueMutation(self._mutations, {
			f = destroy :: any
		})
		return
	end

	destroy(self)
end

function Signal.DestroyNow(self: InternalSignal): ()
	cancelAllMutations(self)
	baseDisconnectAllRemoveNext(self)

	table.clear(self)
	setmetatable(self, nil)
end

--[[
	Returns a new unlinked Connection, used during deferred connections where it's not immediately connected.
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
	Connects the given function to the <code>Signal</code> and returns a <code>Connection</code> that represents it.
	Depending on the signal's fire state, returns a queued unlinked connection, or an immediately linked connection.
]]
const function signalConnect(signal: InternalSignal, func: (...any) -> ()): (InternalConnection)
	if signal._firing then
		const unlinked = newUnlinkedConnection(signal, func)
		enqueueMutation(signal._mutations, {
			f = linkConnection :: any,
			c = unlinked
		})

		return unlinked
	end

	return newLinkedConnection(signal, func)
end

Signal.Connect = signalConnect
Signal.ConnectNow = newLinkedConnection

const function signalOnce(signal: InternalSignal, func: (...any) -> ()): (InternalConnection)
	local connection: InternalConnection
	connection = signalConnect(signal, function(...: any)
		unlinkConnection(connection :: InternalConnection, signal)
		func(...)
	end)

	return connection
end

const function signalOnceNow(signal: InternalSignal, func: (...any) -> ()): (InternalConnection)
	local connection: InternalConnection
	connection = newLinkedConnection(signal, function(...)
		unlinkConnection(connection :: InternalConnection, signal)
		func(...)
	end)

	return connection
end

Signal.Once = signalOnce
Signal.OnceNow = signalOnceNow

function Signal.Wait(self: InternalSignal): (...any)
	const thisThread = coroutine.running()
	signalOnce(self, function(...: any)
		resumeInvokeThread(thisThread, ...)
	end)

	return coroutine.yield()
end

function Signal.WaitNow(self: InternalSignal): (...any)
	const thisThread = coroutine.running()
	signalOnceNow(self, function(...: any)
		resumeInvokeThread(thisThread, ...)
	end)

	return coroutine.yield()
end

--[[
	Calls all currently connected functions and processes first-level mutations.
]]
const function invokeListenersAndProcessMutations(signal: InternalSignal, mutationList: {{Types.SignalMutation}}, ...: any)
	local connection = signal._head
	while connection do
		const thread = getAvailableThread()
		resumeInvokeThread(thread, thread, connection.Callback, ...)
		connection = connection._next
	end

	-- Apply first-level mutations.
	-- While table.remove would return the firstMutations array if it exists, the majority of use cases will
	-- see no mutations, so it would generally be more performant to index first, then call `table.remove`.
	const firstMutations = mutationList[1]
	if not firstMutations then return end

	table.remove(mutationList, 1)

	for _, mutation in firstMutations do
		const func = mutation.f
		if not func then
			-- The function is only undefined for re-entrant firing.
			-- As re-entrant firing creates a new mutation level, no more mutations will be on this level.
			-- Resume parameter storage thread to retrieve the variadics, and select with index 2, as coroutine.resume
			-- returns a boolean as the first argument, which we don't want.
			invokeListenersAndProcessMutations(signal, mutationList, select(2, coroutine.resume(mutation.p :: thread)))
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

--[[
	Yields the current thread, and when resumed, returns the given parameters.
]]
const function yieldVariadicStack(...: any)
	coroutine.yield()
	return ...
end

--[[
	Stores the given parameters in a thread that immediately yields, and that when resumed, returns the parameters.
]]
const function storeVariadics<V...>(...: V...): (thread)
	return spawnThread(yieldVariadicStack, ...)
end

function Signal.Fire(self: InternalSignal, ...: any)
	const mutations = self._mutations

	if self._firing then
		enqueueMutationLevel(mutations, {
			p = storeVariadics(...)
		})
		return
	end

	self._firing = true
	invokeListenersAndProcessMutations(self, mutations, ...)
	self._firing = nil
end

function Signal.FireNow(self: InternalSignal, ...: any)
	const mutations = self._mutations

	self._firing = true
	invokeListenersAndProcessMutations(self, mutations, ...)
	if not mutations[1] then
		self._firing = nil
	end
end

-- Interface --
const NamedSignal = {}

--[[
	Returns a new <code>Signal</code>.
]]
function NamedSignal.new<Signature>(): (Signal<Signature>)
	return setmetatable({
		_mutations = {},
	}, Signal) :: any
end

return NamedSignal