# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Buildkite plugin that extends the step-templates plugin functionality to centralize deployment configuration and automate deploy target management. The plugin allows deployment steps to be injected into pipelines based on templates, with deployment targets either manually selected or automatically discovered from centralized S3-based configuration.

## Development Commands

### Testing
```bash
pnpm test
```
Runs the BATS testing framework to test all plugin functionality. Tests are located in the `tests/` directory with 28 test cases across 5 test files.

To run a specific test file:
```bash
docker-compose run --rm tests bats tests/command.bats
```

### Linting
```bash
pnpm lint
```
Runs the Buildkite plugin linter via Docker to validate plugin configuration and code style.

### Docker Development
Both test and lint commands use Docker Compose. The services are defined in `docker-compose.yaml`:
- `lint`: Uses `buildkite/plugin-linter` image with plugin ID `cultureamp/deploy-templates`
- `tests`: Builds from local Dockerfile (based on `buildkite/plugin-tester` with added `grep`) and runs BATS tests

## Architecture

### Core Components

**Plugin Entry Point (`hooks/command`)**
- Main plugin execution script that validates configuration and orchestrates deployment step generation
- Handles three modes: manual selection via `selector-template`, automatic production deployment via `auto-deploy-to-production`, and predefined `auto-selections`

**Library Modules (`lib/`)**
- `shared.bash`: Common plugin configuration reading utilities
- `steps.bash`: Step template rendering and environment variable management
- `targets.bash`: S3-based deploy target configuration fetching and parsing

**Configuration (`plugin.yml`)**
- Defines plugin schema with properties: `step-template`, `step-var-names`, `auto-selections`, `selector-template`, `auto-deploy-to-production`
- Enforces mutual exclusivity between `auto-selections` and `auto-deploy-to-production`

### Key Behaviors

**Centralized Configuration**
- Uses `BUILDKITE_DEPLOY_CONFIG_S3_PATH` environment variable to fetch deploy configurations from S3
- Expected S3 structure: `environments/` (env files) and `types/` (service-specific deploy targets)
- Service name derived from `BUILDKITE_PIPELINE_SLUG`

**Environment Variable Loading**
- Loads `.env` files from both S3 and local repository
- Local `.env` files take precedence over S3 files
- For `auto-deploy-to-production`, `FARM=production` is automatically set but can be overridden per target

**Step Generation Order**
- Templates are uploaded in reverse order to appear immediately after the current step
- Selector template (manual selection) appears last if configured
- Production auto-deploy steps are generated based on discovered targets
- Auto-selections are processed with `AUTO_SELECTION_DEFAULT_BRANCH` environment variable

## Testing Strategy

The codebase uses BATS (Bash Automated Testing System) for comprehensive testing:
- `command.bats`: Tests main plugin logic and configuration validation
- `steps_*.bats`: Tests step generation, AWS integration, and utility functions
- `targets.bats`: Tests deploy target discovery and parsing
- Test fixtures in `tests/fixtures/` provide mock environments and configurations

## Plugin Configuration Examples

Basic usage with manual selection:
```yaml
- cultureamp/deploy-templates#v1.0.5:
    step-template: deploy-steps.yml
    selector-template: deploy-selector.yml
```

Automatic production deployment:
```yaml
- cultureamp/deploy-templates#v1.0.5:
    step-template: .buildkite/deploy/deploy-steps.yaml
    auto-deploy-to-production: true
```

## Release Management

Uses semantic-release with Angular commit message conventions. Manual releases can be triggered via GitHub repository dispatch events.

## Important Instructions

- Always follow existing code patterns and conventions when making changes to Bash scripts
- Test changes thoroughly using the BATS framework before committing
- Follow semantic-release conventions for commit messages (Angular format)

## MCP Rules

- When using Context7 maintain a file named library.md to store a Library IDs that you search for and before searching make sure that you check the file and use the library ID already available. Otherwise search for it.
