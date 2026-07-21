# Everything Passport

A cross-platform travel companion app designed to help users gamify and track their life experiences, travels, and hobbies.

## Project Structure

This repository is a monorepo containing the following components:

- **[mobile/](mobile/README.md)**: The Flutter-based mobile application (Android & iOS).
- **backend/**: The server-side logic and API (if applicable).
- **web/**: The web-based interface for the application.
- **docs/**: Project documentation and architecture diagrams.
- **[CHANGELOG.md](CHANGELOG.md)**: Tracking of released and unreleased changes.
- **[RELEASING.md](docs/RELEASING.md)**: Instructions and process for cutting new releases.

## Quick Start

To get started with the mobile application, please refer to the detailed **[Mobile Setup Guide](mobile/README.md)**.

## Key Features

- **Gamified Travel Tracking**: Earn badges and points for visiting new locations.
- **Life Experience Passport**: A digital log of your trave, events, hobbies and milestones.
- **Cross-Platform**: Seamlessly sync your data across Android, iOS, and Web.

## Contributing

We welcome contributions! To maintain a clean and traceable history, please follow our branch naming convention:

### Branch Naming Convention

Use the format: `<prefix>/(<issue-id>-)<short-description>`

The `issue-id` is optional but should be provided where possible to help track changes back to requirements.

| Prefix | Usage |
| :--- | :--- |
| `feat/` | New features |
| `fix/` | Bug fixes |
| `refactor/` | Code improvements |
| `docs/` | Documentation updates |
| `ci/` | CI/CD changes |
| `test/` | Adding/modifying tests |
| `chore/` | Maintenance & boilerplate |

**Example**: `feat/42-google-sign-in`

### Pull Request Process

1. **Create a Branch**: Create a new branch from `main` using the [Branch Naming Convention](#branch-naming-convention).
2. **Implement Changes**: Add your code changes, ensuring you follow the project's style guidelines.
3. **Add Tests**: Include unit or integration tests for any new functionality or bug fixes.
4. **Verify Locally**: Run all tests and lint checks locally (e.g., `flutter test` and `flutter analyze` for the mobile app).
5. **Commit & Push**: Commit your changes with clear, descriptive messages and push your branch to GitHub.
6. **Open a PR**: Open a Pull Request against the `main` branch. The [Pull Request Template](.github/pull_request_template.md) will be automatically applied; please fill it out completely.
7. **Code Review**: Address any feedback from reviewers and ensure all CI/CD checks (branch name, tests, coverage) pass.

## Git Hooks

This project uses [Lefthook](https://github.com/evilmartians/lefthook) to automate code quality checks.

### Pre-commit Hooks

Before every commit, the following checks are run automatically on your staged files:
- **`dart format`**: Ensures your code follows the project's formatting standards.
- **`flutter analyze`**: Checks for static analysis warnings or errors.

### Pre-push Hooks

Before every push, the following checks are run:
- **`flutter test --coverage`**: Runs all unit tests and ensures that code coverage is **90%** or higher.

To enable git hooks locally, run the following command from the project root (requires Node.js):
```bash
npm install
```

### Local Environment Configuration (GUI Clients)

If you use a GUI Git client (like **Fork**, **Tower**, or **Sourcetree**) and encounter a `command not found: flutter` error, you need to tell Lefthook where to find your shell environment.

Create a `lefthook-local.yml` file in the project root (this file is ignored by Git).

#### macOS / Linux
Add the following to `lefthook-local.yml`, replacing the path with your **absolute** shell profile path:
```yaml
rc: /Users/yourname/.zprofile
```

If sourcing the profile doesn't work, you can explicitly add the Flutter path and system paths to the environment:
```yaml
pre-commit:
  commands:
    analyze:
      env:
        PATH: "/path/to/flutter/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:#{ENV['PATH']}"
    format:
      env:
        PATH: "/path/to/flutter/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:#{ENV['PATH']}"

pre-push:
  commands:
    mobile-tests:
      env:
        PATH: "/path/to/flutter/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:#{ENV['PATH']}"
```

#### Windows
If you are using Git Bash or WSL, you can use the `rc` approach above. For native Windows environments, you might need to specify the path to your shell or the binary directly in the `PATH` environment variable:
```yaml
pre-commit:
  commands:
    analyze:
      env:
        PATH: "%PATH%;C:\\path\\to\\flutter\\bin"
```

> [!TIP]
> Sourcing your shell profile is the most robust way to ensure all environment variables (including those set by version managers like `asdf` or `fvm`) are available to your Git hooks.

## Code Ownership

This project uses a [CODEOWNERS](.github/CODEOWNERS) file to define responsibility for the codebase. Currently, @bsand49 is the primary owner for all files in this repository.

---
© 2026 Everything Passport Team
