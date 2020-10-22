"
Here's a doit to generate my code:
	| offset crtab |
	offset := 1.
	crtab := String with: Character cr with: Character tab.
	CogMethod instVarNamesAndTypesForTranslationDo:
		[:name :type| | isByte class |
		(isByte := type = 'unsigned char') ifFalse:
			[offset := (offset - 1 + 3 bitAnd: -4) + 1].
		class := (CogBlockMethod instVarNames includes: name)
					ifTrue: [CogBlockMethodSurrogate32]
					ifFalse: [CogMethodSurrogate32].
		class
			compile: name, crtab, '^memory unsigned', (isByte ifTrue: ['ByteAt:'] ifFalse: ['LongAt:']), ' address + ', offset printString
			classified: #accessing.
		class
			compile: name, ': aValue', crtab, '^memory unsigned', (isByte ifTrue: ['ByteAt:'] ifFalse: ['LongAt:']), ' address + ', offset printString,
					' put: aValue'
			classified: #accessing.
		offset := offset + (isByte ifTrue: [1] ifFalse: [4])].
	CogMethodSurrogate32 class compile: 'alignedByteSize', crtab, '^', (offset - 1 + 3 bitAnd: -4) printString classified: #'instance creation'

"
Class {
	#name : #CogMethodSurrogate32,
	#superclass : #CogBlockMethodSurrogate32,
	#category : #'VMMaker-JITSimulation'
}

{ #category : #accessing }
CogMethodSurrogate32 class >> alignedByteSize [
	^20 + self baseHeaderSize
]

{ #category : #accessing }
CogMethodSurrogate32 class >> offsetOf: aByteSymbol [
	"These should be generated!!"
	| baseHeaderSize |
	baseHeaderSize := self objectMemoryClass baseHeaderSize.
	^aByteSymbol caseOf:
		{	[#methodObject]		-> [8 + baseHeaderSize].
			[#methodHeader]		-> [12 + baseHeaderSize].
			[#selector]				-> [16 + baseHeaderSize].
			[#blockEntryOffset]	-> [6 + baseHeaderSize].
		}
]

{ #category : #accessing }
CogMethodSurrogate32 >> blockEntryOffset [
	^memory unsignedShortAt: address + 7 + baseHeaderSize
]

{ #category : #accessing }
CogMethodSurrogate32 >> blockEntryOffset: aValue [
	^memory
		unsignedShortAt: address + baseHeaderSize + 7
		put: aValue
]

{ #category : #accessing }
CogMethodSurrogate32 >> blockSize [
	^memory unsignedShortAt: address + 5 + baseHeaderSize
]

{ #category : #accessing }
CogMethodSurrogate32 >> blockSize: aValue [
	^memory
		unsignedShortAt: address + baseHeaderSize + 5
		put: aValue
]

{ #category : #'Cog method structure' }
CogMethodSurrogate32 >> decodeMap [
	"Iterate over this method's map, decode each entry
		and answer an ordered collection of those entries.
		Each entry is an association mcpc->annotation.
		NB: All this knowledge will eventually be migrated
		here from Cogit, so Cogit will have none of these
		constants like FirstAnnotation etc."
	| mcpc map mapByte annotation result |
	result := OrderedCollection new.
	self cmType = CMBlock ifTrue: [^self shouldBeImplemented].
	mcpc := cogit firstMappedPCFor: self.
	map := cogit mapStartFor: self.
	[(mapByte := cogit objectMemory byteAt: map) ~= 0"MapEnd"] whileTrue:
		[mapByte >= 64"FirstAnnotation"
			ifTrue:
				[mcpc := mcpc + ((mapByte bitAnd: 31"DisplacementMask") * 4).
				 "If this is an IsSendCall annotation, peek ahead for an IsAnnotationExtension, and consume it."
				 ((annotation := mapByte >> 5"AnnotationShift") = 7"IsSendCall"
				  and: [(mapByte := cogit objectMemory byteAt: map - 1) >> 5"AnnotationShift" = 1"IsAnnotationExtension"]) ifTrue:
					[annotation := annotation + (mapByte bitAnd: 31"DisplacementMask").
					 map := map - 1].
				 result add: mcpc->annotation ]
			ifFalse:
				[mapByte < (1"IsAnnotationExtension" << 5"AnnotationShift") ifTrue:
					[mcpc := mcpc + ((mapByte - 0"DisplacementX2N" << 5"AnnotationShift") * 4)]].
		 map := map - 1].
	^result
]

{ #category : #disassembly }
CogMethodSurrogate32 >> disassembleMapOn: s [
	self decodeMap do: [ :entry | self printMapEntry: entry on: s ]

]

{ #category : #GT }
CogMethodSurrogate32 >> gtInspectorCodeRangesIn: composite [
	<gtInspectorPresentationOrder: 21>

	^ composite fastTable
		title: 'Code ranges';
		display: [ cogit codeRangesFor: self ];
		column: 'first' evaluated: [ :each | each first ];
		column: 'last'  evaluated: [ :each | each last ];
		column: 'startPC' evaluated: [ :each | each startpc ];
		column: 'endPC' evaluated: [ :each | each endPC ]
]

{ #category : #GT }
CogMethodSurrogate32 >> gtInspectorHeaderIn: composite [
	<gtInspectorPresentationOrder: 24>

	^ composite text
		title: 'Header';
		display: [
			| s |
			s := WriteStream on: String new.
			cogit printMethodHeader: self on: s. "will refactor into MethodSurrogate"
			s contents ]
]

{ #category : #GT }
CogMethodSurrogate32 >> gtInspectorMCIn: composite [
	<gtInspectorPresentationOrder: 23>

	^ composite text
		title: 'Machine code';
		display: [
			| s |
			s := WriteStream on: String new.
			cogit disassembleMethod: self on: s. "will refactor to surrogate"
			s contents ]
]

{ #category : #GT }
CogMethodSurrogate32 >> gtInspectorMapIn: composite [
	<gtInspectorPresentationOrder: 22>

	^ composite text
		title: 'Map';
		display: [
			| s |
			s := WriteStream on: String new.
			self disassembleMapOn: s.
			s contents ]
]

{ #category : #'Cog method structure' }
CogMethodSurrogate32 >> methodContainingMcpc: mcpc [
	| startMcpc |
	startMcpc := self startMcpcFor: mcpc.
	startMcpc = (self asInteger + (cogit sizeof: CogMethod))
		ifTrue: [^self]
		ifFalse: [^self class new
			address: (startMcpc - (cogit sizeof: CogBlockMethod));
			memory: memory;
			cogit: cogit;
			yourself ]
]

{ #category : #accessing }
CogMethodSurrogate32 >> methodHeader [
	^memory unsignedLongAt: address + 13 + baseHeaderSize
]

{ #category : #accessing }
CogMethodSurrogate32 >> methodHeader: aValue [
	^memory
		unsignedLongAt: address + baseHeaderSize + 13
		put: aValue
]

{ #category : #accessing }
CogMethodSurrogate32 >> methodObject [
	^memory unsignedLongAt: address + 9 + baseHeaderSize
]

{ #category : #accessing }
CogMethodSurrogate32 >> methodObject: aValue [
	^memory
		unsignedLongAt: address + baseHeaderSize + 9
		put: aValue
]

{ #category : #disassembly }
CogMethodSurrogate32 >> printMapEntry: ass on: aStream [
	"Print the Map entry's mcpc, its annotation and the corresponding bytecode pc, if any."
	| annotation mcpc codeRanges startmcpc subMethod name codeRange |
	annotation := ass value.
	mcpc := ass key.
	codeRanges := cogit codeRangesFor: self.

startmcpc := self startMcpcFor: mcpc.
subMethod := self methodContainingMcpc: mcpc.	

		"Find the start of the block by searching the code ranges."
		codeRange := codeRanges detect: [:range| range includes: mcpc] ifNone: [codeRanges detect: [:range| range last + 1 = mcpc]].
		codeRange first = mcpc ifTrue:
			[aStream nextPutAll: 'startpc: '; print: codeRange startpc; cr].
		aStream
			next: 2 put: Character space;
			nextPutAll: (mcpc hex);  space;
			nextPutAll: (name := cogit class annotationConstantNames at: annotation + 1);
			next: 20 - name size put: Character space;
			nextPut: $(;
			nextPutAll: ((cogit findMapLocationForMcpc: mcpc inMethod: self) hex).
		(cogit isPCMappedAnnotation: annotation) ifTrue:
			[aStream
				nextPutAll: ', bc: ';
				print: (cogit bytecodePCFor: mcpc startBcpc: codeRange startpc in: subMethod)].
		(cogit isSendAnnotation: annotation) ifTrue:
			[| sel |
			sel := cogit selectorForSendAt: mcpc annotation: annotation in: self methodObject.
			sel isInteger ifTrue:
				[sel := cogit lookupAddress: sel].
			sel isString ifTrue:
				[aStream space; nextPutAll: sel]].
		aStream
			nextPut: $);
			cr; flush.
	^0
]

{ #category : #accessing }
CogMethodSurrogate32 >> selector [
	^memory unsignedLongAt: address + 17 + baseHeaderSize
]

{ #category : #accessing }
CogMethodSurrogate32 >> selector: aValue [
	^memory
		unsignedLongAt: address + baseHeaderSize + 17
		put: aValue
]

{ #category : #'Cog method structure' }
CogMethodSurrogate32 >> startMcpcFor: mcpc [
	"Ansewr the start of machine code range containing the indicated mcpc,
	or nil if it's not within any of the receiver's code ranges."
	^((cogit codeRangesFor: self)
					detect: [:range| range includes: mcpc]
					ifNone:
						[(cogit codeRangesFor: self)
							detect: [:range| range last + 1 = mcpc]
							ifNone: [^nil]]) first.
]
