Class {
	#name : #BaselineOfVMMaker,
	#superclass : #BaselineOf,
	#category : #BaselineOfVMMaker
}

{ #category : #baselines }
BaselineOfVMMaker >> baseline: spec [
	<baseline>
	spec
		for: #pharo
		do: [
			spec baseline: 'SmallRSP' with: [
				spec repository: 'github://shingarov/SmallRSP:squeak'
			].
			spec
				package: 'VMMakerCompatibilityForPharo6';
				package: 'VMMakerLoadingDependencies'.
			spec
				package: 'VMMaker' with: [ spec requires: #('SmallRSP' 'VMMakerCompatibilityForPharo6' 'VMMakerLoadingDependencies') ]				
		]
]
