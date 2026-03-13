# AGENTS.md - Development Guide for openlink

## Build & Run Commands

### Go Server
```bash
# Run server (default: port 39527, current dir)
go run cmd/server/main.go

# Run with custom options
go run cmd/server/main.go -dir=/path/to/workspace -port=39527 -timeout=60

# Build binary
go build -o openlink cmd/server/main.go

# Run binary
./openlink -dir=/your/workspace -port=39527
```

### Chrome Extension
```bash
cd extension
npm install
npm run build    # outputs to extension/dist/
npm run dev      # watch mode
```

### Testing
```bash
# Run all tests
go test ./...

# Run single package tests
go test ./internal/tool/...

# Run single test function
go test -run TestExecCmdValidate ./internal/tool/

# Run tests with verbose output
go test -v ./internal/security/...

# Run tests with coverage
go test -cover ./...

# Run specific test file
go test -run TestExecCmdValidate -v ./internal/tool/exec_cmd_test.go
```

### Verification
```bash
# Check server health
curl http://127.0.0.1:39527/health

# List tools
curl http://127.0.0.1:39527/tools -H "Authorization: Bearer <token>"
```

## Code Style Guidelines

### Imports
- Standard library imports first, blank line, then external packages
- Group imports in parentheses, alphabetically sorted within each group
- Use relative imports within the module: `github.com/afumu/openlink/internal/...`

```go
import (
    "errors"
    "fmt"
    "os"

    "github.com/gin-gonic/gin"
)
```

### Formatting
- Run `gofmt -w .` before committing
- Line length: no hard limit, but prefer <120 chars for readability
- Use tabs for indentation (Go standard)

### Naming Conventions
- **Types**: PascalCase (e.g., `ToolRequest`, `Config`)
- **Functions**: PascalCase for exported, camelCase for private (e.g., `SafePath`, `normalizeLineEndings`)
- **Variables**: camelCase, descriptive names (e.g., `absTarget`, `replaceAll`)
- **Constants**: camelCase or PascalCase based on visibility
- **Files**: snake_case matching package name (e.g., `exec_cmd.go`, `read_file.go`)

### Types & Interfaces
- Use pointer receivers for methods that mutate state
- Define interfaces where behavior needs abstraction (see `Tool` interface in `tool.go`)
- Use `map[string]interface{}` for dynamic JSON args
- Struct tags: use `json:"name"` with standard naming

### Error Handling
- Return errors as the last return value
- Check errors immediately after the call
- Use `errors.New()` for simple errors, `fmt.Errorf()` for formatted errors
- Include context in error messages when helpful
- For HTTP handlers, return appropriate status codes and JSON error responses

```go
if err != nil {
    result.Status = "error"
    result.Error = err.Error()
    return result
}
```

### Comments & Documentation
- Package comments: `// Package X provides...` at top of file
- Exported functions/types: single-line doc comment starting with the name
- Internal comments in English (code) or Chinese (internal notes) acceptable
- Use `// ── Section ──` style for visual section separators in complex files

### Testing
- Test files: `<name>_test.go` in same package
- Test function naming: `Test<Function><Scenario>` (e.g., `TestExecCmdValidate`)
- Use `t.TempDir()` for temporary test directories
- Use `t.Run()` for sub-tests
- Test both success and failure cases

```go
func TestExecCmdValidate(t *testing.T) {
    cfg := &types.Config{RootDir: t.TempDir(), Timeout: 10}
    tool := NewExecCmdTool(cfg)

    if err := tool.Validate(map[string]interface{}{"command": "ls"}); err != nil {
        t.Errorf("expected valid: %v", err)
    }
}
```

### Security Patterns
- Always validate file paths with `security.SafePath()` or `resolveAbsPath()`
- Use `filepath.EvalSymlinks()` before path validation
- Check dangerous commands with `security.IsDangerousCommand()`
- Use constant-time comparison for token validation

### Git & Commits
- Keep commits focused on single concerns
- Write clear commit messages explaining "why" not just "what"
- No commits unless explicitly requested by user

## Architecture Notes
- Server uses Gin framework for HTTP routing
- All routes protected by token auth middleware
- CORS enabled for all origins (required for browser extension)
- Tool execution uses context with timeout
- Skills system loads `SKILL.md` files from multiple directories
