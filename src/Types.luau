--!strict

-- Basic Types --
export type DefaultSignature = (...any) -> ()
export type SignalMutation = {
	f: ((InternalSignal | InternalConnection | thread, InternalSignal?) -> ())?, -- for any mutation that isn't fire
	c: InternalConnection?, -- for connection operations
	a: {any}?, -- array of stored arguments from deferred fire
}

-- Type Functions --

--[[
	Makes all read-only or write-only properties to be both writable and readable.
]]
type function internal(ty: type): (type)
	const cache: {[type]: type?} = {}
	const function processType(node: type): (type)
		local result = cache[node]
		if result then return result end

		const nodeTag = node.tag
		if nodeTag == "table" then
			for keyType, rwType in node:properties() do
				node:setproperty(keyType, processType((rwType.read or rwType.write) :: type))
			end

			result = node
		elseif nodeTag == "union" or nodeTag == "intersection" then
			const components = node:components()
			for i, component in components do
				components[i] = processType(component)
			end

			result = if nodeTag == "union"
				then types.unionof(table.unpack(components))
				else types.intersectionof(table.unpack(components))
		else
			result = node
		end

		cache[node] = result

		return result :: type
	end

	return processType(ty)
end

--[[
	Extracts the connection signature from a given RBXScriptSignal if available.
]]
type function fnSignatureFromSignal(connectSignature: type): (type)
	const connectSignatureTag = connectSignature.tag
	if connectSignatureTag ~= "function" then
		print(`WrapSignal<Signal> expects property 'Connect' to be a function, but got '{connectSignatureTag}' type instead.`)
		return DefaultSignature
	end

	const connectHead = connectSignature:parameters().head
	if not connectHead then
		print(`WrapSignal<Signal> requires the 'Connect' function to have head parameters.`)
		return DefaultSignature
	end

	const callback = connectHead[2]
	if not callback then
		print(`WrapSignal<Signal> requires the 'Connect' function to have a callback as its second parameter.`)
		return DefaultSignature
	end

	const callbackTag = callback.tag
	if callbackTag ~= "function" then
		print(`WrapSignal<Signal> expects the callback in the 'Connect' function to be a \`function\`, got {callbackTag} instead.`)
		return DefaultSignature
	end

	return callback
end

type SignatureFromSignal<Signal> = fnSignatureFromSignal<index<Signal, "Connect">>

type function SignalFireSignature(signature: type): (type)
	const signatureTag = signature.tag
	if signatureTag ~= "function" then
		print(`Signal<Signature> expects a 'function' type for \`Signature\`, got '{signatureTag}' type instead.`)
		return DefaultSignature
	end

	const params = signature:parameters()
	const head = params.head
	if head then
		table.insert(head, 1, types.any)
	else
		params.head = {types.any}
	end
	
	return types.newfunction(params)
end

type function SignalWaitSignature(signature: type): (type)
	const signatureTag = signature.tag
	if signatureTag ~= "function" then
		print(`Signal<Signature> expects a 'function' type for \`Signature\`, got '{signatureTag}' type instead.`)
		return DefaultSignature
	end

	return types.newfunction(
		{head = {types.any}}, -- parameters
		signature:parameters() -- returns
	)
end

-- Connection Types --

type BaseConnection<Signal, Signature> = {
	read Signal: Signal,
	read Connected: boolean,
	read Callback: Signature,

	read Disconnect: typeof(
		--[[
			Disconnects the <code>Connection</code> from the <code>Signal</code>.
		]]
		function(self: BaseConnection<Signal, Signature>): () end
	),
	read DisconnectNow: typeof(
		--[[
			The immediate mode equivalent of <code>Connection:Disconnect()</code>.
		]]
		function(self: BaseConnection<Signal, Signature>): () end
	),
	
	read Reconnect: typeof(
		--[[
			Reconnects the <code>Connection</code> to the <code>Signal</code>.
		]]
		function(self: BaseConnection<Signal, Signature>): () end
	),
	read ReconnectNow: typeof(
		--[[
			The immediate mode equivalent of <code>Connection:Reconnect()</code>.
		]]
		function(self: BaseConnection<Signal, Signature>): () end
	),
	
	read Destroy: typeof(
		--[[
			Destroys the <code>Connection</code>.
		]]
		function(self: BaseConnection<Signal, Signature>): () end
	),
	read DestroyNow: typeof(
		--[[
			The immediate mode equivalent of <code>Connection:Destroy()</code>.
		]]
		function(self: BaseConnection<Signal, Signature>): () end
	),
}

export type Connection<Signature = DefaultSignature> = BaseConnection<Signal<Signature>, Signature>
export type GenericConnection<Params... = ...any> = BaseConnection<GenericSignal<Params...>, (Params...) -> ()>
export type InternalConnection = internal<GenericConnection> & {
	_prev: InternalConnection?,
	_next: InternalConnection?,
	Signal: InternalSignal,
}

-- Signal Types --

-- Base signal type without Fire/Wait signatures
type BaseSignal<Signal, Connection, Signature> = {
	read CancelAllMutations: typeof(
		--[[
			Cancels all deferred mutations that have not yet been processed on the <code>Signal</code>.

			<strong>Note</strong>: Use with care! Can cause memory leaks or other issues if improperly used.
		]]
		function(self: Signal): () end
	),

	read DisconnectAll: typeof(
		--[[
			Disconnects all connections from the <code>Signal</code>.
		]]
		function(self: Signal): () end
	),

	read DisconnectAllNow: typeof(
		--[[
			The immediate mode equivalent of <code>Signal:DisconnectAll()</code>.
		]]
		function(self: Signal): () end
	),

	read Destroy: typeof(
		--[[
			Destroys the <code>Signal</code>, disconnecting all connections in the process, and cancelling further mutations.
		]]
		function(self: Signal): () end
	),

	read DestroyNow: typeof(
		--[[
			The immediate mode equivalent of <code>Signal:Destroy()</code>.
		]]
		function(self: Signal): () end
	),

	read Connect: typeof(
		--[[
			Connects the given function to the <code>Signal</code> and returns a <code>Connection</code> that represents it.
		]]
		function(self: Signal, func: Signature): (Connection) return nil :: any end
	),

	read ConnectNow: typeof(
		--[[
			The immediate mode equivalent of <code>Signal:Connect()</code>.
		]]
		function(self: Signal, func: Signature): (Connection) return nil :: any end
	),

	read Once: typeof(
		--[[
			Connects the given function to the <code>Signal</code> for a single invocation and returns a <code>Connection</code> that represents it.
		]]
		function(self: Signal, func: Signature): (Connection) return nil :: any end
	),

	read OnceNow: typeof(
		--[[
			The immediate mode equivalent of <code>Signal:Once()</code>.
		]]
		function(self: Signal, func: Signature): (Connection) return nil :: any end
	),

	read GetConnections: typeof(
		--[[
			Returns an array of active <code>Connection</code>s on this <code>Signal</code> ordered from oldest to newest.
		]]
		function(self: Signal): ({Connection}) return nil :: any end
	),
}

export type Signal<Signature = DefaultSignature> = BaseSignal<Signal<Signature>, Connection<Signature>, Signature> & {
	-- UDTF-generated Signatures
	read Fire: SignalFireSignature<Signature>,
	read FireNow: SignalFireSignature<Signature>,
	read Wait: SignalWaitSignature<Signature>,
	read WaitNow: SignalWaitSignature<Signature>,
}

export type GenericSignal<Params... = ...any> = BaseSignal<
	GenericSignal<Params...>,
	GenericConnection<Params...>,
	((Params...) -> ())
> & {
	-- Generic Signatures
	read Fire: typeof(
		--[[
			Calls all connected functions and resumes all waiting threads with the given arguments.
		]]
		function(self: GenericSignal<Params...>, ...: Params...) end
	),
	read FireNow: typeof(
		--[[
			The immediate mode equivalent of <code>Signal:Fire()</code>.
		]]
		function(self: GenericSignal<Params...>, ...: Params...) end
	),
	read Wait: typeof(
		--[[
			Yields the calling thread until the <code>Signal</code> fires, and returns any arguments provided by it.
		]]
		function(self: GenericSignal<Params...>, ...: Params...) end
	),
	read WaitNow: typeof(
		--[[
			The immediate mode equivalent of <code>Signal:Wait()</code>.
		]]
		function(self: GenericSignal<Params...>, ...: Params...) end
	),
}

-- We don't need to use internal UDTF here as there is no read-only public API that we write to.
export type InternalSignal = GenericSignal & {
	_head: InternalConnection?,
	_tail: InternalConnection?,
	_firing: true?,
	_mutations: {
		-- [mutation depth]: {...}
		[number]: {SignalMutation}
	},
	_wrapConnection: RBXScriptConnection?,

	-- Used to preserve iteration when an immediate-mode disconnection happens.
	_pTail: InternalConnection?,
}

export type WrapSignal<OtherSignal> = Signal<SignatureFromSignal<OtherSignal>>
export type WrapConnection<OtherSignal> = Connection<SignatureFromSignal<OtherSignal>>

return nil