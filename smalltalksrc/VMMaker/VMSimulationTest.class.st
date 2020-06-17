Class {
	#name : #VMSimulationTest,
	#superclass : #TestCase,
	#category : #'VMMaker-Doodles'
}

{ #category : #tests }
VMSimulationTest >> test1 [ 
| cos |
cos := CogVMSimulator newWithOptions: #(
										Cogit StackToRegisterMappingCogit
										ObjectMemory Spur32BitCoMemoryManager
										haltOnExecuteMethod false
										MULTIPLEBYTECODESETS true),
										{#ISA. #ARMv5}.
"cos initializeThreadSupport."
cos desiredNumStackPages: 8. "Speeds up scavenging when simulating.  Set to e.g. 64 for something like the real VM."
cos openOn: 'spurreader.image'.
cos openAsMorph; run; halt

]
