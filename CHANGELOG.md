# Changelog

## Unreleased

### Changed

- Options for getting or creating passkeys and security keys are now served by dedicated Rails controllers and retrieved via JavaScript fetch requests. [#73](https://github.com/cedarcode/devise-webauthn/pull/73) [@nicolastemciuc]
- BREAKING!: Remove helpers for generating WebAuthn options. [#106](https://github.com/cedarcode/devise-webauthn/pull/115) [@nicolastemciuc]

## [v0.3.0](https://github.com/cedarcode/devise-webauthn/compare/v0.2.2...v0.3.0/) - 2026-01-16

### Added

- WebAuthn JavaScript is now bundled as engine assets using custom HTML elements (`<webauthn-create>`, `<webauthn-get>`) instead of generating a Stimulus controller into the host application. [#84](https://github.com/cedarcode/devise-webauthn/pull/84) [@santiagorodriguez96]
- Add endpoint to `SecondFactorWebauthnCredentialsController` for "upgrading" second factor webauthn credentials (i. e., security keys) to passkeys. [#80](https://github.com/cedarcode/devise-webauthn/pull/80) [@nicolastemciuc]

### Changed

- Loosen `devise` upper constraint to allow for v5. [#94](https://github.com/cedarcode/devise-webauthn/pull/94) [@santiagorodriguez96]
- BREAKING!: Our [Form helpers](https://github.com/cedarcode/devise-webauthn/blob/355a6836315439f71265bb368bff4e8067033072/lib/devise/webauthn/helpers/credentials_helper.rb#L7-L58) now use the bundled WebAuthn JS asset now instead of the Stimulus controllers, so they expect it to be included in your application. [#84](https://github.com/cedarcode/devise-webauthn/pull/84) [@santiagorodriguez96]
  - Previously generated Stimulus controller for handling WebAuthn client logic are no longer generated.
  - Stimulus is no longer needed for this engine to work.
- Make helpers for generating WebAuthn options public methods. [#106](https://github.com/cedarcode/devise-webauthn/pull/106) [@santiagorodriguez96]

### Fixed

- Fix `Remember me` checkbox not honored when going through the 2FA challenge flow. [#87](https://github.com/cedarcode/devise-webauthn/pull/87) [@santiagorodriguez96]

## [v0.2.2](https://github.com/cedarcode/devise-webauthn/compare/v0.2.1...v0.2.2/) - 2025-12-11

### Added

- Update controllers and views generators to generate 2FA-related controllers and views. [#75](https://github.com/cedarcode/devise-webauthn/pull/75) [@santiagorodriguez96]
- Add flash messages when removing credentials. [#78](https://github.com/cedarcode/devise-webauthn/pull/78) [@nicolastemciuc]

### Changed

- Generate webauthn credentials table with not null constraints in attributes that must be present. [#70](https://github.com/cedarcode/devise-webauthn/pull/70) [@santiagorodriguez96]

## [v0.2.1](https://github.com/cedarcode/devise-webauthn/compare/v0.2.0...v0.2.1/) - 2025-12-10

### Added

- Add form helpers for security key registration and 2FA authentication. [#52](https://github.com/cedarcode/devise-webauthn/pull/52) [@santiagorodriguez96]

### Fixed

- Fix incorrect call to `resource_name` instead of using passed `resource` param in `login_with_security_key_button` helper. [#65](https://github.com/cedarcode/devise-webauthn/pull/65) [@santiagorodriguez96]
- Fix `NoMethodError` when calling `second_factor_enabled?` on resources without 2FA. [#62](https://github.com/cedarcode/devise-webauthn/pull/62) [@nicolastemciuc]
- Avoid assuming `email` as the authentication key of the resource in form helpers. [#66](https://github.com/cedarcode/devise-webauthn/pull/66) [@santiagorodriguez96]

## [v0.2.0](https://github.com/cedarcode/devise-webauthn/compare/v0.1.2...v0.2.0/) - 2025-12-03

### Added

- Add new `webauthn_two_factor_authenticatable` module for enabling 2FA using WebAuthn credentials. [#49](https://github.com/cedarcode/devise-webauthn/pull/49) [@santiagorodriguez96]

## [v0.1.2](https://github.com/cedarcode/devise-webauthn/compare/v0.1.1...v0.1.2/) - 2025-12-03

### Fixed

- Fixed sign in with passkey for resources with name different from "User". [#47](https://github.com/cedarcode/devise-webauthn/pull/47) [@joaquintomas2003], [@santiagorodriguez96]

## [v0.1.1](https://github.com/cedarcode/devise-webauthn/compare/v0.1.0...v0.1.1/) - 2025-11-13

### Changed

- Updated gemspec metadata. [#43](https://github.com/cedarcode/devise-webauthn/pull/43) [@joaquintomas2003]

## [v0.1.0](https://github.com/cedarcode/devise-webauthn/compare/v0.0.0...v0.1.0/) - 2025-11-12

### Initial release

- Provides passkey authentication for apps using Devise. [@joaquintomas2003], [@nicolastemciuc], [@RenzoMinelli], [@santiagorodriguez96]

[@RenzoMinelli]: https://github.com/RenzoMinelli
[@joaquintomas2003]: https://github.com/joaquintomas2003
[@nicolastemciuc]: https://github.com/nicolastemciuc
[@santiagorodriguez96]: https://github.com/santiagorodriguez96
