Class {
	#name : #FrameSurrogate,
	#superclass : #Object,
	#instVars : [
		'fp',
		'cointerpreter'
	],
	#category : #'VMMaker-JITSimulation'
}

{ #category : #'instance creation' }
FrameSurrogate class >> fp: fp cointerpreter: c [
	^self new
		fp: fp;
		cointerpreter: c;
		yourself
]

{ #category : #'as yet unclassified' }
FrameSurrogate >> cogit [
	^self cointerpreter cogit
]

{ #category : #accessing }
FrameSurrogate >> cointerpreter [
	^ cointerpreter
]

{ #category : #accessing }
FrameSurrogate >> cointerpreter: anObject [
	cointerpreter := anObject
]

{ #category : #accessing }
FrameSurrogate >> fp [
	^ fp
]

{ #category : #accessing }
FrameSurrogate >> fp: anObject [
	fp := anObject
]

{ #category : #reflection }
FrameSurrogate >> frameCallerFP [
	^self cointerpreter frameCallerFP: self fp
]

{ #category : #'as yet unclassified' }
FrameSurrogate >> gtConstructDebuggerInspectorIn: composite for: aDebugger [
	
	^ composite custom: ((GTDebuggerInspector new  
		debugger: aDebugger;
		notifyPaneRemoved: true;
		showFirst: [ :a | a custom: (aDebugger class variablesBrowserClass new 
			debugger: aDebugger;
			startOn: self;
			restoreSettings;
			yourself).];
		yourself) 
			startOn: self)
]

{ #category : #'as yet unclassified' }
FrameSurrogate >> gtDebuggerRetrieveVariableValuePairs [
	| fieldList |
	fieldList := cointerpreter variablePairsFP: self fp.
	
	
	fieldList add: (GTInspectorDynamicNode hostObject: self label: 'thisContext' value: self).
	
	^fieldList
]

{ #category : #'as yet unclassified' }
FrameSurrogate >> isDead [
	^true
]

{ #category : #'as yet unclassified' }
FrameSurrogate >> method [
	^SqueakMethodSurrogate oop: self methodObjectOop cointerpreter: self cointerpreter 
]

{ #category : #'context API' }
FrameSurrogate >> methodClass [
	^SqueakObjectSurrogate oop: self methodClassOop cointerpreter: self cointerpreter 
]

{ #category : #reflection }
FrameSurrogate >> methodClassName [
	^self cointerpreter theNameOfClass: self methodClassOop count: 5
]

{ #category : #reflection }
FrameSurrogate >> methodClassOop [
	^self cointerpreter findClassOfMethod: self methodObjectOop forReceiver: self receiverOop
]

{ #category : #reflection }
FrameSurrogate >> methodObjectOop [
	^self cointerpreter frameMethodObject: self fp
	
]

{ #category : #reflection }
FrameSurrogate >> methodSelectorOop [
	^self cointerpreter findSelectorOfMethod: self methodObjectOop 
	
]

{ #category : #'as yet unclassified' }
FrameSurrogate >> outerContext [
	^nil "BOGUS"
]

{ #category : #'as yet unclassified' }
FrameSurrogate >> outerMostContext [
	^ self outerContext 
		ifNil: [ self ]
		ifNotNil: [ self outerContext ]
]

{ #category : #printing }
FrameSurrogate >> printOn: aStream [
	aStream nextPutAll: 'FP='.
	self fp asInteger printOn: aStream base: 16 length: 8 padded: true.
	aStream space.
	aStream nextPut: (
		(self cointerpreter isMachineCodeFrame: self fp)
			ifTrue: [$M] ifFalse: [$I]).
	aStream space.
	aStream nextPutAll: self methodClassName.
	aStream nextPutAll: '>>'.
	aStream nextPutAll: self selector.
]

{ #category : #reflection }
FrameSurrogate >> receiver [
	^SqueakObjectSurrogate oop: self receiverOop cointerpreter: self cointerpreter 
]

{ #category : #reflection }
FrameSurrogate >> receiverClassName [
	^self cointerpreter theNameOfClass: self receiverClassOop count: 5
]

{ #category : #reflection }
FrameSurrogate >> receiverClassOop [
	^self cointerpreter objectMemory fetchClassOf: self receiverOop
]

{ #category : #reflection }
FrameSurrogate >> receiverOop [
	^self cointerpreter frameReceiver: self fp
	
]

{ #category : #reflection }
FrameSurrogate >> selector [
	^self cointerpreter theStringOf: self methodSelectorOop
]

{ #category : #'context API' }
FrameSurrogate >> sender [
	| prevFP |
	prevFP := self frameCallerFP.
	prevFP = 0 ifTrue: [ ^nil ].
	^self class fp: prevFP cointerpreter: self cointerpreter 
]

{ #category : #'context API' }
FrameSurrogate >> sourceCode [ 
	^self method getSource
]

{ #category : #'as yet unclassified' }
FrameSurrogate >> stack [ 
	"Answer an Array of the contexts on the receiver's sender chain."

	^self stackOfSize: 9999
]

{ #category : #'as yet unclassified' }
FrameSurrogate >> stackOfSize: limit [ 
	"Answer an OrderedCollection of the top 'limit' contexts
	 on the receiver's sender chain."

	| stack context |
	stack := OrderedCollection new.
	stack addLast: (context := self).
	[(context := context sender) ~~ nil
	 and: [stack size < limit]] whileTrue: [
		stack addLast: context ].
	^ stack
]
