RailsCloudflareTurnstile.configure do |c|
  c.site_key = ENV["CF_TURNSTILE_SITEKEY"] || "1x00000000000000000000AA"
  c.secret_key = ENV["CF_TURNSTILE_SECRET_KEY"] || "1x0000000000000000000000000000000AA"
  c.fail_open = true
end
