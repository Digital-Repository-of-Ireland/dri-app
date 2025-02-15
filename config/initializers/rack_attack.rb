# We need a cache for throttling! Uses Rails.cache by default,
# which we set in config/application.rb. In development/test,
# may be in-memory cache, may have to toggle dev caching
# with `./bin/rails dev:cache`
if Rails.env.production?
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: Settings.cf_turnstile.redis)

  if ENV["RACK_ATTACK_SAFELIST"].present?
    ENV["RACK_ATTACK_SAFELIST"].split(',').each do |safe_ip|
      Rack::Attack.safelist_ip(safe_ip)
    end
  end
else
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new 
end

class Rack::Attack
  class Request < ::Rack::Request
    def remote_ip
      @remote_ip ||= ActionDispatch::Request.new(env).remote_ip
    end
  end
end

# Explained at https://sciencehistory.atlassian.net/wiki/spaces/HDC/pages/2645098498/Cloudflare+Turnstile+bot+detection
Rails.application.config.to_prepare do
  # allow rate_limit_count requests in rate_limit_period, before issuing challenge
  BotDetectController.rate_limit_period = 12.hour
  BotDetectController.rate_limit_count = 5

  # How long a challenge pass is good for
  BotDetectController.session_passed_good_for = 24.hours

  BotDetectController.enabled                 = Settings.cf_turnstile.enabled
  BotDetectController.cf_turnstile_sitekey    = ENV["CF_TURNSTILE_SITEKEY"]
  BotDetectController.cf_turnstile_secret_key = ENV["CF_TURNSTILE_SECRET_KEY"]

  # any custom collection controllers or other controllers that offer search have to be listed here
  # to rate-limit them!
  BotDetectController.rate_limited_locations = [
    '/catalog',
  ]

  # But except any Catalog #facet action that looks like an ajax/fetch request, the redirect
  # ain't gonna work there, we just exempt it.
  #
  # sec-fetch-dest is set to 'empty' by browser on fetch requests, to limit us further;
  # sure an attacker could fake it, we don't mind if someone determined can avoid rate-limiting on this one action
  BotDetectController.allow_exempt = ->(controller) {
    controller.params[:action] == "facet" && controller.request.headers["sec-fetch-dest"] == "empty" && controller.kind_of?(CatalogController)
  }

  BotDetectController.rack_attack_init
end
