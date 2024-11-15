# Auto Commit CLI

An AI-powered Conventional Commits message generator for Git. This tool analyzes your staged changes and generates standardized commit messages using OpenAI's GPT models.

## Features

### 🤖 AI-Powered Commit Messages

- Automatically generates [Conventional Commits](https://www.conventionalcommits.org/) style messages
- Analyzes your staged Git changes using AI
- Interactive confirmation before committing
- Quick commit with `-y` flag to skip confirmation
- Beautiful CLI interface with loading spinners

### ⚙️ Configuration Management

- OpenAI API integration out of the box
- Flexible API configuration (endpoint, key, model)
- Secure API key storage with masked display
- Configuration priority: local > global > defaults
- Easy setup with `--init` flag

### 🔍 Health Checks

Built-in system diagnostics with `doctor` command:

- API key validation (securely masked)
- Endpoint URL verification
- Model name validation
- API connectivity testing

## Usage

### Basic Commands

```bash
# Generate commit message for staged changes
flit commit
flit commit -y  # Skip confirmation

# Configure settings
flit config --set-api-key "your-api-key"
flit config --set-endpoint "https://api.openai.com"
flit config --set-model "gpt-4"
flit config --show    # Display current configuration
flit config --init    # Create new configuration file

# Check system status
flit doctor

# Display version
flit --version
flit version
```

### Configuration

The tool supports both local (project-specific) and global configuration files:

```yaml
# .auto_commit.yaml
apiKey: your-api-key
endpoint: https://api.openai.com # Default OpenAI endpoint
model: gpt-4o # Default model
```

Configuration locations (in priority order):

1. Current directory: `./.auto_commit.yaml`
2. Home directory: `~/.auto_commit.yaml`
3. Default values if no config file found

Initialize a new configuration file:

```bash
flit config --init  # Creates in home directory
```

View current configuration (with masked API key):

```bash
flit config --show
```

## Project Structure

```
lib/
  ├─ auto_commit.dart      # Main CLI entry point
  ├─ commit_command.dart   # Commit message generation
  ├─ config_command.dart   # Configuration management
  ├─ config.dart          # Configuration handling
  ├─ doctor_command.dart   # System health checks
  ├─ generator.dart        # AI interaction logic
  ├─ spinner.dart         # CLI loading animations
  └─ version_command.dart  # Version information (v1.0.0)
```

## Dependencies

- `args`: Command line argument parsing
- `http`: API communication
- `process_run`: Git command execution
- `yaml`: Configuration file parsing
- Other Dart standard libraries

## Technical Details

### Configuration System

- YAML-based configuration files
- Supports both local and global configurations
- Environment-aware path resolution
- Default fallback values
- Secure API key handling

### User Interface

- Interactive command-line interface
- Elegant loading spinners with status updates
- Color-coded output
- Clear success/error indicators
- Progress feedback for long-running operations

### API Integration

- OpenAI API integration by default
- Configurable endpoints for alternative AI services
- JSON schema-based response formatting
- Secure API key handling
- Network connectivity validation
