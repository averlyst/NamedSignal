--!strict

-- Type Functions --

--[[
	Makes all read-only or write-only properties to be both writable and readable.
]]
type function internal(ty: type)
	const function processType(t: type): (type)
		const tTag = t.tag
		if tTag == "table" then
			-- props
			for keyType, rwType in t:properties() do
				t:setproperty(
					keyType,
					processType(rwType.read or rwType.write :: type)
				)
			end
			
			-- indexer
			const indexer = t:indexer()
			if indexer then
				t:setindexer(
					indexer.index,
					processType(indexer.readresult)
				)
			end
		elseif tTag == "union" then
			const components = t:components()
			for i, component in components do
				components[i] = processType(component)
			end

			return types.unionof(table.unpack(components))
		elseif tTag == "intersection" then
			const components = t:components()
			for i, component in components do
				components[i] = processType(component)
			end

			return types.intersectionof(table.unpack(components))
		end

		return t
	end

	return processType(ty)
end

type function SignalFireSignature(signal: type, signature: type, fallback: type)
	const signatureTag = signature.tag
	if signatureTag == "unknown" then
		return fallback
	end

	if signatureTag ~= "function" then
		print(`Signal<Signature> expects a 'function' type for \`Signature\`, got '{signatureTag}' type instead.`)
		return fallback
	end

	const params = signature:parameters()
	local head = params.head
	if not head then
		head = {} :: {type}
		params.head = head
	end

	table.insert(head :: {type}, 1, signal)
	return types.newfunction(params)
end

type function SignalWaitSignature(signal: type, signature: type, fallback: type)
	const signatureTag = signature.tag
	if signatureTag == "unknown" then
		return fallback
	end

	if signatureTag ~= "function" then
		print(`Signal<Signature> expects a 'function' type for \`Signature\`, got '{signatureTag}' type instead.`)
		return fallback
	end

	return types.newfunction(
		{head = {signal}}, -- parameters
		signature:parameters() -- returns
	)
end

-- Connection Type --
export type Connection<Signature = () -> ()> = {
	read Signal: Signal<Signature>,
	read Connected: boolean,
	read Callback: Signature,
	
	read Disconnect: typeof(
		--[[
			Disconnects the <code>Connection</code> from the <code>Signal</code>.
		]]
		function(self: Connection<Signature>): () end
	),
	read DisconnectNow: typeof(
		--[[
			The immediate mode equivalent of <code>Connection:Disconnect()</code>.
		]]
		function(self: Connection<Signature>): () end
	),
	
	read Reconnect: typeof(
		--[[
			Reconnects the <code>Connection</code> to the <code>Signal</code>.
		]]
		function(self: Connection<Signature>): () end
	),
	read ReconnectNow: typeof(
		--[[
			The immediate mode equivalent of <code>Connection:Reconnect()</code>.
		]]
		function(self: Connection<Signature>): () end
	),
	
	read Destroy: typeof(
		--[[
			Destroys the <code>Connection</code>.
		]]
		function(self: Connection<Signature>): () end
	),
}

export type InternalConnection = internal<Connection> & {
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
}

export type Signal<Signature = (...unknown) -> ()> = BaseSignal<Signal<Signature>, Connection<Signature>, Signature> & {
	-- UDTF generated Signatures
	read Fire: SignalFireSignature<any, Signature, (...unknown) -> ()>,
	read FireNow: SignalFireSignature<any, Signature, (...unknown) -> ()>,
	read Wait: SignalWaitSignature<any, Signature, (...unknown) -> ()>,
	read WaitNow: SignalWaitSignature<any, Signature, (...unknown) -> ()>,
}

export type SignalMutation = {
	f: ((InternalSignal | InternalConnection | thread, InternalSignal?) -> ())?, -- for any mutation that isn't fire
	c: InternalConnection?, -- for connection operations
	p: thread?, -- yielded thread that returns the stored parameters for deferred fire when resumed.
}

export type InternalSignal = Signal & {
	_head: InternalConnection?,
	_tail: InternalConnection?,
	_firing: true?,
	_mutations: {
		{SignalMutation} -- [re-entrancy depth]: ...
	},
}

export type GenericSignal<Params... = ...unknown> = BaseSignal<GenericSignal<Params...>, Connection<(Params...) -> ()>, (Params...) -> ()> & {
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

return nil