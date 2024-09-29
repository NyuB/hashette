.PHONY: default build fmt test test-promote

# If INSTALL_ROOT is in your PATH, so will be the installed executable
INSTALL_ROOT=~/bin

default: fmt test

# Build the executable then copy it under INSTALL_ROOT
install: fmt build test
	# Copy the executable into installation directory
	cp _build/install/default/bin/hashette $(INSTALL_ROOT)/hashette
	# Make the installed file writable to allow future deletion or replacement
	chmod +w $(INSTALL_ROOT)/hashette

build:
	dune build

# Format sources, formatting can be configured in .ocamlformat
fmt:
	-dune fmt

test:
	dune test

# Update expected test results with whatever the current output is, run this once you are ok with the current behaviour
test-promote:
	dune test --auto-promote
