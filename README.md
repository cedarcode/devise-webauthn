# Devise::Webauthn
[![Gem Version](https://badge.fury.io/rb/devise-webauthn.svg)](https://badge.fury.io/rb/devise-webauthn)

Devise::Webauthn is a [Devise](https://github.com/heartcombo/devise) extension that adds [WebAuthn](https://www.w3.org/TR/2025/WD-webauthn-3-20250127/) support to your Rails application, allowing users to authenticate with [passkeys](https://www.w3.org/TR/2025/WD-webauthn-3-20250127/#passkey) and use [security keys](https://www.w3.org/TR/webauthn-3/#server-side-credential) for two factor authentication.

## Requirements

- **Ruby**: 2.7+
- **JavaScript**: This gem includes WebAuthn JavaScript as custom HTML elements. You'll need to import the JavaScript file in your application.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'devise-webauthn'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install devise-webauthn

## Usage

First, ensure you have Devise set up in your Rails application. For a full guide on setting up Devise, refer to the [Devise documentation](https://github.com/heartcombo/devise?tab=readme-ov-file#getting-started).
Then, follow these steps to integrate Devise::Webauthn:
1. **Run Devise::Webauthn Generator:**
   Run the generator to set up necessary configurations and migrations:
   ```bash
   $ bin/rails generate devise:webauthn:install
   ```

   You can optionally specify a different resource name (defaults to "user"):
   ```bash
   $ bin/rails generate devise:webauthn:install --resource-name=RESOURCE_NAME
   ```

   The generator will:
    - Create the WebAuthn initializer (`config/initializers/webauthn.rb`)
    - Generate the `WebauthnCredential` model and migration
    - Add `webauthn_id` field to your devise model (e.g., `User`)
    - Configure JavaScript loading for your application (see [JavaScript Setup](#javascript-setup))

2. **Run Migrations:**
   After running the generator, execute the migrations to update your database schema:
   ```bash
   $ bin/rails db:migrate
   ```

3. **Update Your Devise Model:**
   Add `:passkey_authenticatable` to your Devise model (e.g., `User`) for passkeys authentication and `:webauthn_two_factor_authenticatable` for WebAuthn-based 2FA if desired. For example:
   ```ruby
   class User < ApplicationRecord
     devise :database_authenticatable, :registerable,
            :recoverable, :rememberable, :validatable,
            :passkey_authenticatable, :webauthn_two_factor_authenticatable
   end
   ```

4. **Configure WebAuthn Settings:**
   Update the generated initializer file `config/initializers/webauthn.rb` with your application's specific settings, such as `rp_name`, and `allowed_origins`. For example:
   ```ruby
    WebAuthn.configure do |config|
      # This value needs to match `window.location.origin` evaluated by
      # the User Agent during registration and authentication ceremonies.
      config.allowed_origins = ["https://yourapp.com"]

      # Relying Party name for display purposes
      config.rp_name = "Your App Name"
    end
    ```
> [!TIP]
> You can find a working example on how to use this gem for passwordless and two factor authentication in [`devise-webauthn-rails-demo`](https://github.com/cedarcode/devise-webauthn-demo-app).

5. **Include bundled WebAuthn JavaScript in your application:**
   The install generator automatically configures JavaScript loading based on your setup:

   **For importmap-rails:**
   - Adds `pin "devise/webauthn", to: "devise/webauthn.js"` to `config/importmap.rb`
   - Adds `import "devise/webauthn"` to `app/javascript/application.js`

   **For node setups (esbuild, Bun, etc.):**
   - Adds `<%= javascript_include_tag "devise/webauthn" %>` to your application layout

   If the automatic setup doesn't work for your configuration, you can manually include the JavaScript:
   ```erb
   <%= javascript_include_tag "devise/webauthn" %>
   ```

#### Behavior

When the form is submitted:
1. The default form submission is prevented
2. The browser's WebAuthn prompt is triggered with the provided options
3. Upon successful authentication, the credential response is stored in the hidden input
4. The form is submitted with the credential data

## How It Works

### Passkey authentication

#### Adding Passkeys
Signed-in users can add passkeys by visiting `/users/passkeys/new`.

#### Sign In with Passkeys
When a user visits `/users/sign_in` they can choose to authenticate using a passkey. The authentication flow is handled by `PasskeysAuthenticatable` strategy.

The WebAuthn passkey sign-in flow works as follows:
1. User clicks "Sign in with Passkey", starting a WebAuthn authentication ceremony.
2. Browser shows available passkeys.
3. User selects a passkey and verifies with their [authenticator](https://www.w3.org/TR/webauthn-3/#webauthn-authenticator).
4. The server verifies the response and signs in the user.

### Two-Factor Authentication (2FA) with WebAuthn

#### Adding Security Keys for 2FA
Signed-in users can add security keys by visiting `/users/second_factor_webauthn_credentials/new`.

#### 2FA Sign In with Security Keys
When a user that has 2FA enabled (i.e., has registered passkeys or security keys) visits `/users/sign_in`, after entering their primary credentials (e.g., email and password), they will be prompted to complete the second factor authentication using WebAuthn. The authentication flow is handled by `WebauthnTwoFactorAuthenticatable` strategy.

The two factor authentication flow with WebAuthn works as follows:
1. User enters their primary credentials (e.g., email and password) and submits the form.
2. If the user has 2FA enabled, they are redirected to a second factor authentication page.
3. User clicks "Use security key", starting a WebAuthn authentication ceremony.
4. Browser shows available credentials (which can be both passkeys and security keys).
5. User selects a credential and verifies with their [authenticator](https://www.w3.org/TR/webauthn-3/#webauthn-authenticator).
6. The server verifies the response and signs in the user.

## Customization

### Customizing Views
Similar to [views customization on Devise](https://github.com/heartcombo/devise?tab=readme-ov-file#configuring-views), to customize the views, you can copy the view files from the gem into your application. Run the following command:
```bash
$ bin/rails generate devise:webauthn:views
```

If you want to customize only specific views, you can copy them individually. For example, to copy only the passkeys views:
```bash
$ bin/rails generate devise:webauthn:views -v passkeys
```

### Helper methods
Devise::Webauthn provides helpers that can be used in your views. These helpers accept either a resource name (e.g., `:user`) or a resource object (e.g., `@user`) as the first argument.

For example, for a resource named `user`, you can use the following helpers:

To add a button for logging in with passkeys:
```erb
<%= login_with_passkey_button_for(:user, "Log in with passkeys", session_path: user_session_path) %>
```

To add a passkeys creation form:
```erb
<%= passkey_creation_form_for(:user) do |form| %>
  <%= form.label :name, 'Passkey name' %>
  <%= form.text_field :name, required: true %>
  <%= form.submit 'Create Passkey' %>
<% end %>
```

### Handling unsupported WebAuthn

The custom elements check for WebAuthn API support when they connect to the DOM. If the browser doesn't support WebAuthn, a `webauthn:unsupported` event is dispatched and the form submission handler is not attached.

```javascript
document.addEventListener('webauthn:unsupported', (event) => {
  const { action } = event.detail; // 'create' or 'get'

  // Hide the WebAuthn form and show a message
  hideWebauthnFormWithMessage('Your browser does not support WebAuthn');
});
```

### Customizing Javascript Error Handling

By default, WebAuthn errors during registration or authentication are displayed using the browser's `alert()` dialog. You can customize this behavior by listening to the `webauthn:prompt:error` event.

#### Listening for WebAuthn Errors

The custom elements dispatch a `webauthn:prompt:error` event whenever an error occurs during the WebAuthn prompt interaction (registration or authentication). You can listen for this event and provide custom error handling:

```javascript
document.addEventListener('webauthn:prompt:error', (event) => {
  event.preventDefault(); // Prevent the default alert

  const { error, action } = event.detail;

  // Your custom error handling
  console.error(`WebAuthn ${action} failed:`, error);
  showFlashMessage(error.message, 'error');
});
```

#### Event Details

The event includes the following information in `event.detail`:
- `error`: The error object thrown during the WebAuthn operation
- `action`: Either `"create"` (for registration) or `"get"` (for authentication)

#### Handling Specific Error Types

WebAuthn operations can fail for various reasons. Here are some common error types you might want to handle:

```javascript
document.addEventListener('webauthn:prompt:error', (event) => {
  event.preventDefault();

  const { error, action } = event.detail;

  switch (error.name) {
    case 'NotAllowedError':
      // User cancelled the operation or timeout
      showFlashMessage('Operation cancelled or timed out', 'warning');
      break;

    default:
      // Generic error message
      showFlashMessage(`Authentication error: ${error.message}`, 'error');
  }
});
```

#### Different Handling for Registration vs Authentication

You can provide different error handling based on whether the error occurred during registration or authentication:

```javascript
document.addEventListener('webauthn:prompt:error', (event) => {
  event.preventDefault();

  const { error, action } = event.detail;

  if (action === 'create') {
    // Handle registration errors
    handleRegistrationError(error);
  } else if (action === 'get') {
    // Handle authentication errors
    handleAuthenticationError(error);
  }
});
```

**Note:** If you don't call `event.preventDefault()`, the default `alert()` will still be shown.

### Customizing Controllers
Similar to [controllers customization on Devise](https://github.com/heartcombo/devise?tab=readme-ov-file#configuring-controllers), you can customize the Devise::Webauthn controllers.

1. Create your custom controllers using the generator which requires a scope:
```bash
$ bin/rails generate devise:webauthn:controllers [scope]
```

2. Tell the router to use your custom controllers. For example, if your scope is `users`:
```ruby
devise_for :users, controllers: {
  passkeys: 'users/passkeys'
}
```

3. Change or extend the generated controllers as needed.

### Manually implementing WebAuthn forms

The gem provides two custom HTML elements for WebAuthn operations. While the [form helpers](#helper-methods) handle this automatically, you can use these elements directly for custom implementations.

#### `<webauthn-create>`

Used for registering new credentials (passkeys or security keys).

```html
<form action="/passkeys" method="post">
  <webauthn-create data-options-json="<%= create_passkey_options(@user).to_json %>">
    <input type="hidden" name="public_key_credential" data-webauthn-target="response">
    <input type="text" name="name" placeholder="Passkey name">
    <button type="submit">Create Passkey</button>
  </webauthn-create>
</form>
```

**Requirements:**
- Must be wrapped in a `<form>` element
  - The form's action should point to the appropriate endpoint – you can use the provided url helpers:
    - For creating passkeys: `passkeys_path(resource_name)`
    - For creating 2FA security keys: `second_factor_webauthn_credentials_path(resource_name)`
- Requires a `data-options-json` attribute containing JSON-serialized WebAuthn creation options
- Must contain a hidden input with `data-webauthn-target="response"` to store the credential response
- Must contain the submit button — the element intercepts form submission, calls the WebAuthn API, stores the credential in the hidden input, and then re-submits the form

#### `<webauthn-get>`

Used for authenticating with existing credentials.

```html
<form action="/users/sign_in" method="post">
  <webauthn-get data-options-json="<%= passkey_authentication_options.to_json %>">
    <input type="hidden" name="public_key_credential" data-webauthn-target="response">
    <button type="submit">Sign in with Passkey</button>
  </webauthn-get>
</form>
```

**Requirements:**
- Must be wrapped in a `<form>` element
    - The form's action should point to the appropriate endpoint – you can use the provided url helpers:
        - For passkey sign-in: `session_path(resource_name)`
        - For 2FA with WebAuthn: `two_factor_authentication_path(resource_name)`
- Requires a `data-options-json` attribute containing JSON-serialized WebAuthn request options
- Must contain a hidden input with `data-webauthn-target="response"` to store the credential response
- Must contain the submit button — the element intercepts form submission, calls the WebAuthn API, stores the credential in the hidden input, and then re-submits the form

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests.
To run the linter, use `bundle exec rubocop`.

Before submitting a pull request, ensure that tests and linter pass.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cedarcode/devise-webauthn.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
