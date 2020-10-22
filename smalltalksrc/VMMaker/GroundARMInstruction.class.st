"
I add knowledge about ARM instructions that Cog -- for now -- insists on managing manually.
"
Class {
	#name : #GroundARMInstruction,
	#superclass : #ProcessorInstruction,
	#category : #'VMMaker-JIT'
}

{ #category : #decoding }
GroundARMInstruction >> extractOffsetFromBL [
	"we are told this is a BL <offset> instruction, so work out the offset it encodes"
	| relativeJump |
	self isB ifFalse: [ self error: 'Only B or BL' ].
	relativeJump := (self field: 'offset') signedValue.  "Type_BBL says offset is unsigned, but in reality it is signed"
	^relativeJump*4
]

{ #category : #testing }
GroundARMInstruction >> isB [
	^self name = 'b'
]

{ #category : #testing }
GroundARMInstruction >> isBL [
	^self name = 'b' and: [(self fieldValue: 'h') = 1]
]

{ #category : #testing }
GroundARMInstruction >> isCall [
	"Answer whether I am a call (not a CallFull)."
	"There are two types of calls: BL and/BLX encoding"
	^self isBL or: [ self isBLX ]
]

{ #category : #decoding }
GroundARMInstruction >> pcRelativeTo: currentPC [
	"Extract the address of the ldr rX, [pc, #NNN] inst"
	| offset |
	name = 'ldr1' ifFalse: [ self error: 'Only LDR1 allowed' ].
	(self fieldValue: 'rn') = 15 ifFalse: [ self error: 'Only relative to PC allowed' ].
	(self fieldValue: 'cond') = 14 ifFalse: [ self error: 'Only ALWAYS allowed' ].
	offset := self fieldValue: 'imm12'.
	(self fieldValue: 'u') = 0 ifTrue: [ offset := offset negated ].
	^currentPC + 8 + offset
]
