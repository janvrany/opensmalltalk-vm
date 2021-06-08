Class {
	#name : #VMSimulationTest,
	#superclass : #TestCase,
	#instVars : [
		'image'
	],
	#category : #'VMMaker-Doodles'
}

{ #category : #running }
VMSimulationTest >> ensureZ3Context [
	Z3Context current isNull ifTrue: [ self reset ]
]

{ #category : #running }
VMSimulationTest >> reset [ 
	Z3Context createGlobalContext.
	AcProcessorDescriptions reset.
	CogARMCompiler recompile.
	CogOutOfLineLiteralsARMCompiler recompile.
	CogInLineLiteralsARMCompiler recompile.
	CogPOWERCompiler recompile.
"
ArchCOpalTest recompile.
TestCase defaultTimeLimit: 100 years.
"
]

{ #category : #running }
VMSimulationTest >> setUp [
	image := OSEnvironment current getEnv: 'COG_READER_IMAGE'.
	self assert: image asFileReference exists.
]

{ #category : #tests }
VMSimulationTest >> testARM [
	| cos |
	self ensureZ3Context.
AcProcessorDescriptions armv5 grounder processorInstructionClass: GroundARMInstruction.
cos := CogVMSimulator newWithOptions: #(
										Cogit StackToRegisterMappingCogit
										compilationTrace 1 "OR of bit-flags"
										ObjectMemory Spur32BitCoMemoryManager
										haltOnExecuteMethod false
										MULTIPLEBYTECODESETS true),
										{#ISA. #ARMv5}.
"cos desiredNumStackPages: 8."
cos openOn: image.
cos openAsMorph; run
]

{ #category : #tests }
VMSimulationTest >> testPOWER [
	| cos |
	self ensureZ3Context.
AcProcessorDescriptions powerpc grounder processorInstructionClass: GroundPOWERInstruction.
cos := CogVMSimulator newWithOptions: #(
										Cogit StackToRegisterMappingCogit
										compilationTrace 1 "OR of bit-flags"
										ObjectMemory Spur32BitCoMemoryManager
										haltOnExecuteMethod false
										MULTIPLEBYTECODESETS true),
										{#ISA. #POWER}.
"cos desiredNumStackPages: 8."
cos openOn: image.
cos openAsMorph; run
]
