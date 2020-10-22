Class {
	#name : #GroundPOWERInstruction,
	#superclass : #ProcessorInstruction,
	#category : #'VMMaker-JIT'
}

{ #category : #testing }
GroundPOWERInstruction >> isCall [
	"Answer whether I am a call (not a CallFull)."
	^self disassemble ~= 'bctrl'
]
