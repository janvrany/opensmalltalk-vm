Class {
	#name : #Booo,
	#superclass : #Object,
	#category : #'VMMaker-Tests'
}

{ #category : #'as yet unclassified' }
Booo class >> disassembleInstructionAt: ip In: memory into: aBlock [ 
	| lenAndDi |
	lenAndDi := self primitiveDisassembleAt: ip inMemory: memory.
	^aBlock value: lenAndDi last value: lenAndDi first
]

{ #category : #'as yet unclassified' }
Booo class >> primitiveDisassembleAt: address inMemory: memoryArray [ "<Bitmap|ByteArray>"
	"Answer an Array of the size and the disassembled code string
	for the instruction at the current instruction pointer in memory."
	| pdl instrBytes |
	instrBytes := memoryArray copyFrom: address+1 to: address+4.
	pdl := AcProcessorDescriptions armv5.
	^Array
		with: 4
		with: (pdl disassemble: instrBytes)
]
