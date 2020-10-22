Class {
	#name : #CogILTest,
	#superclass : #TestCase,
	#instVars : [
		'sim',
		'cogit',
		'gdb'
	],
	#pools : [
		'CogAbstractRegisters'
	],
	#category : #'VMMaker-Tests'
}

{ #category : #running }
CogILTest >> actuallyRunCPUCode [
	| stopReason |
	gdb := cogit objectMemory memory gdb.
	gdb pc: self initialPC.
	cogit processor runInMemory: cogit objectMemory memory
]

{ #category : #running }
CogILTest >> armSimulator [
	^CogVMSimulatorLSB newWithOptions: #(
										Cogit StackToRegisterMappingCogit
										ObjectMemory Spur32BitCoMemoryManager
										haltOnExecuteMethod false
										MULTIPLEBYTECODESETS true
										ISA ARMv5
										)
]

{ #category : #running }
CogILTest >> askSimulator [
	^CogVMSimulator newWithOptions: #(
										Cogit StackToRegisterMappingCogit
										ObjectMemory Spur32BitCoMemoryManager
										haltOnExecuteMethod false
										MULTIPLEBYTECODESETS true),
										{#ISA. Cogit choose32BitISA}
]

{ #category : #thinshell }
CogILTest >> exitCodePtr [
	^16rCA20004
]

{ #category : #thinshell }
CogILTest >> helloStringPtr [
	^16rCA20028
]

{ #category : #thinshell }
CogILTest >> initialPC [
	^16r22000
]

{ #category : #running }
CogILTest >> powerSimulator [
	^CogVMSimulatorLSB newWithOptions: #(
										Cogit StackToRegisterMappingCogit
										ObjectMemory Spur32BitCoMemoryManager
										haltOnExecuteMethod false
										MULTIPLEBYTECODESETS true
										ISA POWER
										)
]

{ #category : #thinshell }
CogILTest >> printCodePtr [
	^16rCA20010
]

{ #category : #running }
CogILTest >> runCPUCode [
	cogit outputInstructionsForGeneratedRuntimeAt: self initialPC.
	^self actuallyRunCPUCode 
]

{ #category : #running }
CogILTest >> segfault [
	cogit JumpFull: 1
]

{ #category : #running }
CogILTest >> setUp [ 
	| objMem |
	sim := self simulator.
	cogit := sim cogit.
	objMem := cogit objectMemory.
	objMem edenBytes: 0.
	objMem setHeapBase: 16r1D7BD8 memoryLimit: 16r6257BD8 endOfMemory: 16r4E373D0.
	objMem allocateMemoryOfSize: objMem memoryLimit.
	gdb := objMem memory gdb.
	sim setThinshellForTest.
	cogit preInitializeCodeZoneFrom: 131072 upTo: 2228224.

	cogit allocateOpcodes: 20 bytecodes: 0
]

{ #category : #running }
CogILTest >> simulator [
	"This is all crap.
	What needs to happen is we ask the remote GDB target what it is.
	For that, we'll have to rework the shape how Cogit instantiates the processor."
	^self askSimulator 
	
]

{ #category : #running }
CogILTest >> tearDown [
	"gdb isAlive ifFalse: [ ^self ].
	gdb setRegister: 'pc' to: self exitCodePtr.
	[gdb c] on: GdbChildExited do: [^self].
	self error"
]

{ #category : #'tests - arithmetic' }
CogILTest >> testAddCqR [
	cogit MoveCq: 100 R: 1.
	cogit AddCw: 111111 R: 1.
	self segfault.

	self runCPUCode.
	self assert: (gdb getRegister: 'r1') equals: 111211
]

{ #category : #'tests - arithmetic' }
CogILTest >> testAddOverflow [
	"THIS TEST DOES NOT WORK."
	| j p |
	cogit MoveCw: 16r7F11AAAA R: 9.
	cogit AddCq: 16r05000000 R: 9.
	j := cogit JumpOverflow: 1.
	self segfault.
	p := cogit MoveCq: self helloStringPtr R: 5.
	cogit CallFull: self printCodePtr.
	j jmpTarget: p.
	self segfault.

	self runCPUCode.
	self assert: (gdb getRegister: 'r9') equals: 111211
]

{ #category : #'tests - control' }
CogILTest >> testCallFull [
	"Call print(), and after it returns, call exit().
	On the gem5 side, you should see the '****** TEST ******' message
	followed by 'Exit code is 42'.
	"
	cogit MoveCq: self helloStringPtr R: 5.
	cogit CallFull: self printCodePtr.
	cogit CallFull: self exitCodePtr.
	
	[ self runCPUCode ] on: GdbChildExited do: [ ^self ]
]

{ #category : #'tests - control' }
CogILTest >> testCmpJumpNE1 [
	cogit allocateOpcodes: 10 bytecodes: 0.
	cogit MoveCq: 2 R: 1.
	cogit CmpCq: 1 R: 1.
	cogit JumpNonZero: 16r1.
	cogit Stop.
	
	cogit outputInstructionsForGeneratedRuntimeAt: self initialPC.
	self runCPUCode.
	

	gdb halt
]

{ #category : #'tests - control' }
CogILTest >> testCmpJumpNE2 [
	cogit allocateOpcodes: 10 bytecodes: 0.
	cogit MoveCq: 2 R: 1.
	cogit CmpCq: 2 R: 1.
	cogit JumpNonZero: 16r1.
	cogit Stop.
	
	cogit outputInstructionsForGeneratedRuntimeAt: self initialPC.
	self runCPUCode.
	

	gdb halt
]

{ #category : #'tests - control' }
CogILTest >> testJumpFull [
	"Call exit().
	On the gem5 side, you should see 'Exit code is 42'.
	"
	cogit JumpFull: self exitCodePtr.
	
	[ self runCPUCode ] on: GdbChildExited do: [ ^self ]
]

{ #category : #'tests - control' }
CogILTest >> testJumpFullBiggestNegative [
	cogit allocateOpcodes: 1 bytecodes: 0.
	cogit JumpFull: 16rFE000000.
	
	cogit outputInstructionsForGeneratedRuntimeAt: self initialPC.
	self runCPUCode.
	

	gdb halt
]

{ #category : #'tests - combinations' }
CogILTest >> testLoop10Times [
	"Call print() 10 times, then call exit()."
	| l |
	cogit MoveCq: self helloStringPtr R: 5.
	cogit MoveCq: 10 R: 10.
	l := cogit CallFull: self printCodePtr.
	cogit SubCq: 1 R: 10.
	cogit JumpGreater: l.
	cogit CallFull: self exitCodePtr.
	
	[ self runCPUCode ] on: GdbChildExited do: [ ^self ]
]

{ #category : #'tests - combinations' }
CogILTest >> testLoop10Times_ [
	"Variation on the sibling test:
	this time, instead of closing the loop conditionally,
	jump to exit() if reached 0, and loop unconditionally."
	| l |
	cogit MoveCq: self helloStringPtr R: 5.
	cogit MoveCq: 10 R: 10.
	l := cogit CallFull: self printCodePtr.
	cogit SubCq: 1 R: 10.
	cogit JumpZero: self exitCodePtr.
	cogit Jump: l.
	
	[ self runCPUCode ] on: GdbChildExited do: [ ^self ]
]

{ #category : #'tests - combinations' }
CogILTest >> testLoopCmpC32 [
	"Call print() while R10 > 5"
	| l |
	cogit MoveCq: self helloStringPtr R: 5.
	cogit MoveCq: 10 R: 10.
	l := cogit CallFull: self printCodePtr.
	cogit SubCq: 1 R: 10.
	cogit CmpC32: 5 R: 10.
	cogit JumpGreater: l.
	cogit CallFull: self exitCodePtr.
	
	[ self runCPUCode ] on: GdbChildExited do: [ ^self ]
]

{ #category : #'tests - control' }
CogILTest >> testMoveCmpCq1 [
	| cr0 |
	cogit allocateOpcodes: 20 bytecodes: 0.
	cogit MoveCq: 1 R: 1.
	cogit CmpCq: 2 R: 1.
	
	cogit MoveAw: 16r7 R: 0.
	cogit outputInstructionsForGeneratedRuntimeAt: self initialPC.
	self runCPUCode.
	
	cr0 := (gdb getRegister: 'cr') >> 28. "most-sig nibble; LT GT EQ SO"
	self assert: cr0 equals: 8.
	gdb kill
]

{ #category : #'tests - control' }
CogILTest >> testMoveCmpCq2 [
	| cr0 |
	cogit allocateOpcodes: 20 bytecodes: 0.
	cogit MoveCq: 2 R: 1.
	cogit CmpCq: 2 R: 1.
	
	cogit MoveAw: 16r7 R: 0.
	cogit outputInstructionsForGeneratedRuntimeAt: self initialPC.
	self runCPUCode.
	
	cr0 := (gdb getRegister: 'cr') >> 28. "most-sig nibble; LT GT EQ SO"
	self assert: cr0 equals: 2.
	gdb kill
]

{ #category : #'tests - data movement' }
CogILTest >> testMoveCqR_full [
	cogit MoveCq: 12345678 R: 1.
	
	self segfault.
	self runCPUCode.
	self assert: (gdb getRegister: 'r1') equals: 12345678
]

{ #category : #'tests - data movement' }
CogILTest >> testMoveCqR_quick [
	cogit MoveCq: 5 R: 1.
	
	self segfault.
	self runCPUCode.
	self assert: (gdb getRegister: 'r1') equals: 5
]

{ #category : #'tests - data movement' }
CogILTest >> testMoveRR [
	cogit MoveCq: 500000 R: 10.
	cogit MoveR: 10 R: 11.
	
	self segfault.
	self runCPUCode.
	self assert: (gdb getRegister: 'r11') equals: 500000
]

{ #category : #'tests - control' }
CogILTest >> testRelativeJumpIfEq [
	| l |
	l := cogit MoveCq: 256 R: 1.
	l breakHW.
	cogit MoveCq: 1 R: 1.
	cogit AndCq: 2 R: 1.
	cogit JumpZero: l.
	cogit AddCq: 3 R: 5.
	
	[ self runCPUCode ] on: GdbChildExited do: [ ^self ]
]
