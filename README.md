# Devise::Webauthn
[![Gem Version](https://badge.fury.io/rb/devise-webauthn.svg)](https://badge.fury.io/rb/devise-webauthn)

Devise::Webauthn is a [Devise](https://github.com/heartcombo/devise) extension that adds [WebAuthn](https://www.w3.org/TR/2025/WD-webauthn-3-20250127/) support to your Rails application, allowing users to authenticate with [passkeys](https://www.w3.org/TR/2025/WD-webauthn-3-20250127/#passkey).

## Requirements

- **Ruby**: 2.7+
- **Stimulus Rails**: This gem requires [stimulus-rails](https://github.com/hotwired/stimulus-rails) to be installed and configured in your application.
> **Note:** Stimulus Rails is needed for the generated code to work out of the box.  
> If you prefer not to have this dependency, you’ll need to manually implement the JavaScript logic for WebAuthn interactions.

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
   Run the generator to set up necessary configurations, migrations, and Stimulus controller:
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
    - Install the Stimulus controller

2. **Run Migrations:**
   After running the generator, execute the migrations to update your database schema:
   ```bash
   $ bin/rails db:migrate
   ```

3. **Update Your Devise Model:**
   Add `:passkey_authenticatable` to your Devise model (e.g., `User`):
   ```ruby
   class User < ApplicationRecord
     devise :database_authenticatable, :registerable,
            :recoverable, :rememberable, :validatable, :passkey_authenticatable
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

## How It Works

### Adding Passkeys
Signed-in users can add passkeys by visiting `/users/passkeys/new`.

### Sign In with Passkeys
When a user visits `/users/sign_in` they can choose to authenticate using a passkey. The authentication flow is handled by `PasskeysAuthenticatable` strategy.

The WebAuthn passkey sign-in flow works as follows:
1. User clicks "Sign in with Passkey", starting a WebAuthn authentication ceremony.
2. Browser shows available passkeys.
3. User selects a passkey and verifies with their [authenticator](https://www.w3.org/TR/webauthn-3/#webauthn-authenticator).
4. The server verifies the response and signs in the user.

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
Devise::Webauthn provides helpers that can be used in your views. For example, for a resource named `user`, you can use the following helpers:

To add a button for logging in with passkeys:
```erb
<%= login_with_passkey_button("Log in with passkeys", session_path: user_session_path) %>
```

To add a passkeys creation form:
```erb
<%= create_passkey_form(resource: current_user) do |form| %>
  <%= form.label :name, 'Passkey name' %>
  <%= form.text_field :name, required: true %>
  <%= form.submit 'Create Passkey' %>
<% end %>
```

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


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests.
To run the linter, use `bundle exec rubocop`.

Before submitting a pull request, ensure that tests and linter pass.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cedarcode/devise-webauthn.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
