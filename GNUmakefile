PROJECT=VMMaker

DIR_MACHINEARITHMETIC ?= 3rdparty/MachineArithmetic
DIR_ARCHC ?= 3rdparty/ArchC
DIR_SMALLRSP ?= 3rdparty/SmallRSP
DIR_PDL ?= 3rdparty/pdl
DIR_GEM5 ?= 3rdparty/gem5
DIR_THINSHELL ?= 3rdparty/thinshell



all: pharo-ui $(PROJECT).image image/r.1.image gem5 thinshell

pharo pharo-ui Pharo.image:
	curl https://get.pharo.org/64/80+vm | bash

$(PROJECT).image: pharo Pharo.image image/r.1.image smalltalksrc $(DIR_MACHINEARITHMETIC) $(DIR_ARCHC) $(DIR_SMALLRSP)
	./pharo Pharo.image save $(PROJECT)
	# Register Iceberg repositories to ease development.
	#
	# Oh no, we cannot do this because Iceberg does not support git modules.
	# Sigh.
	# ./pharo $@ eval --save "(IceRepositoryCreator new location: '$(DIR_MACHINEARITHMETIC)/' asFileReference; createRepository) register" || rm $@
	# ./pharo $@ eval --save "(IceRepositoryCreator new location: '$(DIR_ARCHC)/src' asFileReference; createRepository) register" || rm $@
	# ./pharo $@ eval --save "(IceRepositoryCreator new location: '$(DIR_SMALLRSP)/src' asFileReference; createRepository) register" || rm $@
	./pharo $@ eval --save "(IceRepositoryCreator new location: '.' asFileReference; createRepository) register" || rm $@

	# Load 3rd party libraries from local clones
	./pharo $@ eval --save "Metacello new baseline: 'MachineArithmetic'; repository: 'tonel://$(DIR_MACHINEARITHMETIC)'; onConflictUseLoaded; load." || rm $@
	./pharo $@ eval --save "Metacello new baseline: 'ArchC'; repository: 'tonel://$(DIR_ARCHC)/src'; onConflictUseLoaded; load." || rm $@
	./pharo $@ eval --save "Metacello new baseline: 'SmallRSP'; repository: 'tonel://$(DIR_SMALLRSP)/src'; onConflictUseLoaded; load." || rm $@

	# Load VMMaker
	./pharo $@ eval --save "Metacello new baseline: '$(PROJECT)'; repository: 'tonel://./smalltalksrc'; onConflictUseLoaded; load." || rm $@

	# Perform post-load mambo-jumbo
	ARCHC_PDL_DIR=$(DIR_PDL)/ ./pharo-ui $@ eval --save "\
	    Author fullName: 'anonymous'.                 \
		Smalltalk at: #NewspeakVM put: false.		  \
		ArchCOpalTest recompile.					  \
		TestCase defaultTimeLimit: 100 years.		  \
		TargetAware compile:'hostIP ^''localhost'''.  \
		SystemWindow closeTopWindow.                  \
		GTPlayground openContents: 'VMSimulationTest debug: #testPOWER.'.\
		"

	@echo ""
	@echo "To open Pharo $(PROJECT) image run:"
	@echo ""
	@echo "    ARCHC_PDL_DIR=$(DIR_PDL)/ COG_READER_IMAGE=image/r.1.image ./pharo-ui $(PROJECT).image"
	@echo ""

image/r.1.image: $(DIR_THINSHELL)/squeak/Reader.tar.gz
	tar xf $<
	touch $@

gem5: $(DIR_GEM5)/build/POWER/gem5.debug

$(DIR_GEM5)/build/POWER/gem5.debug:
	scons -C $(DIR_GEM5) -j4 build/POWER/gem5.debug)

thinshell: $(DIR_THINSHELL)/squeak/power/squeak.elf

$(DIR_THINSHELL)/squeak/power/squeak.elf:
	$(MAKE) -C $(DIR_THINSHELL)/squeak/power

run-g5: thinshell gem5
	$(MAKE) -C $(DIR_THINSHELL)/squeak/power \
		G5DIR=$(shell pwd)/$(DIR_GEM5) \
		DEBUG5=--debug-flags=Exec \
		g5

run-vmmaker: $(PROJECT).image
	ARCHC_PDL_DIR=$(DIR_PDL)/ COG_READER_IMAGE=image/r.1.image ./pharo-ui $< eval --no-quit "VMSimulationTest debug: #testPOWER."

clean:
	rm -f $(PROJECT).image $(PROJECT).changes test-reports *.fuel
	rm -fr pharo-local

mrproper: clean
	rm -rf Pharo* pharo* icon-packs

.PHONY: gem5 thinshell run-g5 run-vmmaker

