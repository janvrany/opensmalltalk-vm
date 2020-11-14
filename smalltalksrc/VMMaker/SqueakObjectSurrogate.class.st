Class {
	#name : #SqueakObjectSurrogate,
	#superclass : #Object,
	#instVars : [
		'oop',
		'cointerpreter'
	],
	#category : #'VMMaker-JITSimulation'
}

{ #category : #'instance creation' }
SqueakObjectSurrogate class >> oop: oop cointerpreter: c [
	^self new
		oop: oop;
		cointerpreter: c;
		yourself 
]

{ #category : #accessing }
SqueakObjectSurrogate >> cointerpreter [
	^ cointerpreter
]

{ #category : #accessing }
SqueakObjectSurrogate >> cointerpreter: anObject [
	cointerpreter := anObject
]

{ #category : #accessing }
SqueakObjectSurrogate >> oop [
	^ oop
]

{ #category : #accessing }
SqueakObjectSurrogate >> oop: anObject [
	oop := anObject
]

{ #category : #printing }
SqueakObjectSurrogate >> printOn: aStream [
	aStream nextPutAll: (self cointerpreter cogit printOopString: oop)
]
