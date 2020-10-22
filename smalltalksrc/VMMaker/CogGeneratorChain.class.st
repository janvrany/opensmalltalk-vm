Class {
	#name : #CogGeneratorChain,
	#superclass : #Object,
	#instVars : [
		'stack',
		'cogit',
		'string',
		'pc',
		'rtlStartPC',
		'nMachineInstrs'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #logic }
CogGeneratorChain >> addresses [
	^rtlStartPC to: nMachineInstrs - 1 * 4 + rtlStartPC by: 4
]

{ #category : #logic }
CogGeneratorChain >> addressesAndInstructions [
	^self addresses collect: [ :a |
		a -> (cogit backEnd instructionAt: a) ]
]

{ #category : #accessing }
CogGeneratorChain >> cogit [
	^ cogit
]

{ #category : #accessing }
CogGeneratorChain >> cogit: anObject [
	cogit := anObject
]

{ #category : #GT }
CogGeneratorChain >> gtInspectorGenChainIn: composite [
	<gtInspectorPresentationOrder: 31>
	^composite fastList
		title: 'Gen chain';
		display: [ stack collect: #key ]
]

{ #category : #GT }
CogGeneratorChain >> gtInspectorNativeCodeIn: composite [
	<gtInspectorPresentationOrder: 31>
	^ composite fastList
		title: 'Native code';
		display: [ self addressesAndInstructions ];
		format: [ :ai | "instr disassemble" 
			(ai key = pc ifTrue: '--> ' ifFalse: ''),			
			ai value disassemble  ]
		" ; send: [ :x | x halt ]"
]

{ #category : #logic }
CogGeneratorChain >> instructionAtPC [
	^cogit backEnd instructionAt: pc
]

{ #category : #logic }
CogGeneratorChain >> instructions [ 
	^self addresses collect: [ :a |
		cogit backEnd instructionAt: a ]
]

{ #category : #logic }
CogGeneratorChain >> interestingContext [
	| c index |
	stack isNil ifTrue: [ ^nil ].
	c := stack detect: [ :ctxAndPC | ctxAndPC key methodSelector first isUppercase ] ifNone: [ ^nil ].
	index := stack indexOf: c.
	"This is really bad.  We can't just say #sender, because even though the context is a copy, it's still somehow cleared."
	^(stack at: index+1) key
]

{ #category : #accessing }
CogGeneratorChain >> nMachineInstrs [
	^ nMachineInstrs
]

{ #category : #accessing }
CogGeneratorChain >> nMachineInstrs: anObject [
	nMachineInstrs := anObject
]

{ #category : #accessing }
CogGeneratorChain >> pc [
	^ pc
]

{ #category : #accessing }
CogGeneratorChain >> pc: anObject [
	pc := anObject
]

{ #category : #accessing }
CogGeneratorChain >> rtlStartPC [
	^ rtlStartPC
]

{ #category : #accessing }
CogGeneratorChain >> rtlStartPC: anObject [
	rtlStartPC := anObject
]

{ #category : #accessing }
CogGeneratorChain >> stack [
	^ stack
]

{ #category : #accessing }
CogGeneratorChain >> stack: anObject [
	stack := anObject
]

{ #category : #accessing }
CogGeneratorChain >> string [
	^ string
]

{ #category : #accessing }
CogGeneratorChain >> string: anObject [
	string := anObject
]
