# Gohan's Certification

[Gohan's Certification](https://devforum.roblox.com/t/signal-certifications-classes-guide/4263792) was used during development to validate behavior and establish a set of rules, **NamedSignal v2.0.0 is a Class 2 Signal** under this certification.

## Not Quite to Spec (Intentionally) {#not-quite-to-spec}

Prior to v2.0.0, NamedSignal was a Class 3 signal, however I have slightly deviated from the certification's behavior for re-entrant signal firing. My reasoning for doing so is to have consistent mutation deferral behavior and avoiding artificial limitations.

Specifically, the **certification expects the re-entrant thread calling fire to yield** until all prior events are completed. This is **inconsistent with all other methods**, as connection and disconnection does not yield, and also introduces a potentially dealbreaking limitation — you **cannot use re-entrant fire in unyieldable environments**, commonly seen in metamethods.

This is where NamedSignal v2.0.0 and onwards diverges from the certification, it also **queues firing, but without yielding**, thus making all methods consistently non-yielding.

## Results

```txt
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
🎓 | TESTING: NamedSignal         |  -  Server - Signal_Certifications:1978
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
⚪ | Scheduler Certification |  -  Server - Signal_Certifications:1990
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
☑ | Create                   | Baseline: 1  ▶ {...} | Results: 1  ▶ {...}  -  Server - Signal_Certifications:172
☑ | Connect                  | Baseline: 9  ▶ {...} | Results: 9  ▶ {...}  -  Server - Signal_Certifications:172
☑ | Connect_Safety           | Baseline: 1  ▶ {...} | Results: 1  ▶ {...}  -  Server - Signal_Certifications:172
☑ | Connect_Unit             | Baseline: 1000  ▶ {...} | Results: 1000  ▶ {...}  -  Server - Signal_Certifications:172
☑ | Once                     | Baseline: 4  ▶ {...} | Results: 4  ▶ {...}  -  Server - Signal_Certifications:172
☑ | Once_Safety              | Baseline: 3  ▶ {...} | Results: 3  ▶ {...}  -  Server - Signal_Certifications:172
☑ | Once_Unit                | Baseline: 1000  ▶ {...} | Results: 1000  ▶ {...}  -  Server - Signal_Certifications:172
☑ | Wait                     | Baseline: 1  ▶ {...} | Results: 1  ▶ {...}  -  Server - Signal_Certifications:172
☑ | Wait_Safety              | Baseline: 2  ▶ {...} | Results: 2  ▶ {...}  -  Server - Signal_Certifications:172
☑ | Wait_Unit                | Baseline: 1000  ▶ {...} | Results: 1000  ▶ {...}  -  Server - Signal_Certifications:172
☑ | DisconnectAll_Connect    | Baseline: 0 {} | Results: 0 {}  -  Server - Signal_Certifications:172
☑ | DisconnectAll_Once       | Baseline: 0 {} | Results: 0 {}  -  Server - Signal_Certifications:172
☑ | DisconnectAll_Wait       | Baseline: 0 {} | Results: 0 {}  -  Server - Signal_Certifications:172
☑ | ConsecutiveReentrancy    | Baseline: 5  ▶ {...} | Results: 5  ▶ {...}  -  Server - Signal_Certifications:172
☑ | MultiSignalCNs           | Baseline: 7  ▶ {...} | Results: 7  ▶ {...}  -  Server - Signal_Certifications:172
☑ | MultiSignalNested        | Baseline: 10  ▶ {...} | Results: 10  ▶ {...}  -  Server - Signal_Certifications:172
☑ | MultiSignalDisconnectAll | Baseline: 1  ▶ {...} | Results: 1  ▶ {...}  -  Server - Signal_Certifications:172
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
✅ | Scheduler Certified     |  -  Server - Signal_Certifications:125
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
⚪ | Speed Certification     |  -  Server - Signal_Certifications:2023
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
☑ | Create         | -0.6μs  | Baseline: 0.6μs  ▶ {...} | Results: 0.1μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | Connect        | -0.6μs  | Baseline: 0.8μs  ▶ {...} | Results: 0.2μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | Once           | -0.4μs  | Baseline: 0.7μs  ▶ {...} | Results: 0.2μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | Fire_None      | +0.0μs  | Baseline: 0.1μs  ▶ {...} | Results: 0.1μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | Fire_One       | +0.6μs  | Baseline: 0.4μs  ▶ {...} | Results: 0.9μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | Fire_Many      | -0.1μs  | Baseline: 0.1μs  ▶ {...} | Results: 0.0μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | Fire_OneYield  | +0.5μs  | Baseline: 0.7μs  ▶ {...} | Results: 1.2μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | Fire_ManyYield | +0.8μs  | Baseline: 0.2μs  ▶ {...} | Results: 0.9μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | Disconnect     | -0.1μs  | Baseline: 0.2μs  ▶ {...} | Results: 0.1μs  ▶ {...}  -  Server - Signal_Certifications:225
☑ | DisconnectAll  | -7.1μs  | Baseline: 8.2μs  ▶ {...} | Results: 1.1μs  ▶ {...}  -  Server - Signal_Certifications:225
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
✅ | Speed Certified         |  -  Server - Signal_Certifications:125
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
⚪ | Connected Certification |  -  Server - Signal_Certifications:2076
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
☑ | Connect       | Baseline: 2  ▶ {...} | Results: 2  ▶ {...}  -  Server - Signal_Certifications:172
☑ | Once          | Baseline: 3  ▶ {...} | Results: 3  ▶ {...}  -  Server - Signal_Certifications:172
☑ | DisconnectAll | Baseline: 2  ▶ {...} | Results: 2  ▶ {...}  -  Server - Signal_Certifications:172
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
✅ | Connected Certified     |  -  Server - Signal_Certifications:125
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
⚪ | Snapshot Certification  |  -  Server - Signal_Certifications:2109
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
☑ | BasicOrdering     | Baseline: 1  ▶ {...} | Results: 1  ▶ {...}  -  Server - Signal_Certifications:172
☑ | Disconnect        | Baseline: 4  ▶ {...} | Results: 4  ▶ {...}  -  Server - Signal_Certifications:172
☑ | DisconnectAll     | Baseline: 4  ▶ {...} | Results: 4  ▶ {...}  -  Server - Signal_Certifications:172
☑ | NestedConnections | Baseline: 4  ▶ {...} | Results: 4  ▶ {...}  -  Server - Signal_Certifications:172
☑ | ReentranceSafety  | Baseline: 6  ▶ {...} | Results: 6  ▶ {...}  -  Server - Signal_Certifications:172
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
✅ | Snapshot Certified      |  -  Server - Signal_Certifications:125
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
⚪ | Synchronous Certification |  -  Server - Signal_Certifications:2142
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
☑ | Connect      | Baseline: 3  ▶ {...} | Results: 3  ▶ {...}  -  Server - Signal_Certifications:172
☑ | Wait_Modify  | Baseline: 2  ▶ {...} | Results: 2  ▶ {...}  -  Server - Signal_Certifications:172
☑ | Wait_Chained | Baseline: 1  ▶ {...} | Results: 1  ▶ {...}  -  Server - Signal_Certifications:172
//[!code highlight]
✖ | Fire         | Baseline: 2  ▶ {...} | Results: 2  ▶ {...}  -  Server - Signal_Certifications:172
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
❌ | NOT Synchronous Certified |  -  Server - Signal_Certifications:125
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
⚪ | Order Certification     |  -  Server - Signal_Certifications:2175
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
☑ | Connect    | Baseline: 2  ▶ {...} | Results: 2  ▶ {...}  -  Server - Signal_Certifications:172
☑ | Once       | Baseline: 2  ▶ {...} | Results: 2  ▶ {...}  -  Server - Signal_Certifications:172
☑ | Wait       | Baseline: 2  ▶ {...} | Results: 2  ▶ {...}  -  Server - Signal_Certifications:172
☑ | Mixed      | Baseline: 12  ▶ {...} | Results: 12  ▶ {...}  -  Server - Signal_Certifications:172
☑ | Disconnect | Baseline: 10  ▶ {...} | Results: 10  ▶ {...}  -  Server - Signal_Certifications:172
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
✅ | Order Certified         |  -  Server - Signal_Certifications:125
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
✅ | Signal: Class 2         |  -  Server - Signal_Certifications:2222
--------------------------------------------------------------------------------------  -  Server - Signal_Certifications:1968
```
