# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

### Standard Change Categories
When adding to this file, please use the following headers to group changes:
- `Added`: For new features.
- `Changed`: For changes in existing functionality.
- `Deprecated`: For soon-to-be removed features.
- `Removed`: For now removed features.
- `Fixed`: For any bug fixes.
- `Security`: In case of vulnerabilities.

## [Unreleased]

### Added
- **Initial Project Infrastructure**: Established monorepo structure with `mobile`, `backend`, `web`, and `docs` directories.
- **Flutter Mobile Application**:
    - Core app structure and navigation.
    - **Firebase Integration**: Authentication, Cloud Firestore, and Firebase Storage.
    - **Authentication**: Email/Password and Google Sign-In providers.
    - **Image Handling**: Integration with `image_picker` and `image_cropper`.
    - **UI/UX**: Material Design 3 components, `cached_network_image` for remote assets.
- **Testing Infrastructure**:
    - Unit testing framework using `flutter_test` and `mockito`.
    - Integration testing suite for end-to-end verification.
    - Automated mock generation with `build_runner`.
- **Repository Management**:
    - `CODEOWNERS` file for automated review assignments.
    - `dependabot.yml` for automated dependency updates.
    - `dependabot-auto-merge.yml` for auto merging PRs raised by dependabot, when safe to do so.
    - Pull Request template and branch naming conventions.
    - Comprehensive `README.md` and documentation structure.
- **Documentation**:
    - Added `CHANGELOG.md` (this file) to track changes.
    - Added `RELEASING.md` to document the release process.

[Unreleased]: https://github.com/bsand49/everything-passport/compare/v0.0.0...HEAD
