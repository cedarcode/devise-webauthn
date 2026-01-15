# Changelog

## Unreleased

- BREAKING!: WebAuthn JavaScript is now bundled as engine assets using custom HTML elements (`<webauthn-create>`, `<webauthn-get>`) instead of generating a Stimulus controller into the host application.
  - [Form helpers](https://github.com/cedarcode/devise-webauthn/blob/355a6836315439f71265bb368bff4e8067033072/lib/devise/webauthn/helpers/credentials_helper.rb#L7-L58) use the bundle js asset now instead of the Stimulus controllers, so they expect it to be included in your application.
  - Given so, you don't need Stimulus anymore for this engine to work so you can safely remove the previously generated Stimulus controllers form your app.

## [v0.2.2](https://github.com/cedarcode/devise-webauthn/compare/v0.2.1...v0.2.2/) - 2025-12-11

- Generate webauthn credentials table with not null constraints in attributes that must be present.
- Update controllers and views generators to generate 2FA-related controllers and views.
- Add flash messages when removing credentials.

## [v0.2.1](https://github.com/cedarcode/devise-webauthn/compare/v0.2.0...v0.2.1/) - 2025-12-10

- Add form helpers for security key registration and 2FA authentication.
- Fix incorrect call to `resource_name` instead of using passed `resource` param in `login_with_security_key_button` helper.
- Fix `NoMethodError` when calling `second_factor_enabled?` on resources without 2FA.
- Avoid assuming `email` as the authentication key of the resource in form helpers.

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
