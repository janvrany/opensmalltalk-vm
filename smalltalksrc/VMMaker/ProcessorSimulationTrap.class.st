Class {
	#name : #ProcessorSimulationTrap,
	#superclass : #Error,
	#instVars : [
		'pc',
		'nextpc',
		'address',
		'type',
		'registerAccessor'
	],
	#category : #'VMMaker-JITSimulation'
}

{ #category : #debugger }
ProcessorSimulationTrap class >> defaultIntegerBaseInDebugger [
	^16
]

{ #category : #'instance creation' }
ProcessorSimulationTrap class >> pc: pc nextpc: nextpc address: address type: type [
	^self new
		pc: pc;
		nextpc: nextpc;
		address: address;
		type: type
]

{ #category : #'instance creation' }
ProcessorSimulationTrap class >> pc: pc nextpc: nextpc address: address type: type accessor: regAccessorMessage [
	^self new
		pc: pc;
		nextpc: nextpc;
		address: address;
		type: type;
		registerAccessor: regAccessorMessage
]

{ #category : #accessing }
ProcessorSimulationTrap >> address [
	^ address
]

{ #category : #accessing }
ProcessorSimulationTrap >> address: anObject [
	address := anObject
]

{ #category : #testing }
ProcessorSimulationTrap >> isResumable [
	^true
]

{ #category : #accessing }
ProcessorSimulationTrap >> nextpc [
	^ nextpc
]

{ #category : #accessing }
ProcessorSimulationTrap >> nextpc: anObject [
	nextpc := anObject
]

{ #category : #accessing }
ProcessorSimulationTrap >> pc [
	^ pc
]

{ #category : #accessing }
ProcessorSimulationTrap >> pc: anObject [
	pc := anObject
]

{ #category : #printing }
ProcessorSimulationTrap >> printOn: aStream [
	super printOn: aStream.
	aStream nextPutAll: ' address: '; print: address; nextPut: $/. address printOn: aStream base: 16.
	aStream nextPutAll: ' type: '; print: type.
	aStream nextPutAll: ' accessor: '; print: registerAccessor; nextPut: $)
]

{ #category : #accessing }
ProcessorSimulationTrap >> registerAccessor [
	^ registerAccessor
]

{ #category : #accessing }
ProcessorSimulationTrap >> registerAccessor: anObject [
	registerAccessor := anObject
]

{ #category : #accessing }
ProcessorSimulationTrap >> type [
	^ type
]

{ #category : #accessing }
ProcessorSimulationTrap >> type: anObject [
	type := anObject
]
