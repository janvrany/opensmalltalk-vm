Class {
	#name : #Scanner,
	#superclass : #Object,
	#classVars : [
		'TypeTable'
	],
	#category : #'VMMakerCompatibilityForPharo6-System'
}

{ #category : #initialization }
Scanner class >> initialize [
	self initializeTypeTable
]

{ #category : #initialization }
Scanner class >> initializeTypeTable [
	"self initializeTypeTable"

	| newTable |
	newTable := Array new: 256 withAll: #xBinary. "default"
	newTable atAll: #(9 10 12 13 32 ) put: #xDelimiter. "tab lf ff cr space"
	newTable atAll: ($0 asciiValue to: $9 asciiValue) put: #xDigit.

	1 to: 255
		do: [:index |
			(Character value: index) isLetter
				ifTrue: [newTable at: index put: #xLetter]].

	newTable at: $" asciiValue put: #xDoubleQuote.
	newTable at: $# asciiValue put: #xLitQuote.
	newTable at: $$ asciiValue put: #xDollar.
	newTable at: $' asciiValue put: #xSingleQuote.
	newTable at: $: asciiValue put: #xColon.
	newTable at: $( asciiValue put: #leftParenthesis.
	newTable at: $) asciiValue put: #rightParenthesis.
	newTable at: $. asciiValue put: #period.
	newTable at: $; asciiValue put: #semicolon.
	newTable at: $[ asciiValue put: #leftBracket.
	newTable at: $] asciiValue put: #rightBracket.
	newTable at: ${ asciiValue put: #leftBrace.
	newTable at: $} asciiValue put: #rightBrace.
	newTable at: $^ asciiValue put: #upArrow.
	newTable at: $_ asciiValue put: #xUnderscore.
	newTable at: $| asciiValue put: #verticalBar.
	TypeTable := newTable "bon voyage!"
]

{ #category : #testing }
Scanner class >> isLiteralSymbol: aSymbol [ 
	"Test whether a symbol can be stored as # followed by its characters.  
	Symbols created internally with asSymbol may not have this property, 
	e.g. '3' asSymbol."

	| i ascii type next last |
	i := aSymbol size.
	i = 0 ifTrue: [^ false].

	"TypeTable should have been origined at 0 rather than 1 ..."
	ascii := (aSymbol at: 1) asciiValue.
	type := TypeTable at: ascii ifAbsent: [^false].
	type == #xLetter ifTrue: [
		next := last := nil.
		[i > 1]
				whileTrue: 
					[ascii := (aSymbol at: i) asciiValue.
					type := TypeTable at: ascii ifAbsent: [^false].
					(type == #xLetter or: [type == #xDigit or: [type == #xColon
							and: [
								next == nil
									ifTrue: [last := #xColon. true] 
									ifFalse: [last == #xColon and: [next ~~ #xDigit and: [next ~~ #xColon]]]]]])
						ifFalse: [^ false].
					next := type.
					i := i - 1].
			^ true].
	type == #xBinary ifTrue:
		[^(2 to: i) allSatisfy: [:j |
			ascii := (aSymbol at: j) asciiValue.
			(TypeTable at: ascii ifAbsent: []) == #xBinary]].
	type == #verticalBar ifTrue: [^i = 1].
	^false
]

{ #category : #scanning }
Scanner >> scanTokens: aString [ 

	^ (RBScanner on: aString readStream) contents
]

{ #category : #accessing }
Scanner >> typedScanTokens: textOrString [ 
	"Answer an Array that has been tokenized with literals mapped to literals,
	 special characters mapped to symbols and variable names and keywords
	 to strings. This methiod accepts _ (underscore) as an assignment token
	 irrespective of whether the system prefers := as the assignment token."

	^ (self scanTokens: textOrString)
		collect: [ :e | | value |
			value := e value.
			e isSpecial ifTrue: [ value := value asSymbol ].
			value ]
]
