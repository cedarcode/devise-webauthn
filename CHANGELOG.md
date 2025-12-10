# Changelog

## Unreleased

- Add form helpers for security key registration and 2FA authentication.
- Fix incorrect call to `resource_name` instead of using passed `resource` param in `login_with_security_key_button` helper.
- Fix `NoMethodError` when calling `second_factor_enabled?` on resources without 2FA.
- Generate webauthn credentials table with not null constraints in attributes that must be present.

## [v0.2.0](https://github.com/cedarcode/devise-webauthn/compare/v0.1.2...v0.2.0/) - 2025-12-03

- Add new `webauthn_two_factor_authenticatable` module for enabling 2FA using WebAuthn credentials.

## [v0.1.2](https://github.com/cedarcode/devise-webauthn/compare/v0.1.1...v0.1.2/) - 2025-12-03

### Fixed

- Fixed sign in with passkey for resources with name different from "User"

## [v0.1.1](https://github.com/cedarcode/devise-webauthn/compare/v0.1.0...v0.1.1/) - 2025-11-13

### Changed

- Updated gemspec metadata.

## [v0.1.0](https://github.com/cedarcode/devise-webauthn/compare/v0.0.0...v0.1.0/) - 2025-11-12

### Initial release

- Provides passkey authentication for apps using Devise.
