Class {
	#name : #SqueakMethodSurrogate,
	#superclass : #SqueakObjectSurrogate,
	#category : #'VMMaker-JITSimulation'
}

{ #category : #'as yet unclassified' }
SqueakMethodSurrogate >> at: index [ 
	^cointerpreter objectMemory fetchByte: index-1 ofObject: oop
]

{ #category : #'as yet unclassified' }
SqueakMethodSurrogate >> getSource [
	^ self getSourceFor: self selector in: self methodClass.
]

{ #category : #'as yet unclassified' }
SqueakMethodSurrogate >> getSourceFor: selector in: class [
	^self getSourceFromFileAt: self sourcePointer
]

{ #category : #'as yet unclassified' }
SqueakMethodSurrogate >> getSourceFromFileAt: sourcePointer [ 
	| remoteString |
	remoteString := self targetSourceFiles remoteStringAt: sourcePointer.
	^remoteString text
]

{ #category : #'as yet unclassified' }
SqueakMethodSurrogate >> hasPragmaNamed: aString [ 
	^false
]

{ #category : #'as yet unclassified' }
SqueakMethodSurrogate >> isDoIt [
	^false
]

{ #category : #'as yet unclassified' }
SqueakMethodSurrogate >> lastIndex [
	^cointerpreter objectMemory lengthOf: oop
]

{ #category : #'as yet unclassified' }
SqueakMethodSurrogate >> methodClass [
	^SqueakObjectSurrogate oop: self methodClassOop cointerpreter: self cointerpreter 
]

{ #category : #'as yet unclassified' }
SqueakMethodSurrogate >> methodClassOop [
	^self cointerpreter methodClassOf: oop
]

{ #category : #'as yet unclassified' }
SqueakMethodSurrogate >> selector [
	^self cointerpreter theStringOf: self selectorOop
]

{ #category : #'as yet unclassified' }
SqueakMethodSurrogate >> selectorOop [
	^self cointerpreter findSelectorOfMethod: oop
]

{ #category : #'as yet unclassified' }
SqueakMethodSurrogate >> sourcePointer [
	| msz |
	msz := self lastIndex.
	^(self at: msz) - 251 << 8 + (self at: msz-1) << 8
	 + (self at: msz-2) << 8 + (self at: msz-3).
]

{ #category : #'as yet unclassified' }
SqueakMethodSurrogate >> targetSourceFiles [
	"Cf. SourceFiles"
	^BabySourceFileArray new ensureOpen 
]
