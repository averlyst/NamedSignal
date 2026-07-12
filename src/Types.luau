--!strict

-- Type Functions --

--[[
	Makes all read-only or write-only properties to be both writable and readable.
]]
type function internal(ty: type): (type)
	const function processType(t: type): (type)
		const tTag = t.tag
		if tTag == "table" then
			for keyType, rwType in t:properties() do
				t:setproperty(
					keyType,
					processType(rwType.read or rwType.write :: type)
				)
			end
			
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

type function SignalFireSignature(signal: type, signature: type, fallback: type): (type)
	const signatureTag = signature.tag
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

type function SignalWaitSignature(signal: type, signature: type, fallback: type): (type)
	const signatureTag = signature.tag
	if signatureTag ~= "function" then
		print(`Signal<Signature> expects a 'function' type for \`Signature\`, got '{signatureTag}' type instead.`)
		return fallback
	end

	return types.newfunction(
		{head = {signal}}, -- parameters
		signature:parameters() -- returns
	)
end

-- Extracts the connection signature from a given RBXScriptSignal if available.
type function SignatureFromRBXScriptSignal(rbxSignal: type, fallback: type): (type)
	const rbxSignalTag = rbxSignal.tag
	
	-- In Roblox, RBXScriptSignals are externtypes, while in Luau LSP they are tabletypes.
	local connectSignature: type?
	if rbxSignalTag == "any" then
		return fallback
	elseif rbxSignalTag == "extern" then
		-- for some reason we can't use readproperty on externtype
		for keytype, rwType in rbxSignal:properties() do
			if keytype:value() == "Connect" then
				connectSignature = rwType.read
				break
			end
		end
		
		if not connectSignature then
			print(`WrapSignal<RbxSignal> expects a 'RBXScriptSignal' type for \`RbxSignal\`, got '{rbxSignalTag}' type instead.`)
			return fallback
		end
	elseif rbxSignalTag == "table" then
		connectSignature = rbxSignal:readproperty(types.singleton("Connect"))
	else
		print(`WrapSignal<RbxSignal> expects a 'RBXScriptSignal' type for \`RbxSignal\`, got '{rbxSignalTag}' type instead.`)
		return fallback
	end
	
	if not connectSignature or connectSignature.tag ~= "function" then
		print(`WrapSignal<RbxSignal> expects a 'RBXScriptSignal' type for \`RbxSignal\`, got invalid Connect signature.`)
		return fallback
	end

	const connectHead = connectSignature:parameters().head
	if not connectHead then
		print(`WrapSignal<RbxSignal> expects a 'RBXScriptSignal' type for \`RbxSignal\`, got headless Connect signature.`)
		return fallback
	end

	const callback = connectHead[2] -- first param is self
	if not callback or callback.tag ~= "function" then
		print(`WrapSignal<RbxSignal> expects a 'RBXScriptSignal' type for \`RbxSignal\`, got invalid callback signature.`)
		return fallback
	end

	return callback
end

-- Connection Type --
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
}

export type Connection<Signature = LooseSignature> = BaseConnection<Signal<Signature>, Signature>
export type GenericConnection<Params...> = BaseConnection<GenericSignal<Params...>, (Params...) -> ()>
export type InternalConnection = internal<Connection> & {
	_prev: InternalConnection?,
	_next: InternalConnection?,
	Signal: InternalSignal,
}

-- Signal Types --
export type LooseSignature = (...any) -> ()

export type SignalMutation = {
	f: ((InternalSignal | InternalConnection | thread, InternalSignal?) -> ())?, -- for any mutation that isn't fire
	c: InternalConnection?, -- for connection operations
	a: {any}?, -- array of stored arguments from deferred fire
}

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
}

export type Signal<Signature = LooseSignature> = BaseSignal<Signal<Signature>, Connection<Signature>, Signature> & {
	-- UDTF-generated Signatures
	-- Currently, UDTFs do not support self-recursion (impossible to reduce), so we use `any` in place of it for now.
	-- This still allows the methods to show up in autocomplete, and `self` not being checked is not a huge deal.
	read Fire: SignalFireSignature<any, Signature, LooseSignature>,
	read FireNow: SignalFireSignature<any, Signature, LooseSignature>,
	read Wait: SignalWaitSignature<any, Signature, LooseSignature>,
	read WaitNow: SignalWaitSignature<any, Signature, LooseSignature>,
}

-- We don't need to use internal UDTF here as there is no read-only public API that we write to.
export type InternalSignal = Signal & {
	_head: InternalConnection?,
	_tail: InternalConnection?,
	_firing: true?,
	_mutations: {
		{SignalMutation} -- [re-entrancy depth]: ...
	},
	_wrapConnection: RBXScriptConnection?,
	
	-- This is when a once connection is the tail of a signal, for fixing an iterator invalidation edge case.
	-- A bit of an ugly solution, but I couldn't come up with a better one. Please create an issue or PR if you know of a better way.
	_onceTail: InternalConnection?,
}

export type GenericSignal<Params... = ...any> = BaseSignal<GenericSignal<Params...>, GenericConnection<Params...>, (Params...) -> ()> & {
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

export type WrapSignal<RBXSignal> = Signal<SignatureFromRBXScriptSignal<RBXSignal, LooseSignature>>
export type WrapConnection<RBXSignal> = Connection<SignatureFromRBXScriptSignal<RBXSignal, LooseSignature>>

return nil