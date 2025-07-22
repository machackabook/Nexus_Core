package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/urfave/cli/v2" // Assuming Nexus Core uses urfave/cli
)

// GeminiPlugin is the main plugin struct
type GeminiPlugin struct {
	GeminiPath string
}

// NewGeminiPlugin creates a new instance of the Gemini plugin
func NewGeminiPlugin() *GeminiPlugin {
	// Default path to the Gemini CLI
	geminiPath := "/Users/MacInTosh/gemini-cli/gemini"
	
	// Check if the path exists, if not, try to find it
	if _, err := os.Stat(geminiPath); os.IsNotExist(err) {
		// Try to find it in the user's home directory
		home, err := os.UserHomeDir()
		if err == nil {
			possiblePath := filepath.Join(home, "gemini-cli", "gemini")
			if _, err := os.Stat(possiblePath); err == nil {
				geminiPath = possiblePath
			}
		}
	}
	
	return &GeminiPlugin{
		GeminiPath: geminiPath,
	}
}

// GetCommands returns the CLI commands for this plugin
func (p *GeminiPlugin) GetCommands() []*cli.Command {
	return []*cli.Command{
		{
			Name:    "gemini",
			Aliases: []string{"gem"},
			Usage:   "Interact with Google's Gemini 2.5 Pro model",
			Subcommands: []*cli.Command{
				{
					Name:  "chat",
					Usage: "Start an interactive chat with Gemini",
					Action: func(c *cli.Context) error {
						return p.runGemini("--chat")
					},
				},
				{
					Name:  "ask",
					Usage: "Ask Gemini a single question",
					Action: func(c *cli.Context) error {
						if c.NArg() == 0 {
							return fmt.Errorf("please provide a question")
						}
						prompt := strings.Join(c.Args().Slice(), " ")
						return p.runGemini("--prompt", prompt)
					},
				},
				{
					Name:  "creative",
					Usage: "Ask Gemini a question with higher creativity",
					Action: func(c *cli.Context) error {
						if c.NArg() == 0 {
							return fmt.Errorf("please provide a question")
						}
						prompt := strings.Join(c.Args().Slice(), " ")
						return p.runGemini("--prompt", prompt, "--temperature", "0.9")
					},
				},
				{
					Name:  "save",
					Usage: "Save the conversation history to a file",
					Action: func(c *cli.Context) error {
						if c.NArg() == 0 {
							return fmt.Errorf("please provide a filename")
						}
						filename := c.Args().First()
						return p.runGemini("--chat", "--save-history", filename)
					},
				},
				{
					Name:  "load",
					Usage: "Load a conversation history from a file",
					Action: func(c *cli.Context) error {
						if c.NArg() == 0 {
							return fmt.Errorf("please provide a filename")
						}
						filename := c.Args().First()
						return p.runGemini("--chat", "--load-history", filename)
					},
				},
				{
					Name:  "setup",
					Usage: "Set up the Gemini CLI",
					Action: func(c *cli.Context) error {
						fmt.Println("Setting up Gemini CLI...")
						
						// Check if Gemini CLI exists
						if _, err := os.Stat(p.GeminiPath); os.IsNotExist(err) {
							fmt.Println("Gemini CLI not found. Installing...")
							
							// Clone the repository if it doesn't exist
							geminiDir := filepath.Dir(p.GeminiPath)
							if _, err := os.Stat(geminiDir); os.IsNotExist(err) {
								fmt.Println("Creating directory:", geminiDir)
								if err := os.MkdirAll(geminiDir, 0755); err != nil {
									return fmt.Errorf("failed to create directory: %v", err)
								}
								
								// Copy files from the existing installation
								srcDir := "/Users/MacInTosh/gemini-cli"
								if _, err := os.Stat(srcDir); os.IsNotExist(err) {
									return fmt.Errorf("source directory not found: %s", srcDir)
								}
								
								fmt.Printf("Copying files from %s to %s\n", srcDir, geminiDir)
								cmd := exec.Command("cp", "-r", srcDir+"/.", geminiDir)
								if err := cmd.Run(); err != nil {
									return fmt.Errorf("failed to copy files: %v", err)
								}
							}
							
							// Run the installation script
							installScript := filepath.Join(geminiDir, "install.sh")
							if _, err := os.Stat(installScript); os.IsNotExist(err) {
								return fmt.Errorf("installation script not found: %s", installScript)
							}
							
							fmt.Println("Running installation script...")
							cmd := exec.Command("bash", installScript)
							cmd.Stdout = os.Stdout
							cmd.Stderr = os.Stderr
							if err := cmd.Run(); err != nil {
								return fmt.Errorf("installation failed: %v", err)
							}
						}
						
						// Prompt for API key
						fmt.Println("\nTo use Gemini, you need to set up your API key.")
						fmt.Println("You can get an API key from https://ai.google.dev/")
						fmt.Println("\nOnce you have your API key, set it with:")
						fmt.Println("export GEMINI_API_KEY='your-api-key-here'")
						
						return nil
					},
				},
			},
			Before: func(c *cli.Context) error {
				// Check if Gemini CLI exists
				if _, err := os.Stat(p.GeminiPath); os.IsNotExist(err) {
					return fmt.Errorf("Gemini CLI not found. Run 'nexus gemini setup' first")
				}
				return nil
			},
		},
	}
}

// runGemini runs the Gemini CLI with the given arguments
func (p *GeminiPlugin) runGemini(args ...string) error {
	cmd := exec.Command(p.GeminiPath, args...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
}

// Plugin is the exported plugin instance
var Plugin = NewGeminiPlugin()
