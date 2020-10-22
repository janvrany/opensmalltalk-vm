"
I generate POWER instructions from CogAbstractInstructions.
"
Class {
	#name : #CogPOWERCompiler,
	#superclass : #CogAbstractInstruction,
	#instVars : [
		'conditionOrNil'
	],
	#classVars : [
		'AL',
		'CArg0Reg',
		'CArg1Reg',
		'CArg2Reg',
		'CArg3Reg',
		'CC',
		'CMPSMULL',
		'CPSRReg',
		'CS',
		'ConcreteIPReg',
		'ConcretePCReg',
		'ConcreteVarBaseReg',
		'EQ',
		'GE',
		'GT',
		'HI',
		'LDMFD',
		'LE',
		'LR',
		'LS',
		'LT',
		'MI',
		'MRS',
		'MSR',
		'MulRR',
		'NE',
		'OverflowFlag',
		'PC',
		'PL',
		'PopLDM',
		'R0',
		'R1',
		'R10',
		'R11',
		'R12',
		'R2',
		'R3',
		'R4',
		'R5',
		'R6',
		'R7',
		'R8',
		'R9',
		'SMULL',
		'SP',
		'STMFD',
		'VC',
		'VS'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #accessing }
CogPOWERCompiler class >> IPReg [
	"Answer the number of the general temp reg in the ARM APCS convention, IP"
	^ConcreteIPReg
]

{ #category : #translation }
CogPOWERCompiler class >> ISA [
	"Answer the name of the ISA the receiver implements."
	^#POWER
]

{ #category : #accessing }
CogPOWERCompiler class >> PCReg [
	^ConcretePCReg
]

{ #category : #accessing }
CogPOWERCompiler class >> VarBaseReg [
	"Answer the number of the reg we use to hold the base address of CoInterpreter variables"
	^ConcreteVarBaseReg
]

{ #category : #'TA Assembler' }
CogPOWERCompiler class >> compiler [
	^super compiler addPlugin: PDLOpalPlugin 
]

{ #category : #translation }
CogPOWERCompiler class >> defaultCompilerClass [
	^CogPOWERCompiler
]

{ #category : #translation }
CogPOWERCompiler class >> filteredInstVarNames [
	"Edit such that conditionOrNil is amongst the char size vars opcode machineCodeSize and maxSize."
	^(super filteredInstVarNames copyWithout: 'conditionOrNil')
		copyReplaceFrom: 5 to: 4 with: #('conditionOrNil')
]

{ #category : #translation }
CogPOWERCompiler class >> identifyingPredefinedMacros [
	^#('__ARM_ARCH_5__' '__ARM_ARCH_6__' '__ARM_ARCH_7__' '__arm__' '__arm32__' 'ARM32' '_M_ARM')
]

{ #category : #'class initialization' }
CogPOWERCompiler class >> initialize [

	"Initialize various ARM instruction-related constants."
	"CogPOWERCompiler initialize"

	super initialize.
	self ~~ CogPOWERCompiler ifTrue: [^self].

	"ARM general registers"
	R0 := 0.
	R1 := 1.
	R2 := 2.
	R3 := 3.
	R4 := 4.
	R5 := 5.
	R6 := 6.
	R7 := 7.
	R8 := 8.
	R9 := 9.
	R10 := 10.
	R11 := 11.
	R12 := 12.
	SP := 13.
	LR := 14.
	PC := 15.

	CArg0Reg := 1.
	CArg1Reg := 2.
	CArg2Reg := 3.
	CArg3Reg := 4.

	ConcreteVarBaseReg := 10.
	ConcreteIPReg := 12. "IP, The Intra-Procedure-call scratch register."
	ConcretePCReg := 15.

	"Condition Codes. Note that cc=16rF is NOT ALLOWED as a condition; it specifies an extension instruction. See e.g.ARM_ARM v5 DDI01001.pdf A3.2.1"
	EQ := 0.
	NE := 1.
	CS := 2.
	CC := 3.
	MI := 4.
	PL := 5.
	VS := 6.
	VC := 7.
	HI := 8.
	LS := 9.
	GE := 10.
	LT := 11.
	GT := 12.
	LE := 13.
	AL := 14.

	CPSRReg := 16.
	OverflowFlag := 1 << 28.

	"Specific instructions"
	self
		initializeSpecificOpcodes: #(SMULL MSR MRS PopLDM LDMFD STMFD CMPSMULL MulRR)
		in: thisContext method
]

{ #category : #'class initialization' }
CogPOWERCompiler class >> initializeAbstractRegisters [
	"Assign the abstract registers with the identities/indices of the relevant concrete registers."

	super initializeAbstractRegisters.

	"According to IHI0042E ARM Architecture Procedure Calling Standard, in section 5.1.1:
		A subroutine must preserve the contents of the registers r4-r8, r10, r11 and SP (and r9 in PCS variants that designate r9 as v6).
	 SP = r13, so the callee-saved regs are r4-r8 & r10-r12.
	 The caller-saved registers are those that are not callee-saved and not reserved for hardware/abi uses,
	 i..e r0-r3, r9 & r12.
	 We exclude registers 0 & 1 (TempReg/CArg0Reg & CArg1Reg) from the CallerSavedRegisterMask because we only
	 use them for argument passing and so never want to save and restore them.  In fact restoring TempReg/CArg0Reg
	 would overwrite function results, so it shouldn't be included under any circumstances."

	CallerSavedRegisterMask := 0. "BOGUS" "self registerMaskFor: ``0 and: 1 and:`` 2 and: 3 and: 9 and: 12."

	TempReg			:= 30.
	ClassReg			:= 22.
	ReceiverResultReg	:= R5.
	SendNumArgsReg	:= R6.
	SPReg				:= SP. "a.k.a. R13" self assert: SP = 13.
	FPReg				:= R11.
	Arg0Reg			:= R3. "overlaps with last C arg reg"
	Arg1Reg			:= R4.
	Extra0Reg			:= R7.
	Extra1Reg			:= R8.
	Extra2Reg			:= R9.
	VarBaseReg		:= R10.	"Must be callee saved" self assert: ConcreteVarBaseReg = R10.
	RISCTempReg		:= R12.	"a.k.a. IP" self assert: ConcreteIPReg = R12.
	LinkReg				:= LR. "R14"
	PCReg				:= PC. "R15"	

	NumRegisters := 32
]

{ #category : #testing }
CogPOWERCompiler class >> isAbstract [
	^self == CogPOWERCompiler
]

{ #category : #testing }
CogPOWERCompiler class >> isRISCTempRegister: reg [
	"For tests to filter-out bogus values left in the RISCTempRegister, if any."
	^reg = ConcreteIPReg
]

{ #category : #translation }
CogPOWERCompiler class >> machineCodeDeclaration [
	"Answer the declaration for the machineCode array.
	 ARM instructions are 32-bits in length."
	^{#'unsigned int'. '[', self basicNew machineCodeWords printString, ']'}
]

{ #category : #'class initialization' }
CogPOWERCompiler class >> specificOpcodes [
	"Answer the processor-specific opcodes for this class.
	 They're all in an Array literal in the initialize method."
	^(self class >> #initialize) literals detect: [:l| l isArray and: [l includes: #LDMFD]]
]

{ #category : #'TA Assembler' }
CogPOWERCompiler class >> template [
	^CogPOWERCompiler >> #templateMethod
]

{ #category : #translation }
CogPOWERCompiler class >> wordSize [
	"This is a 32-bit ISA"
	^4
]

{ #category : #'register allocation' }
CogPOWERCompiler >> availableRegisterOrNoneFor: liveRegsMask [
	"Answer an unused abstract register in the liveRegMask.
	 Subclasses with more registers can override to answer them.
	 N.B. Do /not/ allocate TempReg."
	<returnTypeC: #sqInt>
	(cogit register: Extra0Reg isInMask: liveRegsMask) ifFalse:
		[^Extra0Reg].
	(cogit register: Extra1Reg isInMask: liveRegsMask) ifFalse:
		[^Extra1Reg].
	(cogit register: Extra2Reg isInMask: liveRegsMask) ifFalse:
		[^Extra2Reg].
	^super availableRegisterOrNoneFor: liveRegsMask
]

{ #category : #'TA Assembler' }
CogPOWERCompiler >> bogusComputeHi [
	^address bogusComputeHi 
]

{ #category : #'TA Assembler' }
CogPOWERCompiler >> bogusComputeHiCarry [
	^address bogusComputeHiCarry 
]

{ #category : #'TA Assembler' }
CogPOWERCompiler >> bogusComputeLo [
	^address bogusComputeLo 
]

{ #category : #testing }
CogPOWERCompiler >> byteReadsZeroExtend [
	"on POWER we use Load Byte and Zero (lbz)"
	^true
]

{ #category : #abi }
CogPOWERCompiler >> cResultRegister [
	"Answer the register through which C funcitons return integral results."
	<inline: true>
	^R0
]

{ #category : #sizing }
CogPOWERCompiler >> callInstructionByteSize [
	^4*4 "bl; mflr; addi; ba"
]

{ #category : #'inline cacheing' }
CogPOWERCompiler >> callTargetFromReturnAddress: callSiteReturnAddress [
	"Unconditional call"
	| instr_ |
	self assert: (self instructionAt: callSiteReturnAddress-16) name = 'bl'.
	self assert: (self instructionAt: callSiteReturnAddress-12) name = 'mfspr'.
	self assert: (self instructionAt: callSiteReturnAddress-8)  name = 'addi'.
	instr_ := self instructionAt: callSiteReturnAddress-4.
	self assert: instr_ name = 'ba'.
	^(instr_ fieldValue: 'li')*4
]

{ #category : #testing }
CogPOWERCompiler >> canDivQuoRem [
	^false
]

{ #category : #testing }
CogPOWERCompiler >> canMulRR [
"we can do a MulRR be we can't simulate it correctly for some reason. More bug-fixing in the simulator one day"
	^true
]

{ #category : #testing }
CogPOWERCompiler >> canPushPopMultipleRegisters [
	<inline: true>
	^false
]

{ #category : #sizing }
CogPOWERCompiler >> cmpC32RTempByteSize [
	^12
]

{ #category : #sizing }
CogPOWERCompiler >> codeGranularity [
	"Answer the size in bytes of a unit of machine code."
	<inline: true>
	^4
]

{ #category : #sizing }
CogPOWERCompiler >> computeMaximumSize [
	"Because we don't use Thumb, each ARM instruction has 4 bytes. Many
	 abstract opcodes need more than one instruction. Instructions that refer
	 to constants and/or literals depend on literals being stored in-line or out-of-line.

	 N.B.  The ^N forms are to get around the bytecode compiler's long branch
	 limits which are exceeded when each case jumps around the otherwise."

	opcode
		caseOf: {
		"Noops & Pseudo Ops"
		[Label]					-> [^0].
		[Literal]					-> [^4].
		[AlignmentNops]		-> [^(operands at: 0) - 4].
		[Fill32]					-> [^4].
		[Nop]					-> [^4].
		"Control"
		[Call]					-> [^4*4].
		[CallFull]				-> [^7*4].
		[JumpR]					-> [^8].
		[Jump]					-> [^4*4].
		[JumpFull]				-> [^4*4].
		[JumpLong]				-> [^4*4].
		[JumpZero]				-> [^8].
		[JumpNonZero]			-> [^8].
		[JumpNegative]			-> [^8].
		[JumpNonNegative]		-> [^8].
		[JumpOverflow]			-> [^8].
		[JumpNoOverflow]		-> [^8].
		[JumpCarry]			-> [^8].
		[JumpNoCarry]			-> [^8].
		[JumpLess]				-> [^8].
		[JumpGreaterOrEqual]	-> [^8].
		[JumpGreater]			-> [^8].
		[JumpLessOrEqual]		-> [^8].
		[JumpBelow]			-> [^8].
		[JumpAboveOrEqual]	-> [^8].
		[JumpAbove]			-> [^8].
		[JumpBelowOrEqual]	-> [^8].
		[JumpLongZero]		-> [^8].
		[JumpLongNonZero]	-> [^8].
		[JumpFPEqual]			-> [^8].
		[JumpFPNotEqual]		-> [^8].
		[JumpFPLess]			-> [^8].
		[JumpFPGreaterOrEqual]-> [^8].
		[JumpFPGreater]		-> [^8].
		[JumpFPLessOrEqual]	-> [^8].
		[JumpFPOrdered]		-> [^8].
		[JumpFPUnordered]		-> [^8].
		[RetN]					-> [^12].
		[Stop]					-> [^4].

		"Arithmetic"
		[AddCqR]				-> [^(operands at: 0) fitsInSigned16 ifTrue: [4] ifFalse: [8]].
		[AndCqR]				-> [^(operands at: 0) fitsInUnsigned16 ifTrue: [4] ifFalse: [12]].
		[AndCqRR]				-> [^8].
		[CmpCqR]				-> [^12].
		[OrCqR]					-> [^12].
		[SubCqR]				-> [^12].
		[TstCqR]				-> [^12].
		[XorCqR]				-> [^12].
		[AddCwR]				-> [^8].
		[AndCwR]				-> [^12].
		[CmpCwR]				-> [^12].
		[OrCwR]				-> [^12].
		[SubCwR]				-> [^12].
		[XorCwR]				-> [^12].
		[AddRR]					-> [^8].
		[AndRR]					-> [^4].
		[CmpRR]				-> [^4].
		[OrRR]					-> [^4].
		[XorRR]					-> [^4].
		[SubRR]					-> [^4].
		[NegateR]				-> [^4].
		[LoadEffectiveAddressMwrR]		-> [^8].
		[LogicalShiftLeftCqR]		-> [^4].
		[LogicalShiftRightCqR]		-> [^4].
		[ArithmeticShiftRightCqR]	-> [^4].
		[LogicalShiftLeftRR]			-> [^4].
		[LogicalShiftRightRR]		-> [^4].
		[ArithmeticShiftRightRR]		-> [^4].
		[MulRR]				-> [^4].
		"Data Movement"						
		[MoveCqR]				-> [(operands at: 0) fitsInSigned16 ifTrue: [^4] ifFalse: [^8]].
		[MoveCwR]				-> [^8].
		[MoveRR]				-> [^4].
		[MoveRdRd]				-> [^4].
		[MoveAwR]				-> [^8].
		[MoveRAw]				-> [^12].
		[MoveAbR]				-> [^(self isAddressRelativeToVarBase: (operands at: 0))
													ifTrue: [4]
													ifFalse: [self literalLoadInstructionBytes + 4]].
		[MoveRAb]				-> [^(self isAddressRelativeToVarBase: (operands at: 1))
													ifTrue: [4]
													ifFalse: [self literalLoadInstructionBytes + 4]].
		[MoveRMwr]			-> [^12].
		[MoveRdM64r]			-> [^self literalLoadInstructionBytes + 4]. 
		[MoveMbrR]				-> [^16].
		[MoveRMbr]				-> [^self is12BitValue: (operands at: 1)
										ifTrue: [:u :i| 4]
										ifFalse: [self literalLoadInstructionBytes + 4]].
		[MoveRM16r]				-> [^12].
		[MoveM16rR]			-> [^12].
		[MoveM64rRd]			-> [^self literalLoadInstructionBytes + 4].
		[MoveMwrR]			-> [^16].
		[MoveXbrRR]			-> [^4].
		[MoveRXbrR]			-> [^4].
		[MoveXwrRR]			-> [^8].
		[MoveRXwrR]			-> [^8].
		[PopR]					-> [^8].
		[PushR]					-> [^8].
		[PushCw]				-> [^16].
		[PushCq]				-> [^16].
		[PrefetchAw] 			-> [^0].
		"Conversion"
		[ConvertRRd]			-> [self error].
		}.
	^0 "to keep C compiler quiet"

]

{ #category : #accessing }
CogPOWERCompiler >> concreteCalleeSavedRegisterMask [
	"According to IHI0042E ARM Architecture Procedure Calling Standard, in section 5.1.1:
		A subroutine must preserve the contents of the registers r4-r8, r10, r11 and SP (and r9 in PCS variants that designate r9 as v6).
	 SP = r13, so..."
	^2r0000110111110000
]

{ #category : #accessing }
CogPOWERCompiler >> concreteCallerSavedRegisterMask [
	"According to IHI0042E ARM Architecture Procedure Calling Standard, in section 5.1.1:
		A subroutine must preserve the contents of the registers r4-r8, r10, r11 and SP (and r9 in PCS variants that designate r9 as v6).
	 SP = r13, so the callee-saved regs are r4-r8 & r10-r12.
	 The caller-saved registers are those that are not callee-saved and not reserved for hardware/abi uses,
	 i..e r0-r3, r9 & r12."
	^2r1001000001111
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeAddCqR [
	^(operands at: 0) fitsInSigned16 
		ifTrue: [ self concretizzeAddCqR ]
		ifFalse: [ self concretizeAddCwR ]
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeAddCwR [
	<operands: #(constant r)>
	<powerpc: 'addis {r}, {r}, {constant bogusComputeHiCarry}'>
	<powerpc: 'addi {r}, {r}, {constant bogusComputeLo}'>
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeAddRR [
	<operands: #(srcR dstR)>
	<powerpc: 'mtxer 20'>
	<powerpc: 'add. {dstR}, {dstR}, {srcR}'>
]

{ #category : #'concretize - floating point' }
CogPOWERCompiler >> concretizeAddRdRd [
	self shouldBeImplemented
]

{ #category : #'concretize - pseudo' }
CogPOWERCompiler >> concretizeAlignmentNops [
	machineCodeSize isNil ifTrue: [ machineCodeSize := 0 ]. "BOGUSBOGUSBOGUS"
	self assert: machineCodeSize \\ 4 = 0.
	0 to: machineCodeSize - 1 by: 4 do:
		[:p| self machineCodeAt: p put: 16r7C000378] "or 0,0,0"
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeAndCqR [
	^(operands at: 0) fitsInUnsigned16 
		ifTrue: [ self concretizzeAndCqR ]
		ifFalse: [ self concretizeAndCwR ]

]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeAndCqRR [
	<operands: #(val src dst)>
	<powerpc: 'andi. {dst}, {src}, {val}'> "BOGUS -- what if it doesn't fit???"
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeAndCwR [
	<operands: #(constant r)>
	<powerpc: 'lis 12, {constant bogusComputeHi}'>
	<powerpc: 'ori 12, 12, {constant bogusComputeLo}'>
	<powerpc: 'and. {r}, {r}, 12'>

]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeAndRR [
	<operands: #(srcR dstR)>
	<powerpc: 'and. {dstR}, {dstR}, {srcR}'>
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeArithmeticShiftRightCqR [
	<operands: #(distance r)>
	<powerpc: 'srawi {r}, {r}, {distance}'>
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeArithmeticShiftRightRR [
	<operands: #(distanceReg dest)>
	<powerpc: 'sraw {dest}, {dest}, {distanceReg}'>
]

{ #category : #'concretize - control' }
CogPOWERCompiler >> concretizeCall [
	"Call is used only within code-space, and is allowed to vary in size.
	On POWER, -- like on ARM -- this method is dispatched to from both Call and CallLong,
	so it must NOT vary in size."
	<operands: #(callTarget)>
	"This is Truly Stupid:
	Emulate ARM-style saving of the return address in R14,
	instead of taking advantage of POWER's Branch Processor.
	This will be fixed very soon."
	<powerpc: 'bl 1'>
	<powerpc: 'mflr 14'>
	<powerpc: 'addi 14, 14, 12'>
	"Actual call"
	<powerpc: 'ba {callTarget asAddress >> 2}'> 
]

{ #category : #'concretize - control' }
CogPOWERCompiler >> concretizeCallFull [
	<operands: #(target)>
	"Save return address, ARM-style.  See concretizeCall"
	<powerpc: 'bl 1'>
	<powerpc: 'mflr 14'>
	<powerpc: 'addi 14, 14, 24'>
	"Synthesize the target in IP"
	<powerpc: 'lis 12, {target bogusComputeHi}'>
	<powerpc: 'ori 12, 12, {target bogusComputeLo}'>
	"Call"
	<powerpc: 'mtctr 12'>
	<powerpc: 'bctr'>
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeCmpCqR [
	^(operands at: 0) fitsInUnsigned16 
		ifTrue: [ self concretizzeCmpCqR ]
		ifFalse: [ self concretizeCmpCwR ]
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeCmpCwR [
	<operands: #(const r)>
	<powerpc: 'lis {ConcreteIPReg}, {const bogusComputeHi}'>
	<powerpc: 'ori {ConcreteIPReg}, {ConcreteIPReg}, {const bogusComputeLo}'>
	<powerpc: 'cmplw 0, {r}, {ConcreteIPReg}'>
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeCmpRR [
	<operands: #(rx ry)>
	<powerpc: 'cmplw 0, {ry}, {rx}'>
]

{ #category : #'concretize - floating point' }
CogPOWERCompiler >> concretizeCmpRdRd [
	self shouldBeImplemented 
]

{ #category : #'generate machine code' }
CogPOWERCompiler >> concretizeConditionalInstruction [
	"Concretize the current instruction, but with a condition."
	| savedCond |
self error. "can't happen and screws the instruction really hard anyway"
	self assert: conditionOrNil notNil.
	savedCond := conditionOrNil.
	conditionOrNil := nil.
	self dispatchConcretize.
	conditionOrNil := savedCond.
	0 to: machineCodeSize-1 by: 4 do:
		[:i| | instr |
		instr := (self machineCodeAt: i) bitClear: 16rF<<28.
		self machineCodeAt: i put: (instr bitOr: (conditionOrNil bitAnd: 16rF)<<28)]
]

{ #category : #'concretize - floating point' }
CogPOWERCompiler >> concretizeConvertRRd [
	self shouldBeImplemented 
]

{ #category : #'concretize - floating point' }
CogPOWERCompiler >> concretizeDivRdRd [
	self shouldBeImplemented 
]

{ #category : #'concretize - floating point' }
CogPOWERCompiler >> concretizeFPConditionalJump: conditionCode [
	self shouldBeImplemented 
]

{ #category : #'concretize - pseudo' }
CogPOWERCompiler >> concretizeFill32 [
	"fill with operand 0 according to the processor's endianness"
	self machineCodeAt: 0 put: (operands at: 0).
	^machineCodeSize := 4
]

{ #category : #'concretize - control' }
CogPOWERCompiler >> concretizeJump [
	^self concretizeJumpFull 
	
	"
	Relative version:
	| bd |
	bd := self computeJumpTargetOffsetPlus: 0.
	^self concretizzeJump: bd//4
	"
]

{ #category : #'concretize - control' }
CogPOWERCompiler >> concretizeJumpFull [
	<operands: #(target)>
	<powerpc: 'lis 12, {target bogusComputeHi}'> "12=IP"
	<powerpc: 'ori 12, 12, {target bogusComputeLo}'>
	<powerpc: 'mtctr 12'>
	<powerpc: 'bctr'>
]

{ #category : #'concretize - control' }
CogPOWERCompiler >> concretizeJumpIfFalse: conditionBit [
	| bd |
	bd := self computeJumpTargetOffsetPlus: 4.
	^self concretizzeJumpIfFalse: conditionBit li: bd//4
]

{ #category : #'concretize - control' }
CogPOWERCompiler >> concretizeJumpIfTrue: conditionBit [
	| bd |
	bd := self computeJumpTargetOffsetPlus: 4. "+4 because this is relative to the address of the tile, and the tile has one instruction before the jump"
	^self concretizzeJumpIfTrue: conditionBit li: bd//4
]

{ #category : #'concretize - control' }
CogPOWERCompiler >> concretizeJumpR [
	<operands: #(reg)>
	<powerpc: 'mtctr {reg}'>
	<powerpc: 'bctr'>	
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeLoadEffectiveAddressMwrR [
	^self concretizzeLoadEffectiveAddressMwrR.
	"BOGUS: what about the below:"
"	on: UnrepresentableOperand 
	do: [ 
		| srcReg offset destReg instrOffset |
		offset := operands at: 0.
		srcReg := operands at: 1.
		destReg := operands at: 2.
		instrOffset := self moveCw: offset intoR: ConcreteIPReg.
		self machineCodeAt: 16 put: (self add: destReg rn: srcReg rm: ConcreteIPReg).
		machineCodeSize := instrOffset + 4.
		^machineCodeSize
		]
"
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeLogicalShiftLeftCqR [
	<operands: #(distance r)>
	"TODO: slwi"
	<powerpc: 'rlwinm {r}, {r}, {distance}, 0, {31-distance}'>
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeLogicalShiftLeftRR [
	<operands: #(distanceReg dest)>
	<powerpc: 'slw. {dest}, {dest}, {distanceReg}'>
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeLogicalShiftRightCqR [
	<operands: #(distance r)>
	"p.123:
	Immediate-form logical (unsigned) shift operations are obtained by
	specifyling appropriate masks and shift values for certain Rotate instructions.
	A set of extended mnemonics is provided to make coding of such shifts
	simpler and easier to understand."
	"cf. App.C, Table 9, p.230"
	
	"In the ArchC model, srwi is not a mnemonic but a pseudo-instr;
	encode using basic mnemonic for now.  ***TODO"
	<powerpc: 'rlwinm {r}, {r}, {32-distance}, {distance}, 31'>
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeLogicalShiftRightRR [
	<operands: #(distanceReg dest)>
	<powerpc: 'srw. {dest}, {dest}, {distanceReg}'>
]

{ #category : #'concretize - data movement' }
CogPOWERCompiler >> concretizeMoveAbR [
	<operands: #(srcAddr destReg)>
	<powerpc: 'twi 0, 11'>

]

{ #category : #'concretize - data movement' }
CogPOWERCompiler >> concretizeMoveAwR [
	<operands: #(srcAddr destReg)>
	<powerpc: 'lis {ConcreteIPReg}, {srcAddr bogusComputeHiCarry}'>
	<powerpc: 'lwz {destReg}, {srcAddr bogusComputeLo} ({ConcreteIPReg})'> "will become srcAddr@l"
]

{ #category : #'concretize - data movement' }
CogPOWERCompiler >> concretizeMoveCqR [
	(operands at: 0) fitsInSigned16 ifTrue: [ ^self concretizzeMoveCqR ].
	"temptation in case it fitsInUnsigned16 -- alas no RZero for ORI :-("
	^self concretizeMoveCwR
]

{ #category : #'concretize - data movement' }
CogPOWERCompiler >> concretizeMoveCwR [
	<operands: #(constant r)>
	<powerpc: 'lis {r}, {constant bogusComputeHi}'>
	<powerpc: 'ori {r}, {r}, {constant bogusComputeLo}'>
]

{ #category : #'concretize - data movement' }
CogPOWERCompiler >> concretizeMoveM16rR [
	<operands: #(offset baseR destR)>
	<powerpc: 'lis 12, {offset bogusComputeHi}'>
	<powerpc: 'ori 12, 12, {offset bogusComputeLo}'>
	<powerpc: 'lhzx {destR}, 12, {baseR}'>
]

{ #category : #'concretize - floating point' }
CogPOWERCompiler >> concretizeMoveM64rRd [
	self shouldBeImplemented 
]

{ #category : #'concretize - data movement' }
CogPOWERCompiler >> concretizeMoveMbrR [ 
	<operands: #(offset srcReg destReg)>
	<powerpc: 'lis 12, {offset bogusComputeHiCarry}'>
	<powerpc: 'addi 12, 12, {offset bogusComputeLo}'>
	"now ConcreteIPReg has offset"
	<powerpc: 'add 12, 12, {srcReg}'>
	<powerpc: 'lbz {destReg}, 0 (12)'>
]

{ #category : #'concretize - data movement' }
CogPOWERCompiler >> concretizeMoveMwrR [ 
	<operands: #(offset srcReg destReg)>
	<powerpc: 'lis 12, {offset bogusComputeHiCarry}'>
	<powerpc: 'addi 12, 12, {offset bogusComputeLo}'>
	"now ConcreteIPReg has offset"
	<powerpc: 'add 12, 12, {srcReg}'>
	<powerpc: 'lwz {destReg}, 0 (12)'>
]

{ #category : #'concretize - data movement' }
CogPOWERCompiler >> concretizeMoveRAb [
	<operands: #(srcReg destAddr)>
	<powerpc: 'twi 0, 16'>
]

{ #category : #'concretize - data movement' }
CogPOWERCompiler >> concretizeMoveRAw [
	<operands: #(srcReg destAddr)>
	<powerpc: 'lis 12, {destAddr bogusComputeHiCarry}'> "12=IP"
	<powerpc: 'addi 12, 12, {destAddr bogusComputeLo}'>
	<powerpc: 'stw {srcReg}, 0 (12)'> "will become destAddr@l"
]

{ #category : #'concretize - data movement' }
CogPOWERCompiler >> concretizeMoveRM16r [
	<operands: #(srcR offset baseR)>
	<powerpc: 'twi 0, 17'>
]

{ #category : #'concretize - data movement' }
CogPOWERCompiler >> concretizeMoveRMbr [
	<operands: #(srcR offset baseR)>
	<powerpc: 'twi 0, 18'>
]

{ #category : #'concretize - data movement' }
CogPOWERCompiler >> concretizeMoveRMwr [
	<operands: #(srcReg offset baseReg)>
	<powerpc: 'lis 12, {offset bogusComputeHiCarry}'>
	"now ConcreteIPReg has offset@hi"
	<powerpc: 'add 12, 12, {baseReg}'>
	<powerpc: 'stw {srcReg}, {offset bogusComputeLo} (12)'>
]

{ #category : #'concretize - data movement' }
CogPOWERCompiler >> concretizeMoveRR [
	<operands: #(srcR dstR)>
	<powerpc: 'or {dstR}, {srcR}, {srcR}'>
]

{ #category : #'concretize - data movement' }
CogPOWERCompiler >> concretizeMoveRXbrR [
	"Write the word in R(src) into memory at address (base+1*index)"
	<operands: #(src index base)>
	<powerpc: 'stbx {src}, {index}, {base}'>
]

{ #category : #'concretize - data movement' }
CogPOWERCompiler >> concretizeMoveRXwrR [
	"Write the word in R(src) into memory at address (base+4*index)"
	<operands: #(src index base)>
	<powerpc: 'rlwinm 12, {index}, 2, 0, 29'> "12=TempR, index is in words"
	<powerpc: 'stwx {src}, 12, {base}'>
]

{ #category : #'concretize - floating point' }
CogPOWERCompiler >> concretizeMoveRdM64r [
	self shouldBeImplemented 
]

{ #category : #'concretize - data movement' }
CogPOWERCompiler >> concretizeMoveXbrRR [
	<operands: #(index base dest)>  "index is in bytes"
	<powerpc: 'lbzx {dest}, {index}, {base}'>
]

{ #category : #'concretize - data movement' }
CogPOWERCompiler >> concretizeMoveXwrRR [
	<operands: #(index base dest)>
	<powerpc: 'rlwinm 12, {index}, 2, 0, 29'> "12=TempR, index is in words"
	<powerpc: 'lwzx {dest}, 12, {base}'>
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeMulRR [
	<operands: #(srcR dstR)>
	<powerpc: 'mullw. {dstR}, {dstR}, {srcR}'> "BOGUS -- must set overflow but gem5 will crash on OE=1"
]

{ #category : #'concretize - floating point' }
CogPOWERCompiler >> concretizeMulRdRd [
	self shouldBeImplemented 
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeNegateR [
	<operands: #(reg)>
	<powerpc: 'neg {reg}, {reg}'>
]

{ #category : #'concretize - pseudo' }
CogPOWERCompiler >> concretizeNop [
	<powerpc: 'or 0, 0, 0'>
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeOrCqR [
	^self concretizeOrCwR
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeOrCwR [
	<operands: #(constant r)>
	<powerpc: 'lis 12, {constant bogusComputeHi}'>
	<powerpc: 'ori 12, 12, {constant bogusComputeLo}'>
	<powerpc: 'or. {r}, {r}, 12'>
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeOrRR [
	<operands: #(srcR dstR)>
	<powerpc: 'or. {dstR}, {dstR}, {srcR}'>
]

{ #category : #'concretize - data movement' }
CogPOWERCompiler >> concretizePopR [
	<operands: #(destR)>
	<powerpc: 'lwz {destR}, 0 (13)'>
	<powerpc: 'addi 13, 13, 4'>
]

{ #category : #'concretize - data movement' }
CogPOWERCompiler >> concretizePrefetchAw [
	^machineCodeSize := 0
]

{ #category : #'concretize - data movement' }
CogPOWERCompiler >> concretizePushCq [
	<operands: #(word)>
	<powerpc: 'lis 12, {word bogusComputeHi}'>  "12=IP"
	<powerpc: 'ori 12, 12, {word bogusComputeLo}'>
	<powerpc: 'addi 13, 13, -4'> "13=SP"
	<powerpc: 'stw 12, 0 (13)'>
]

{ #category : #'concretize - data movement' }
CogPOWERCompiler >> concretizePushCw [
	<operands: #(word)>
	<powerpc: 'lis 12, {word bogusComputeHi}'> "12=IP"
	<powerpc: 'ori 12, 12, {word bogusComputeLo}'>
	<powerpc: 'addi 13, 13, -4'> "13=SP"
	<powerpc: 'stw 12, 0 (13)'>
]

{ #category : #'concretize - data movement' }
CogPOWERCompiler >> concretizePushOrPopMultipleRegisters: doPush [
	<operands: #(xxx)>
	<powerpc: 'twi 0, 28'>
]

{ #category : #'concretize - data movement' }
CogPOWERCompiler >> concretizePushR [
	<operands: #(srcR)>
	<powerpc: 'addi 13, 13, -4'>
	<powerpc: 'stw {srcR}, 0 (13)'>
]

{ #category : #'concretize - control' }
CogPOWERCompiler >> concretizeRetN [
	<operands: #(offset)>
	<powerpc: 'addi 13, 13, {offset}'> "13=SP"
	<powerpc: 'mtctr 14'> "14=LR"
	<powerpc: 'bctr'>

]

{ #category : #'concretize - floating point' }
CogPOWERCompiler >> concretizeSqrtRd [
	self shouldBeImplemented
]

{ #category : #'concretize - control' }
CogPOWERCompiler >> concretizeStop [
	<powerpc: 'trap'>

]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeSubCqR [
	^(operands at: 0) fitsInSigned16 
		ifTrue: [ self concretizzeSubCqR ]
		ifFalse: [ self concretizeSubCwR ]
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeSubCwR [
	| c u32const r |
	c := operands at: 0.
	r := operands at: 1.
	"TODO.  This is idiotic.  Someone please fix this."
	u32const := (c negated toBitVector: 32) value.
	^self concretizzeAddForSubCw: u32const R: r

]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeSubRR [
	<operands: #(right left_dest)>
	<powerpc: 'subf. {left_dest}, {right}, {left_dest}'>
]

{ #category : #'concretize - floating point' }
CogPOWERCompiler >> concretizeSubRdRd [
	self shouldBeImplemented 
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeTstCqR [
	^self concretizeTstCwR
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeTstCwR [
	<operands: #(mask r)>
	<powerpc: 'lis 12, {mask bogusComputeHi}'> "12=IP"
	<powerpc: 'ori 12, 12, {mask bogusComputeLo}'>
	<powerpc: 'and. 12, {r}, 12'>
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeXorCqR [
	^self concretizeXorCwR
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeXorCwR [
	<operands: #(constant r)>
	<powerpc: 'lis 12, {constant bogusComputeHi}'>
	<powerpc: 'ori 12, 12, {constant bogusComputeLo}'>
	<powerpc: 'xor. {r}, {r}, 12'>
]

{ #category : #'concretize - arithmetic' }
CogPOWERCompiler >> concretizeXorRR [
	<operands: #(srcR dstR)>
	<powerpc: 'xor. {dstR}, {dstR}, {srcR}'>
]

{ #category : #concretizze }
CogPOWERCompiler >> concretizzeAddCqR [
	<operands: #(simm16 r)>
	<powerpc: 'addic. {r}, {r}, {simm16}'>

]

{ #category : #concretizze }
CogPOWERCompiler >> concretizzeAddForSubCw: u32const R: r [
	<powerpc: 'lis 12, {u32const bogusComputeHi}'>
	<powerpc: 'ori 12, 12, {u32const bogusComputeLo}'>
	<powerpc: 'add. {r}, {r}, 12'>
]

{ #category : #concretizze }
CogPOWERCompiler >> concretizzeAndCqR [
	<operands: #(uimm16 r)>
	<powerpc: 'andi. {r}, {r}, {uimm16}'>

]

{ #category : #'concretize - control' }
CogPOWERCompiler >> concretizzeCall: li [
	"This is Truly Stupid:
	Emulate ARM-style saving of the return address in R14,
	instead of taking advantage of POWER's Branch Processor.
	This will be fixed very soon."
	<powerpc: 'bl 1'>
	<powerpc: 'mflr 14'>
	<powerpc: 'addi 14, 14, 12'>

	<powerpc: 'b {li}'> 
]

{ #category : #concretizze }
CogPOWERCompiler >> concretizzeCmpCqR [
	<operands: #(ui ra)>
	<powerpc: 'cmplwi 0, {ra}, {ui}'>
]

{ #category : #'concretize - control' }
CogPOWERCompiler >> concretizzeJump: li [
	<powerpc: 'b {li}'>
]

{ #category : #concretizze }
CogPOWERCompiler >> concretizzeJumpFull [
	<operands: #(imm)>
	<powerpc: 'ba {imm>>2 bitAnd: 16r00FFFFFF}'>
]

{ #category : #'concretize - control' }
CogPOWERCompiler >> concretizzeJumpIfFalse: conditionBit li: li [
	"Branch-conditional B-form's +-32K is too small
	 for jumping over the whole code-zone.
	 Invert the condition and skip over the actual jump."

	<powerpc: 'bc 12, {conditionBit}, 2'> "12 = Jump if true"
	<powerpc: 'b {li}'>
]

{ #category : #'concretize - control' }
CogPOWERCompiler >> concretizzeJumpIfTrue: conditionBit li: li [
	"Branch-conditional B-form's +-32K is too small
	 for jumping over the whole code-zone.
	 Invert the condition and skip over the actual jump."

	<powerpc: 'bc 4, {conditionBit}, 2'> "12 = Jump if false"
	<powerpc: 'b {li}'>
]

{ #category : #concretizze }
CogPOWERCompiler >> concretizzeLoadEffectiveAddressMwrR [
	"destReg = srcReg (which contains an address) + offset"
	<operands: #(offset srcR dstR)>
	<powerpc: 'addi {dstR}, {srcR}, {offset}'>
]

{ #category : #'concretize - data movement' }
CogPOWERCompiler >> concretizzeMoveCqR [
	<operands: #(constant r)>
	<powerpc: 'li {r}, {constant}'>
]

{ #category : #concretizze }
CogPOWERCompiler >> concretizzeOrCqR [
	<operands: #(val rn)>
	<armv5: 'orrs {rn}, {rn}, #{val}'>
]

{ #category : #concretizze }
CogPOWERCompiler >> concretizzeRetN [
	<operands: #(offset)>
	<powerpc: 'addi 13, 13, {offset}'> "13=SP"
	<powerpc: 'mtctr 14'> "14=LR"
	<powerpc: 'bctr'>

]

{ #category : #concretizze }
CogPOWERCompiler >> concretizzeSubCqR [
	<operands: #(simm16 r)>
	<powerpc: 'addic. {r}, {r}, {simm16 negated}'>

]

{ #category : #concretizze }
CogPOWERCompiler >> concretizzeTstCqR [
	<operands: #(const r)>
	<powerpc: 'twi 0, 32'>
]

{ #category : #accessing }
CogPOWERCompiler >> conditionOrNil [
"has to be named oddly like this to satisfay i-var code gen translating rules"
	^conditionOrNil
]

{ #category : #accessing }
CogPOWERCompiler >> conditionOrNil: condCode [
"has to be named oddly like this to satisfay i-var code gen translating rules"
	^conditionOrNil := condCode
]

{ #category : #'generate machine code' }
CogPOWERCompiler >> dispatchConcretize [

	| implementedOpcodes |
	implementedOpcodes := OrderedCollection new.
	implementedOpcodes
		add: RetN;
		add: AddCqR;
		add: MoveCqR;
		add: MoveRAw;
		add: MoveAwR;
		add: Label;
		add: CallFull;
		add: MoveCqR;
		add: MoveRR;
		add: PushR;
		add: PopR.
	(implementedOpcodes includes: opcode) ifFalse: [ (CogRTLOpcodes nameForOpcode: opcode) "halt" ].
	
	
	conditionOrNil ifNotNil:
		[self concretizeConditionalInstruction.
		 ^self].
		 
	opcode caseOf: {
		"Noops & Pseudo Ops"
		[Label]					-> [^self concretizeLabel].
		[Literal]					-> [^self concretizeLiteral].
		[AlignmentNops]		-> [^self concretizeAlignmentNops].
		[Fill32]					-> [^self concretizeFill32].
		[Nop]					-> [^self concretizeNop].
		"Control"
		[Call]						-> [^self concretizeCall]. "call code within code space"
		[CallFull]					-> [^self concretizeCallFull]. "call code anywhere in address space"
		[JumpR]						-> [^self concretizeJumpR].
		[JumpFull]					-> [^self concretizeJumpFull]."jump within address space"
		[JumpLong]					-> [^self concretizeJump]."jumps witihn code space"
		[JumpLongZero]			-> [^self concretizeJumpIfTrue: 0].
		[JumpLongNonZero]		-> [^self concretizeJumpIfFalse: 0].
		[Jump]						-> [^self concretizeJump].
		[JumpZero]					-> [^self concretizeJumpIfTrue: 2].
		[JumpNonZero]				-> [^self concretizeJumpIfFalse: 2].
		[JumpNegative]				-> [^self concretizeJumpIfTrue: 0].
		[JumpNonNegative]			-> [^self concretizeJumpIfFalse: 0].
		[JumpOverflow]				-> [^self concretizeJumpIfTrue: 3].
		[JumpNoOverflow]			-> [^self concretizeJumpIfFalse: 3].
		[JumpCarry]				-> [^self concretizeJumpIfTrue: 3 "BOGUS"].
		[JumpNoCarry]				-> [^self concretizeJumpIfFalse: 3 "BOGUS"].
		[JumpLess]					-> [^self concretizeJumpIfTrue: 0].
		[JumpGreaterOrEqual]		-> [^self concretizeJumpIfFalse: 0].
		[JumpGreater]				-> [^self concretizeJumpIfTrue: 1].
		[JumpLessOrEqual]			-> [^self concretizeJumpIfFalse: 1].
		[JumpBelow]				-> [^self concretizeJumpIfTrue: 0]. "unsigned lower"
		[JumpAboveOrEqual]		-> [^self concretizeJumpIfFalse: 0]. "unsigned greater or equal"
		[JumpAbove]				-> [^self concretizeJumpIfTrue: 1].
		[JumpBelowOrEqual]		-> [^self concretizeJumpIfFalse: 1].
		[JumpFPEqual]				-> [^self shouldBeImplemented].
		[JumpFPNotEqual]			-> [^self shouldBeImplemented].
		[JumpFPLess]				-> [^self shouldBeImplemented].
		[JumpFPGreaterOrEqual]	-> [^self shouldBeImplemented].
		[JumpFPGreater]			-> [^self shouldBeImplemented].
		[JumpFPLessOrEqual]		-> [^self shouldBeImplemented].
		[JumpFPOrdered]			-> [^self shouldBeImplemented].
		[JumpFPUnordered]			-> [^self shouldBeImplemented].
		[RetN]						-> [^self concretizeRetN].
		[Stop]						-> [^self concretizeStop].
		"Arithmetic"
		[AddCqR]					-> [^self concretizeAddCqR].
		[AndCqR]					-> [^self concretizeAndCqR].
		[AndCqRR]					-> [^self concretizeAndCqRR].
		[CmpCqR]					-> [^self concretizeCmpCqR].
		[OrCqR]						-> [^self concretizeOrCqR].
		[SubCqR]					-> [^self concretizeSubCqR].
		[TstCqR]					-> [^self concretizeTstCqR].
		[XorCqR]					-> [^self concretizeXorCqR].
		[AddCwR]					-> [^self concretizeAddCwR].
		[AndCwR]					-> [^self concretizeAndCwR].
		[CmpCwR]					-> [^self concretizeCmpCwR].
		[OrCwR]					-> [^self concretizeOrCwR].
		[SubCwR]					-> [^self concretizeSubCwR].
		[XorCwR]					-> [^self concretizeXorCwR].
		[AddRR]						-> [^self concretizeAddRR].
		[AndRR]						-> [^self concretizeAndRR].
		[CmpRR]					-> [^self concretizeCmpRR].
		[OrRR]						-> [^self concretizeOrRR].
		[SubRR]						-> [^self concretizeSubRR].
		[XorRR]						-> [^self concretizeXorRR].
		[AddRdRd]					-> [^self concretizeAddRdRd].
		[CmpRdRd]					-> [^self concretizeCmpRdRd].
		[DivRdRd]					-> [^self concretizeDivRdRd].
		[MulRdRd]					-> [^self concretizeMulRdRd].
		[SubRdRd]					-> [^self concretizeSubRdRd].
		[SqrtRd]					-> [^self concretizeSqrtRd].
		[NegateR]						-> [^self concretizeNegateR].
		[LoadEffectiveAddressMwrR]	-> [^self concretizeLoadEffectiveAddressMwrR].
		[ArithmeticShiftRightCqR]		-> [^self concretizeArithmeticShiftRightCqR].
		[LogicalShiftRightCqR]			-> [^self concretizeLogicalShiftRightCqR].
		[LogicalShiftLeftCqR]			-> [^self concretizeLogicalShiftLeftCqR].
		[ArithmeticShiftRightRR]			-> [^self concretizeArithmeticShiftRightRR].
		[LogicalShiftLeftRR]				-> [^self concretizeLogicalShiftLeftRR].
		[LogicalShiftRightRR]			-> [^self concretizeLogicalShiftRightRR].
		[MulRR]			-> [^self concretizeMulRR].
		"ARM Specific Data Movement"
		[PopLDM]			-> [^self concretizePushOrPopMultipleRegisters: false].
		"Data Movement"
		[MoveCqR]			-> [^self concretizeMoveCqR].
		[MoveCwR]			-> [^self concretizeMoveCwR].
		[MoveRR]			-> [^self concretizeMoveRR].
		[MoveAwR]			-> [^self concretizeMoveAwR].
		[MoveRAw]			-> [^self concretizeMoveRAw].
		[MoveAbR] 			 -> [^self concretizeMoveAbR].
 		[MoveRAb]			-> [^self concretizeMoveRAb].
		[MoveMbrR]			-> [^self concretizeMoveMbrR].
		[MoveRMbr]			-> [^self concretizeMoveRMbr].
		[MoveRM16r]		-> [^self concretizeMoveRM16r].
		[MoveM16rR]		-> [^self concretizeMoveM16rR].
		[MoveM64rRd]		-> [^self concretizeMoveM64rRd].
		[MoveMwrR]		-> [^self concretizeMoveMwrR].
		[MoveXbrRR]		-> [^self concretizeMoveXbrRR].
		[MoveRXbrR]		-> [^self concretizeMoveRXbrR].
		[MoveXwrRR]		-> [^self concretizeMoveXwrRR].
		[MoveRXwrR]		-> [^self concretizeMoveRXwrR].
		[MoveRMwr]		-> [^self concretizeMoveRMwr].
		[MoveRdM64r]		-> [^self concretizeMoveRdM64r].
		[PopR]				-> [^self concretizePopR].
		[PushR]				-> [^self concretizePushR].
		[PushCq]			-> [^self concretizePushCq].
		[PushCw]			-> [^self concretizePushCw].
		[PrefetchAw]		-> [^self concretizePrefetchAw].
		"Conversion"
		[ConvertRRd]		-> [^self concretizeConvertRRd]}
]

{ #category : #'inline cacheing' }
CogPOWERCompiler >> flushICacheFrom: startAddress "<Integer>" to: endAddress [ "<Integer>"
	<cmacro: '(me,startAddress,endAddress) __clear_cache((char*) startAddress, (char*) (endAddress ))'>
	"On ARM we almost certainly need to flush and wash hands. On linux we use __clear_cache (see http://community.arm.com/groups/processors/blog/2010/02/17/caches-and-self-modifying-code for a decent example) and remember that the end address is *exclusive* so we can just use the end address passed in since it is always the byte after the actual last one needing flushing"
	self halt: #ceFlushICache
]

{ #category : #abi }
CogPOWERCompiler >> fullCallsAreRelative [
	"Answer if CallFull and/or JumpFull are relative and hence need relocating on method
	 compation. If so, they are annotated with IsRelativeCall in methods and relocated in
	 relocateIfCallOrMethodReference:mcpc:delta:"
	^false
]

{ #category : #'abstract instructions' }
CogPOWERCompiler >> genDivR: abstractRegDivisor R: abstractRegDividend Quo: abstractRegQuotient Rem: abstractRegRemainder [
"Currently no instruction level support for divide on ARM. See also #canDivQuoRem"
	| rDividend rDivisor rQuotient rRemainder divRemFunctionAddr |
	self assert: abstractRegDividend ~= abstractRegDivisor.
	self assert: abstractRegQuotient ~= abstractRegRemainder.
	rDividend := abstractRegDividend.
	rDivisor := abstractRegDivisor.
	rDividend = CArg0Reg ifFalse:
		["we need to move the value in rDividend to CArg0Reg. Best to double check if rDivisor is already using it first"
		rDivisor = CArg0Reg ifTrue: "oh dear; we also need to move rDivisor's value out of the way first.. I'll move it to CArg1Reg and if some nitwit has managed to put rDividend there they deserve the crash"
			[rDividend = CArg1Reg ifTrue:
				[self error: 'register choices in genDivR:R:Quo:Rem: made life impossible'].
			cogit MoveR: rDivisor R: CArg1Reg.
			"and update rDivisor or we get buggerd by the next clause"
			rDivisor := CArg1Reg].
		cogit MoveR: rDividend R: CArg0Reg].
	rDivisor = CArg1Reg ifFalse:
		[cogit MoveR: rDivisor R: CArg1Reg].
	divRemFunctionAddr := self aeabiDivModFunctionAddr.
	self saveAndRestoreLinkRegAround:
		[cogit CallFullRT: (cogit simulatedTrampolineFor: divRemFunctionAddr)
			registersToBeSavedMask: (cogit registerMaskFor: CArg2Reg and: CArg3Reg)].
	"Now we need to move the r0/1 results back to rQuotient & rRemainder"
	rQuotient := abstractRegQuotient.
	rRemainder := abstractRegRemainder.
	rQuotient = CArg0Reg ifFalse: "oh good grief, not again"
		[cogit MoveR: CArg0Reg R: rQuotient.
		 rQuotient = CArg1Reg ifTrue:
			[self error: 'register choices in genDivR:R:Quo:Rem: made life impossible'] ].
	rRemainder = CArg1Reg  ifFalse:
		[cogit MoveR: CArg1Reg R: rRemainder]
				

]

{ #category : #'smalltalk calling convention' }
CogPOWERCompiler >> genLoadCStackPointer [
	"Load the stack pointer register with that of the C stack, effecting
	 a switch to the C stack.  Used when machine code calls into the
	 CoInterpreter run-time (e.g. to invoke interpreter primitives)."
	cogit MoveAw: cogit cStackPointerAddress R: SPReg.
	^0
]

{ #category : #'smalltalk calling convention' }
CogPOWERCompiler >> genLoadCStackPointers [
	"Load the frame and stack pointer registers with those of the C stack,
	 effecting a switch to the C stack.  Used when machine code calls into
	 the CoInterpreter run-time (e.g. to invoke interpreter primitives)."
	cogit MoveAw: cogit cStackPointerAddress R: SPReg.
	cogit MoveAw: cogit cFramePointerAddress R: FPReg.
	^0
]

{ #category : #abi }
CogPOWERCompiler >> genMarshallNArgs: numArgs arg: regOrConst0 arg: regOrConst1 arg: regOrConst2 arg: regOrConst3 [
	"Generate the code to pass up to four arguments in a C run-time call.  Hack: each argument is
	 either a negative number, which encodes a constant, or a non-negative number, that of a register.

	 Run-time calls have no more than four arguments, so chosen so that on ARM, where in its C ABI the
	 first four integer arguments are passed in registers, all arguments can be passed in registers.  We
	 defer to the back end to generate this code not so much that the back end knows whether it uses
	 the stack or registers to pass arguments (it does, but...). In fact we defer for an extremely evil reason.
	 Doing so allows the x64 (where up to 6 args are passed) to assign the register arguments in an order
	 that allows some of the argument registers to be used for specific abstract  registers, specifically
	 ReceiverResultReg and ClassReg.  This is evil, evil, evil, but also it's really nice to keep using the old
	 register assignments the original author has grown accustomed to."
	<inline: true>
	numArgs = 0 ifTrue: [^self].
	(cogit isTrampolineArgConstant: regOrConst0)
		ifTrue: [cogit MoveCq: (cogit trampolineArgValue: regOrConst0) R: CArg0Reg]
		ifFalse: [cogit MoveR: regOrConst0 R: CArg0Reg].
	numArgs = 1 ifTrue: [^self].
	(cogit isTrampolineArgConstant: regOrConst1)
		ifTrue: [cogit MoveCq: (cogit trampolineArgValue: regOrConst1) R: CArg1Reg]
		ifFalse: [cogit MoveR: regOrConst1 R: CArg1Reg].
	numArgs = 2 ifTrue: [^self].
	(cogit isTrampolineArgConstant: regOrConst2)
		ifTrue: [cogit MoveCq: (cogit trampolineArgValue: regOrConst2) R: CArg2Reg]
		ifFalse: [cogit MoveR: regOrConst2 R: CArg2Reg].
	numArgs = 3 ifTrue: [^self].
	(cogit isTrampolineArgConstant: regOrConst3)
		ifTrue: [cogit MoveCq: (cogit trampolineArgValue: regOrConst3) R: CArg3Reg]
		ifFalse: [cogit MoveR: regOrConst3 R: CArg3Reg]
]

{ #category : #'abstract instructions' }
CogPOWERCompiler >> genMulR: regSource R: regDest [
	^cogit gen: MulRR operand: regSource operand: regDest
]

{ #category : #'generate machine code' }
CogPOWERCompiler >> genPopRegisterMask: registersToBeSavedMask [
	<inline: true>
	^registersToBeSavedMask = 0
		ifTrue: [cogit Label]
		ifFalse: [cogit gen: PopLDM operand: registersToBeSavedMask]
]

{ #category : #'smalltalk calling convention' }
CogPOWERCompiler >> genPushRegisterArgsForAbortMissNumArgs: numArgs [
	"Ensure that the register args are pushed before the outer and
	 inner retpcs at an entry miss for arity <= self numRegArgs.  The
	 outer retpc is that of a call at a send site.  The inner is the call
	 from a method or PIC abort/miss to the trampoline."

	"Putting the receiver and args above the return address means the
	 CoInterpreter has a single machine-code frame format which saves
	 us a lot of work."

	"Iff there are register args convert
		sp		->	outerRetpc			(send site retpc)
		linkReg = innerRetpc			(PIC abort/miss retpc)
	 to
		base	->	receiver
					(arg0)
					(arg1)
		sp		->	outerRetpc			(send site retpc)
		sp		->	linkReg/innerRetpc	(PIC abort/miss retpc)"
	numArgs <= cogit numRegArgs ifTrue:
		[self assert: cogit numRegArgs <= 2.
		 cogit MoveMw: 0 r: SPReg R: TempReg. "Save return address"
		 cogit MoveR: ReceiverResultReg Mw: 0 r: SPReg.
		 numArgs > 0 ifTrue:
			[cogit PushR: Arg0Reg.
			 numArgs > 1 ifTrue:
				[cogit PushR: Arg1Reg]].
		cogit PushR: TempReg]. "push back return address"
	cogit PushR: LinkReg
]

{ #category : #'smalltalk calling convention' }
CogPOWERCompiler >> genPushRegisterArgsForNumArgs: numArgs scratchReg: ignored [
	"Ensure that the register args are pushed before the retpc for arity <= self numRegArgs."
	"This is easy on a RISC like ARM because the return address is in the link register.  Putting
	 the receiver and args above the return address means the CoInterpreter has a single
	 machine-code frame format which saves us a lot of work
	NOTA BENE: we do NOT push the return address here, which means it must be dealt with later."
	numArgs <= cogit numRegArgs ifTrue:
		[self assert: cogit numRegArgs <= 2.
		 cogit PushR: ReceiverResultReg.
		numArgs > 0 ifTrue:
			[cogit PushR: Arg0Reg.
			 numArgs > 1 ifTrue:
				[cogit PushR: Arg1Reg]]]
]

{ #category : #abi }
CogPOWERCompiler >> genRemoveNArgsFromStack: n [
	"This is a no-op on ARM since the ABI passes up to 4 args in registers and trampolines currently observe that limit."
	<inline: true>
	self assert: n <= 4.
	^0
]

{ #category : #abi }
CogPOWERCompiler >> genRestoreRegs: regMask [
	"Restore the registers in regMask as saved by genSaveRegs:."
	<inline: true>
	^self genPopRegisterMask: regMask
]

{ #category : #abi }
CogPOWERCompiler >> genSaveRegForCCall [
	"Save the general purpose registers for a call into the C run-time from a trampoline."
	"Save none, because the ARM ABI only defines callee saved registers, no caller-saved regs."
	"cogit gen: STMFD operand: 16r7F"
]

{ #category : #abi }
CogPOWERCompiler >> genSaveRegs: regMask [
	"Save the registers in regMask for a call into the C run-time from a trampoline"

	regMask = 0 ifTrue: [ ^0 ].

	self halt.
	30 to: 1 by: -1 do:
		[:reg|
		 (regMask anyMask: (cogit registerMaskFor: reg)) ifTrue:
			[cogit PushR: reg]].
	^0
]

{ #category : #'smalltalk calling convention' }
CogPOWERCompiler >> genSaveStackPointers [
	"Save the frame and stack pointer registers to the framePointer
	 and stackPointer variables.  Used to save the machine code frame
	 for use by the run-time when calling into the CoInterpreter run-time."
	cogit MoveR: FPReg Aw: cogit framePointerAddress.
	cogit MoveR: SPReg Aw: cogit stackPointerAddress.
	^0
]

{ #category : #'abstract instructions' }
CogPOWERCompiler >> genSubstituteReturnAddress: retpc [
	<inline: true>
	<returnTypeC: #'AbstractInstruction *'>
	^cogit MoveCw: retpc R: LR
]

{ #category : #disassembly }
CogPOWERCompiler >> generalPurposeRegisterMap [
	<doNotGenerate>
	"Answer a Dictionary from register getter to register index."
	^Dictionary newFromPairs:
		{	#r0. R0.
			#r1. R1.
			#r2. R2.
			#r3. R3.
			#r4. R4.
			#r5. R5.
			#r6. R6.
			#r7. R7.
			#r8. R8.
			#r9. R9.
			#r10. R10.
			#r11. R11.
			#r12. R12	}
]

{ #category : #accessing }
CogPOWERCompiler >> getDefaultCogCodeSize [
	"Return the default number of bytes to allocate for native code at startup.
	 The actual value can be set via vmParameterAt: and/or a preference in the ini file."
	<inline: true>
	^1024 * 1536
]

{ #category : #accessing }
CogPOWERCompiler >> getOperand: i [
	^operands at: i-1
]

{ #category : #testing }
CogPOWERCompiler >> hasConditionRegister [
	"Answer if the receiver supports, e.g., JumpOverflow after a regular AddRR"
	^true
]

{ #category : #testing }
CogPOWERCompiler >> hasDoublePrecisionFloatingPointSupport [
	"might be true, but is for the forseeable future disabled"
	^true
]

{ #category : #testing }
CogPOWERCompiler >> hasLinkRegister [
	^true "lr"
]

{ #category : #testing }
CogPOWERCompiler >> hasPCDependentInstruction [
	"e.g. B, BL: Branch, Branch and Link"
	^true
]

{ #category : #testing }
CogPOWERCompiler >> hasPCRegister [
	^false
]

{ #category : #testing }
CogPOWERCompiler >> hasThreeAddressArithmetic [
	"Answer if the receiver supports three-address arithmetic instructions (currently only AndCqRR)"
	^true
]

{ #category : #testing }
CogPOWERCompiler >> hasVarBaseRegister [
	"Answer if the processor has a dedicated callee-saved register to point to
	 the base of commonly-accessed variables. On ARM we use R10 for this."
	^true "r10/sl"
]

{ #category : #'generate machine code' }
CogPOWERCompiler >> initialize [
	"This method intializes the Smalltalk instance.  The C instance is merely a struct and doesn't need initialization."
	<doNotGenerate>
	operands := CArrayAccessor on: (Array new: NumOperands).
	machineCode := CArrayAccessor on: (Array new: self machineCodeWords)
]

{ #category : #'inline cacheing' }
CogPOWERCompiler >> inlineCacheTagAt: callSiteReturnAddress [
	"Answer the inline cache tag for the return address of a send."
	"cogit disassembleAround: callSiteReturnAddress-(6*4)."
	^self int32InLisOriAt: callSiteReturnAddress-(6*4) "cf rewriteInlineCacheAt:tag:target:"
]

{ #category : #'inline cacheing' }
CogPOWERCompiler >> insert32BitOperand: operand intoLisOriAt: pc [
	| lis ori |
	lis := self instructionAt: pc.
	ori := self instructionAt: pc+4.
	(lis name = 'addis' and: [ ori name = 'ori' ]) ifFalse: [ NotLisOri signal ].
	
	"patch the operands"
	lis := lis substitute:  (Dictionary with: 'd'->(operand>>16)).
	ori := ori substitute:  (Dictionary with: 'ui'->(operand bitAnd: 16rFFFF)).
	
	objectMemory
		longAt: pc   put: (lis emit32);
		longAt: pc+4 put: (ori emit32).
	
	self assert: (self int32InLisOriAt: pc) = operand
]

{ #category : #disassembly }
CogPOWERCompiler >> instructionSizeAt: pc [
	"Answer the instruction size at pc.Simple on ARM ;-)"
	^4
]

{ #category : #'inline cacheing' }
CogPOWERCompiler >> int32InLisOriAt: a [
	"A 32-bit constant is loaded by lis/ori located at address a.
	Answer that constant.
	If we don't find a lis/ori pair at a, raise a NotLisOri."
	| ori lis |
	ori  := self instructionAt: a+4.
	lis := self instructionAt: a.
	(lis name = 'addis' and: [ ori name = 'ori' ]) ifFalse: [ NotLisOri signal ].
	^(lis field: 'd') value << 16 bitOr: (ori field: 'ui') value
]

{ #category : #testing }
CogPOWERCompiler >> isAddressRelativeToVarBase: varAddress [
	<inline: true>
	<var: #varAddress type: #usqInt>
	"Support for addressing variables off the dedicated VarBaseReg"
	^varAddress notNil
	  and: [varAddress >= cogit varBaseAddress
	  and: [varAddress - cogit varBaseAddress < (1 << 12)]]
]

{ #category : #testing }
CogPOWERCompiler >> isBigEndian [
	^false
]

{ #category : #testing }
CogPOWERCompiler >> isInImmediateJumpRange: operand [
	"ARM calls and jumps span +/- 32 mb, more than enough for intra-zone calls and jumps.
	Must implement about the relative addressing on POWER."
	self shouldBeImplemented 
	"^operand signedIntFromLong between: -16r2000000 and: 16r1FFFFFC"
]

{ #category : #testing }
CogPOWERCompiler >> isPCDependent [
	"Answer if the receiver is a pc-dependent instruction."
	^self isJump or: [opcode = AlignmentNops]
]

{ #category : #sizing }
CogPOWERCompiler >> jumpLongByteSize [
"	Branch/Call ranges.  Jump[Cond] can be generated as short as possible.  Call/Jump[Cond]Long must be generated
	in the same number of bytes irrespective of displacement since their targets may be updated, but they need only
	span 16Mb, the maximum size of the code zone.  This allows e.g. ARM to use single-word call and jump instructions
	for most calls and jumps.  CallFull/JumpFull must also be generated in the same number of bytes irrespective of
	displacement for the same reason, but they must be able to span the full (32-bit or 64-bit) address space because
	they are used to call code in the C runtime, which may be distant from the code zone"
	^4*4
]

{ #category : #sizing }
CogPOWERCompiler >> jumpLongConditionalByteSize [
	^2*4
]

{ #category : #'inline cacheing' }
CogPOWERCompiler >> jumpLongConditionalTargetBeforeFollowingAddress: mcpc [
	"Extract the target from a long conditional jump.  On many ISAs this si the same as
	 extracting the target from a long unconditional jump, so we provide the default here.
	 Processors such as MIPS override as appropriate."
	"bc <around>; b relative"
	| b |
	self assert: (self instructionAt: mcpc-8) name = 'bc'.
	self assert: ((self instructionAt: mcpc-8) fieldValue: 'bd') = 2.
	
	b := self instructionAt: mcpc-4.
	self assert: b name = 'b'.
	^(b fieldValue: 'li')*4 + (mcpc-4)
]

{ #category : #'inline cacheing' }
CogPOWERCompiler >> jumpLongTargetBeforeFollowingAddress: mcpc [ 
	"Just before mcpc, there is a LongJump.
	Answer its target address."
	self assert: (self instructionAt: mcpc-8) name = 'mtspr'.
	self assert: (self instructionAt: mcpc-4) name = 'bcctr'.
	^self int32InLisOriAt: mcpc-16
]

{ #category : #disassembly }
CogPOWERCompiler >> jumpTargetPCAt: pc [
	<returnTypeC: #usqInt>
	| operand word |
	word := objectMemory long32At: pc.
	operand := word bitAnd: 16rFFFFFF.
	(operand anyMask: 16r800000) ifTrue:
		[operand := operand - 16r1000000].
	^operand * 4 + pc + 8 bitAnd: cogit addressSpaceMask
]

{ #category : #abi }
CogPOWERCompiler >> leafCallStackPointerDelta [
	"Answer the delta from the stack pointer after a call to the stack pointer
	 immediately prior to the call.  This is used to compute the stack pointer
	 immediately prior to  call from within a leaf routine, which in turn is used
	 to capture the c stack pointer to use in trampolines back into the C run-time."
	"This might actually be false, since directly after a call, lr, fp and variable registers need be pushed onto the stack. It depends on the implementation of call."
	^0
]

{ #category : #'inline cacheing' }
CogPOWERCompiler >> literalBeforeFollowingAddress: a [
	"Answer the long constant loaded just before this address"
	[ ^self int32InLisOriAt: a-8 ]	
		on: NotLisOri do: [
			"cmp"
			(self instructionAt: a-4) name = 'cmpl' ifTrue: [
		^self literalBeforeFollowingAddress: a-4].
		self shouldBeImplemented  "not even a cmp??" ]


]

{ #category : #accessing }
CogPOWERCompiler >> literalLoadInstructionBytes [
	"Answer the size of a literal load instruction.
	On POWER this is the usual LIS/ORI pair."
	^8
]

{ #category : #accessing }
CogPOWERCompiler >> loadLiteralByteSize [
	"Answer the byte size of a MoveCwR opcode's corresponding machine code.
	POWER is always inline-literal, so this is the same as literalLoadInstructionBytes"
	^8
]

{ #category : #accessing }
CogPOWERCompiler >> loadPICLiteralByteSize [
	"Answer the byte size of a MoveCwR opcode's corresponding machine code
	 when the argument is a PIC.  This is for the self-reference at the end of a
	 closed PIC.  On POWER these are all full loads."
	^8
]

{ #category : #accessing }
CogPOWERCompiler >> machineCodeAt: anOffset [
	"read aWord from machineCode, with little endian"
	<inline: true>
	^machineCode at: anOffset // 4
]

{ #category : #accessing }
CogPOWERCompiler >> machineCodeAt: anOffset put: aWord [
	"add aWord to machineCode, with little endian"
	<inline: true>
	machineCode at: anOffset // 4 put: aWord
]

{ #category : #sizing }
CogPOWERCompiler >> machineCodeBytes [
	"Answer the maximum number of bytes of machine code generated for any abstract instruction."
	^8*4
]

{ #category : #sizing }
CogPOWERCompiler >> machineCodeWords [
	"Answer the maximum number of words of machine code generated for any abstract instruction."
	^8
]

{ #category : #printing }
CogPOWERCompiler >> nameForRegister: reg [ "<Integer>"
	<doNotGenerate>
	| default |
	default := super nameForRegister: reg.
	^default last = $?
		ifTrue:
			[#(LR SP PC CArg0Reg CArg0Reg CArg1Reg CArg2Reg CArg3Reg)
				detect: [:sym| (thisContext method methodClass classPool at: sym) = reg] 
				ifNone: [default]]
		ifFalse:
			[default]
]

{ #category : #'inline cacheing' }
CogPOWERCompiler >> numICacheFlushOpcodes [
	"ARM needs to do icache flushing when code is written"
	"for now return 0 to skip it and probably blow up"
	^0
	
]

{ #category : #accessing }
CogPOWERCompiler >> numIntRegArgs [
	^4
]

{ #category : #'generate machine code' }
CogPOWERCompiler >> padIfPossibleWithStopsFrom: startAddr to: endAddr [
	| nullBytes |
	nullBytes := (endAddr - startAddr + 1) \\ 4.
	self stopsFrom: startAddr to: endAddr - nullBytes.
	endAddr - nullBytes + 1 to: endAddr 
		do: [ :p | objectMemory byteAt: p put: 16rFF]
]

{ #category : #sizing }
CogPOWERCompiler >> pushLinkRegisterByteSize [
	^8
]

{ #category : #'inline cacheing' }
CogPOWERCompiler >> relocateMethodReferenceBeforeAddress: pc by: delta [
	"If possible we generate the method address using pc-relative addressing.
	 If so we don't need to relocate it in code.  So check if pc-relative code was
	 generated, and if not, adjust a long sequence.  There are two cases, a push
	 or a register load.  If a push, then there is a register load, but in the instruction
	 before."
	| instr_ instr__ reference |
	
	"BOGUS -- First, we need to differentiate the push case.
	But in my (bgs) runs of the Reader, I never encountered it."
	
	instr_ := self instructionAt: pc-4.
	instr__ := self instructionAt: pc-8.
	"Then, we potentially are looking at PC-relative addressing.
	Let's hope not."
	(instr_ name = 'ori' and: [ instr__ name = 'addis' ]) ifFalse: [ self shouldBeImplemented ].
	reference := self int32InLisOriAt: pc-8.
	reference := reference + delta.
	self insert32BitOperand: reference intoLisOriAt: pc-8
]

{ #category : #'inline cacheing' }
CogPOWERCompiler >> rewriteCPICJumpAt: addressFollowingJump target: jumpTargetAddr [
	"Rewrite a jump instruction to call a different target.  This variant is used to reset the 
	jumps in the prototype CPIC to suit each use,.   
	Answer the extent of the code change which is used to compute the range of the icache to flush."
	<var: #addressFollowingJump type: #usqInt>
	<var: #jumpTargetAddr type: #usqInt>
	<inline: true>
	
	"There can be various cases here."
	"It may be a conditional jump:"
	((self instructionAt: addressFollowingJump-8) name = 'bc' and: [(self instructionAt: addressFollowingJump-4) name = 'b'])
		ifTrue: [ ^self rewriteConditionalJumpLongAt: addressFollowingJump target: jumpTargetAddr ].
		
	"Or it could be an unconditional jump, or a call... who knows"
	self shouldBeImplemented.
	" cogit processor pcMap at: addressFollowingJump-4 "
]

{ #category : #'inline cacheing' }
CogPOWERCompiler >> rewriteCallAt: callSiteReturnAddress target: callTargetAddress [
	"Rewrite a call instruction to call a different target.  This variant is used to link PICs
	 in ceSendMiss et al,.   
	Answer the extent of the code change which is used to compute the range of the icache to flush."
	| addr bla li |
	addr := callSiteReturnAddress-4.
	bla := self instructionAt: addr.
	bla name = 'ba' ifFalse: [ ^self shouldBeImplemented  ].
	li := callTargetAddress //4. "cf concretizeJumpIfTrue:"
	bla := bla substitute:  (Dictionary with: 'li'->li).
	objectMemory longAt: addr put: bla emit32.
	^4
]

{ #category : #'inline cacheing' }
CogPOWERCompiler >> rewriteConditionalJumpLongAt: callSiteReturnAddress target: callTargetAddress [
	| addr b li |
	"bc <around>; b relative"
	self assert: (self instructionAt: callSiteReturnAddress-8) name = 'bc'.
	self assert: ((self instructionAt: callSiteReturnAddress-8) fieldValue: 'bd') = 2.
	addr := callSiteReturnAddress-4.
	b := self instructionAt: addr.
	self assert: b name = 'b'.
	li := callTargetAddress - addr //4. "cf concretizeJumpIfTrue:"
	b := b substitute:  (Dictionary with: 'li'->li).
	objectMemory longAt: addr put: b emit32
]

{ #category : #'inline cacheing' }
CogPOWERCompiler >> rewriteInlineCacheAt: callSiteReturnAddress tag: cacheTag target: callTargetAddress [
	"Rewrite an inline cache to call a different target for a new tag.  This variant is used
	 to link unlinked sends in ceSend:to:numArgs: et al.  Answer the extent of the code
	 change which is used to compute the range of the icache to flush."
	callTargetAddress >= cogit minCallAddress ifFalse:
					[self error: 'linking callsite to invalid address'].
	
	"The IC looks like this:
	
	callSiteReturnAddress-(6*4):
		MoveUniqueC32:R:
			lis ClassR, <tag>
			ori ClassR, <tag>
	callSiteReturnAddress-(4*4):
		Call:
			bl .+1
			mflr LR
			addi LR, LR, +12
			ba <absTarget>
		...
	"
	self insert32BitOperand: cacheTag intoLisOriAt: callSiteReturnAddress-(6*4).
	self rewriteCallAt: callSiteReturnAddress target: callTargetAddress.
	
	^-1 "BOGUS, hopefully the -1 will catch it (this is for icache-flush"
]

{ #category : #'inline cacheing' }
CogPOWERCompiler >> rewriteInlineCacheTag: cacheTag at: callSiteReturnAddress [
	"Rewrite an inline cache with a new tag.  This variant is used
	 by the garbage collector."
	self insert32BitOperand: cacheTag into4InstructionsPreceding: callSiteReturnAddress -4
]

{ #category : #'inline cacheing' }
CogPOWERCompiler >> rewriteJumpFullAt: callSiteReturnAddress target: callTargetAddress [
	"Rewrite a full jump instruction to jump to a different target.	Answer the extent of the
	 code change which is used to compute the range of the icache to flush."

	self assert: (self instructionAt: callSiteReturnAddress-8) name = 'mtspr'.
	self assert: (self instructionAt: callSiteReturnAddress-4) name = 'bcctr'.
	self insert32BitOperand: callTargetAddress intoLisOriAt: callSiteReturnAddress-16.
	^-1 "to catch later"
]

{ #category : #'inline cacheing' }
CogPOWERCompiler >> rewriteJumpLongAt: callSiteReturnAddress target: callTargetAddress [
	"This variant is used to reset the 	jumps in the prototype CPIC to suit each use"
	
	^self rewriteJumpFullAt: callSiteReturnAddress target: callTargetAddress 
	
	"| addr instr_ |
	addr := callSiteReturnAddress-4.
	instr_ := self instructionAt: addr.
	instr_ name = 'b' ifTrue: [ 
		| li |
		li := callTargetAddress - addr //4.
		instr_ := instr_ substitute:  (Dictionary with: 'li'->li).
		objectMemory longAt: addr put: instr_ emit32.
		^4
	].
	
	
	self error.
	self assert: instr_ name = 'ba'.
	^self rewriteBAat: callSiteReturnAddress-4 newTarget: callTargetAddress"
]

{ #category : #abi }
CogPOWERCompiler >> saveAndRestoreLinkRegAround: aBlock [
	"If the processor's ABI includes a link register, generate instructions
	 to save and restore it around aBlock, which is assumed to generate code."
	<inline: true>
	| inst |
	inst := cogit PushR: LinkReg.
	aBlock value.
	cogit PopR: LinkReg.
	^inst
]

{ #category : #testing }
CogPOWERCompiler >> setsConditionCodesFor: aConditionalJumpOpcode [
	<inline: false> "to save Slang from having to be a real compiler (it can't inline switches that return)"
	"Answer if the receiver's opcode sets the condition codes correctly for the given conditional jump opcode.
	ARM has to check carefully since the V flag is not affected by non-comparison instructions"
	^opcode caseOf:
		{	[ArithmeticShiftRightCqR]	->	[self shiftSetsConditionCodesFor: aConditionalJumpOpcode].
			[ArithmeticShiftRightRR]	->	[self shiftSetsConditionCodesFor: aConditionalJumpOpcode].
			[LogicalShiftLeftCqR]		->	[self shiftSetsConditionCodesFor: aConditionalJumpOpcode].
			[LogicalShiftLeftRR]		->	[self shiftSetsConditionCodesFor: aConditionalJumpOpcode].
			[XorRR]					->	[true]
		}
		otherwise: [self halt: 'unhandled opcode in setsConditionCodesFor:'. false]
]

{ #category : #testing }
CogPOWERCompiler >> shiftSetsConditionCodesFor: aConditionalJumpOpcode [
	"check what flags the opcdoe needs setting - ARM doesn't set V when simply MOVing"
		^aConditionalJumpOpcode caseOf:
		{	[JumpNegative]	->	[true].
			[JumpZero]	->	[true].
			[JumpLess]	->	[true].
		}
		otherwise: [self halt: 'unhandled opcode in setsConditionCodesFor:'. false]
]

{ #category : #'generate machine code' }
CogPOWERCompiler >> sizePCDependentInstructionAt: eventualAbsoluteAddress [
	"Size a jump and set its address.  The target may be another instruction
	 or an absolute address.  On entry the address inst var holds our virtual
	 address. On exit address is set to eventualAbsoluteAddress, which is
	 where this instruction will be output.  The span of a jump to a following
	 instruction is therefore between that instruction's address and this
	 instruction's address ((which are both still their virtual addresses), but the
	 span of a jump to a preceding instruction or to an absolute address is
	 between that instruction's address (which by now is its eventual absolute
	 address) or absolute address and eventualAbsoluteAddress.

	 ARM is simple; the 26-bit call/jump range means no short jumps.  This routine
	 only has to determine the targets of jumps, not determine sizes."

	opcode = AlignmentNops ifTrue:
		[| alignment |
		 address := eventualAbsoluteAddress.
		 alignment := operands at: 0.
		 ^machineCodeSize := (eventualAbsoluteAddress + (alignment - 1) bitAnd: alignment negated)
							   - eventualAbsoluteAddress].
	self assert: (self isJump or: [opcode = Call or: [opcode = CallFull]]).
	self isJump ifTrue: [self resolveJumpTarget].
	address := eventualAbsoluteAddress.
	^machineCodeSize := maxSize
]

{ #category : #accessing }
CogPOWERCompiler >> stackPageInterruptHeadroomBytes [
	"Return a minimum amount of headroom for each stack page (in bytes).  In a
	 JIT the stack has to have room for interrupt handlers which will run on the stack.
	According to ARM architecture v5 reference manual chapter A2.6, the basic interrupt procedure does not push anything onto the stack. It uses SPSR_err and R14_err to preserve state. Afterwards, it calls an interrupt procedure. So leave some room."
	^128 "32 words"
]

{ #category : #'generate machine code - support' }
CogPOWERCompiler >> stop [
	^(CogPOWERCompiler>>#concretizeStop literalAt: 2) first value
]

{ #category : #'generate machine code - support' }
CogPOWERCompiler >> stopsFrom: startAddr to: endAddr [
	CogPOWERCompiler>>#concretizeStop literalAt: 2  .
	self assert: endAddr - startAddr + 1 \\ 4 = 0.
	startAddr to: endAddr by: 4 do: 
		[:addr | objectMemory longAt: addr put: self stop].
]

{ #category : #'inline cacheing' }
CogPOWERCompiler >> storeLiteral: literal beforeFollowingAddress: followingAddress [
	"Patch (rewrite over) the long constant loaded by a lis/ori sequence just before this address"
	| instr_ |
	instr_ := self instructionAt: followingAddress-4.
	instr_ name = 'cmpl'
		ifFalse: [ self insert32BitOperand: literal intoLisOriAt: followingAddress-8 ]
		ifTrue: [ self insert32BitOperand: literal intoLisOriAt: followingAddress-12 ]
]

{ #category : #'TA Assembler' }
CogPOWERCompiler >> templateMethod [
	| instr theEnvironment |
	theEnvironment := Dictionary new .
	1. 2. 3. 4. 5. 6. 7. 8.
	instr := #theInstruction.
	^self spitAll: (instr inEnvironment: theEnvironment)
]

{ #category : #simulation }
CogPOWERCompiler >> wantsNearAddressFor: anObject [
	"A hack hook to allow ARM to override the simulated address for the short-cut trampolines"
	<doNotGenerate>
	^anObject isSymbol and: [anObject beginsWith: 'ceShortCut']
]

{ #category : #'inline cacheing' }
CogPOWERCompiler >> zoneCallsAreRelative [
	"Answer if Call and JumpLong are relative and hence need to take the caller's
	 relocation delta into account during code compaction, rather than just the
	 callee's delta."
	^false 
]
