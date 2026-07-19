# Everything Passport

A cross-platform travel companion app designed to help users gamify and track their life experiences, travels, and hobbies.

## Project Structure

This repository is a monorepo containing the following components:

- **[mobile/](mobile/README.md)**: The Flutter-based mobile application (Android & iOS).
- **backend/**: The server-side logic and API (if applicable).
- **web/**: The web-based interface for the application.
- **docs/**: Project documentation and architecture diagrams.

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

---
© 2026 Everything Passport Team
