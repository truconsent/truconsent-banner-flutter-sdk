# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2025-02-03

### Fixed
- Removed unused fields and imports to fix linter warnings
- Replaced deprecated `withOpacity()` with `withValues(alpha:)` for Color
- Replaced deprecated `activeColor` with `activeThumbColor` for Switch
- Added comprehensive dartdoc comments to public API (20%+ coverage)

### Changed
- Improved code quality and static analysis scores

## [0.1.0] - 2025-02-03

### Added
- Initial release of TruConsent Flutter SDK
- Native Flutter widgets for consent banner display
- TruConsentModal widget for modal-based consent collection
- NativeRightCenter widget for Rights Center functionality
- Support for multiple languages (English, Hindi, Tamil)
- Consent management and tracking
- Integration with TruConsent API
- Support for GDPR and privacy compliance features

### Features
- Consent banner UI with customizable styling
- Purpose-based consent selection
- Cookie consent management
- Rights Center with tabs (Consent, Rights, Transparency, DPO, Nominee, Grievance)
- API integration for consent submission and retrieval
- Internationalization (i18n) support

