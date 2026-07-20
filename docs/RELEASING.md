# Releasing Everything Passport

This document outlines the process for cutting a new release of the Everything Passport project.

## Versioning Policy

We use [Semantic Versioning](https://semver.org/spec/v2.0.0.html) for all releases.
Tags and releases MUST follow the `vMAJOR.MINOR.PATCH` format (e.g., `v1.0.0`).

## Release Process

### 1. Pre-release Checks

Before starting the release, ensure the codebase is stable:
- [ ] All unit tests pass: `flutter test` (in `mobile/`).
- [ ] Integration tests pass on a real device/emulator.
- [ ] Linting is clean: `flutter analyze`.
- [ ] The `[Unreleased]` section in `CHANGELOG.md` is up-to-date.

### 2. Prepare the Release

1.  **Update CHANGELOG.md**:
    - Rename the `[Unreleased]` section to the new version and add the current date (e.g., `## [1.0.0] - 2026-07-20`).
    - Add a new empty `[Unreleased]` section at the top.
    - Update the comparison links at the bottom of the file (e.g., `[Unreleased]: .../compare/v1.0.0...HEAD` and `[1.0.0]: .../compare/v0.9.0...v1.0.0`).
2.  **Update Version Numbers**:
    - Mobile: Update `version` in `mobile/pubspec.yaml`.
3.  **Commit Changes**:
    ```bash
    git add .
    git commit -m "chore: release v1.0.0"
    ```

### 3. Tag and Release

1.  **Create a Git Tag**:
    ```bash
    git tag -a v1.0.0 -m "Release v1.0.0"
    git push origin v1.0.0
    ```

2.  **Create GitHub Release**:
    - Go to the [Releases page](https://github.com/bsand49/everything-passport/releases) on GitHub.
    - Click **Draft a new release**.
    - Choose the tag `v1.0.0` you just pushed.
    - Set the **Release title** to `v1.0.0`.
    - Copy the relevant entries from `CHANGELOG.md` into the **Describe this release** section.
    - Click **Publish release**.

### 4. Post-release

- Ensure any CI/CD pipelines triggered by the tag complete successfully.
- Verify the release notes on GitHub/GitLab.

### 5. Rollback Procedure

If a critical issue is discovered immediately after tagging:
1.  **Delete Tag Locally**: `git tag -d v1.0.0`
2.  **Delete Tag Remotely**: `git push --delete origin v1.0.0`
3.  **Revert/Fix**: Address the issue on a new branch, merge to `main`, and restart the release process.

### 6. Post-Release Smoke Tests

Perform these checks on the production environment:
- [ ] New user sign-up (Email/Google).
- [ ] Existing user login.
- [ ] CRUD operations for travel tracking (add/edit/delete).
- [ ] Image upload/cropping functionality.
