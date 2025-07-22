.PHONY: build install clean

# Default target
all: build

# Build the plugin
build:
	@echo "Building Gemini plugin..."
	@go build -buildmode=plugin -o gemini.so gemini.go

# Install the plugin
install: build
	@echo "Installing Gemini plugin..."
	@mkdir -p $(HOME)/.nexus/plugins
	@cp gemini.so $(HOME)/.nexus/plugins/
	@cp plugin.json $(HOME)/.nexus/plugins/gemini.json
	@echo "Plugin installed successfully!"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -f gemini.so

# Setup the Gemini CLI
setup:
	@echo "Setting up Gemini CLI..."
	@mkdir -p $(HOME)/gemini-cli
	@cp -r /Users/MacInTosh/gemini-cli/. $(HOME)/gemini-cli/
	@cd $(HOME)/gemini-cli && ./install.sh
