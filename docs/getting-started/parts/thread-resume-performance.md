<!-- markdownlint-disable-file MD041 -->

Conservative 3x figure to account for some logging overhead, you may see up to 5x faster performance in raw comparison:

```luau
local iters = 50000

local thread = task.spawn(function()
	while true do
		coroutine.yield()
	end
end)

local t1 = os.clock()
for _ = 1, iters do
	task.spawn(thread)
end
local t2 = os.clock()
for _ = 1, iters do
	coroutine.resume(thread)
end
local t3 = os.clock()

print(`coroutine.resume is {(t2 - t1) / (t3 - t2)}x faster than task.spawn`)
```
