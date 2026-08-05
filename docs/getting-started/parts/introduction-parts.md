<!-- markdownlint-disable-file MD041 -->

## Footnotes

### Parameter Name

<!-- #region footnote-performance-details -->
Additional implementation details and benchmarks are covered in the [dedicated section](/additional-info/performance).
<!-- #endregion footnote-performance-details -->

## Shared Comparisons

<table>
	<thead>
		<tr>
			<th>Feature</th><th>NamedSignal</th><th>Other Library</th>
		</tr>
	</thead>
	<tbody>
		<!-- #region comparison-generic-typecheck -->
		<tr>
			<td rowspan="2">Type-checking</td>
			<td><b><a href="/NamedSignal/api-reference/api-overview#signal-type">Named Parameters</a> and <a href="/NamedSignal/api-reference/api-overview#wrapsignal-type">Wrap</a> Inference</b></td>
			<td><b>Standard Generic Types</b></td>
		</tr>
		<tr>
			<td>Uses <a href="https://luau.org/types/type-functions/">type functions</a> to facilitate enhanced type information, supporting parameter names and <code>Signal.wrap()</code> inference.<hr>Reduces the need to refer to documentation to identify parameters.</td>
			<td>Has type-checking but lacks parameter names.<hr>Necessitates referral to documentation when types alone are insufficient.</td>
		</tr>
		<!-- #endregion comparison-generic-typecheck -->
		<!-- #region comparison-thread-edge-cases -->
		<tr>
			<td rowspan="2">Thread Edge Cases</td>
			<td><b>✅ Safely caught and handled</b></td>
			<td><b>⚠️ No <code>coroutine.status</code> check</b></td>
		</tr>
		<tr>
			<td>Cached threads are checked before reuse, ensuring listeners are always dispatched correctly.</td>
			<td>Doesn't check thread status before reuse, may cause dispatch to fail if a thread is closed externally.</td>
		</tr>
		<!-- #endregion comparison-thread-edge-cases -->
		<!-- #region comparison-thread-reuse -->
		<tr>
			<td><b>Multi Thread Reuse</b></td>
			<td><b>Single Thread Reuse</b></td>
		</tr>
		<tr>
			<td>Reuses all created threads to reduce overhead and churn for asynchronous listeners.</td>
			<td>Reuses a single thread, faster than naive (no cache) for synchronous listeners, but slow churn for async.</td>
		</tr>
		<!-- #endregion comparison-thread-reuse -->
		<!-- #region comparison-minimized-resumption -->
		<tr>
			<td><b>Minimized Resumption (Per Async)</b></td>
			<td><b>Naive Resumption (Per Listener)</b></td>
		</tr>
		<tr>
			<td>Resumes threads only when invocation becomes asynchronous (i.e. a listener yields), greatly improving performance for large non-yielding signals.</td>
			<td>Always resumes a thread per listener, incurring the overhead for each one, which results in poor scaling for multiple connections.</td>
		</tr>
		<!-- #endregion comparison-minimized-resumption -->
	</tbody>
</table>
