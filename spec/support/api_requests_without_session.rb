# frozen_string_literal: true

# The API side of an app that also signs in browsers with a cookie session on the same scope: API requests read
# and get no cookies, and skip session storage with Devise's per-request switch.
class ApiRequestsWithoutSession
  def initialize(app)
    @app = app
  end

  def call(env)
    env.delete("HTTP_COOKIE")
    env["devise.skip_storage"] = true
    status, headers, body = @app.call(env)
    headers.delete("set-cookie")
    [status, headers, body]
  end
end
