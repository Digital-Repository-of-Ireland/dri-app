# We need a cache for throttling! Uses Rails.cache by default,
# which we set in config/application.rb. In development/test,
# may be in-memory cache, may have to toggle dev caching
# with `./bin/rails dev:cache`
if Rails.env.production? && (Rack::Attack.cache.nil? || Rack::Attack.cache.store.kind_of?(ActiveSupport::Cache::NullStore))
  # log with `rack_attack` token so our log watcher will catch it.
  Rails.logger.warn("rack_attack: rack-attack is not throttling, as we do not have a real Rails.cache available!")
end

# If any single client IP is making tons of requests, then they're
# probably malicious or a poorly-configured scraper. Either way, they
# don't deserve to hog all of the app server's CPU. Cut them off!
#
# Note: If you're serving assets through rack, those requests may be
# counted by rack-attack and this throttle may be activated too
# quickly. If so, enable the condition to exclude them from tracking.

Rack::Attack.safelist_ip(ENV["RACK_ATTACK_SAFELIST"])
Rack::Attack.safelist_ip(ENV["10.115.0.0/24"])

# Throttle all requests by IP
#
# Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
#
# -------------------------
#
# Rack-attack docs suggested averaging one request per second over
# 5 minutes: limit: 300, period: 5.minutes
#
# But we're going to try a more generous 3 per second over
# 1 minute instead.
#
# May 1 2024: Limiting much more extensively to 30 req per minute -- one per every two seconds
# averaging over a minute -- after bot  attacks costing us money from s3.
Rack::Attack.throttle('req/ip', limit: 80, period: 1.minutes) do |req|
  req.ip unless (
                  req.path.start_with?('/assets')
                 )
end

# But we're also going to TRACK at half that limit, for ease
# of understanding what's going on in our logs
Rack::Attack.track("req/ip_track", limit: 60, period: 1.minute) do |req|
  req.ip unless req.path.start_with?('/assets')
end

# And we want to log rack-attack track and throttle  notifications. But we get
# a notification every time an IP has exceeded the limit -- that's far too
# many to log every time, could be many per second when it's exceeding limits.
#
# We want to log once per period of our limits -- eg one minute, for records.
#
# But we want to ALERT us even less than that -- say once per day -- so we
# log a special log line with 'ALERT' in it even less frequently, that we
# can have papertrail set an alert for us on, on the string: `rack_attack: ALERT`.
# We also do reverse IP lookup on the less frequent ALERTS.
#
# To do this, we need to store and consult some state about the last time(s)
# we logged, which we do in the cache that rack-attackc is already using
# (probably the Rails.cache which is probably a memcached)
#
# The implementation of all of this is currently kind of squirrely and hard
# to follow, sorry.
alert_only_per = 1.day
ActiveSupport::Notifications.subscribe(/throttle\.rack_attack|track\.rack_attack/) do |name, start, finish, request_id, payload|
  rack_request = payload[:request]
  rack_env     = rack_request.env
  match_data   = rack_env["rack.attack.match_data"]
  match_data_formatted = match_data.slice(:count, :limit, :period).map { |k, v| "#{k}=#{v}"}.join(" ")

  match_name = rack_env["rack.attack.matched"]
  discriminator = rack_env["rack.attack.match_discriminator"] # generally the IP address
  last_logged_key = "rack_attack_notification_#{name}_#{match_name}_#{discriminator}"

  last_logged_info = Rack::Attack.cache.read(last_logged_key)
  # should be a serialized JSON hash
  last_logged_info = if last_logged_info.kind_of?(String)
    JSON.parse(last_logged_info) rescue JSON::ParserError
  else
    {}
  end


  last_logged_count = last_logged_info['count']
  last_alerted_time = last_logged_info['last_alerted_time'] && (Time.iso8601(last_logged_info['last_alerted_time']) rescue nil)
  current_count = match_data[:count]

  # only log if we have a new count, not if we're still incrementing the count!
  if !last_logged_count || current_count <= last_logged_count.to_i
    last_logged_info['count'] = current_count

    # if it's been longer than our alert window, we log a special ALERT
    # that papertrail can be configured to notify us on
    #
    # `name` will be throttle.rack_attack or track.rack_attack
    # `match_name` will be name of rule like 'req/ip'
    # `discriminator` will generally be IP address, or what you are grouping by to limit
    current_time = Time.now
    if !last_alerted_time || (current_time - last_alerted_time) > alert_only_per
      hostname = Resolv.getname(discriminator) rescue nil
      last_logged_info['last_alerted_time'] = current_time.utc.iso8601 # record time so we don't do it again soon
      # eg: track.rack_attack: ALERT: req/ip_track: 66.249.66.21 (crawl-66-249-66-21.googlebot.com) count=91 limit=90 period=60
      Rails.logger.warn("#{name}: ALERT: #{match_name}: #{discriminator} (#{hostname || "no hostname"}) #{match_data_formatted}")
    else
      # eg: track.rack_attack: req/ip_track: 66.249.66.21 count=91 limit=90 period=60
      Rails.logger.warn("#{name}: #{match_name}: #{discriminator}: #{match_data_formatted}")
    end

    # we put it in cache for up to our total alert window, so we can make sure
    # not to alert more than that.
    Rack::Attack.cache.write(last_logged_key, JSON.dump(last_logged_info), alert_only_per)
  end
end


# Explained at https://sciencehistory.atlassian.net/wiki/spaces/HDC/pages/2645098498/Cloudflare+Turnstile+bot+detection
Rails.application.config.to_prepare do
  # allow rate_limit_count requests in rate_limit_period, before issuing challenge
  BotDetectController.rate_limit_period = 12.hour
  BotDetectController.rate_limit_count = 5

  # How long a challenge pass is good for
  BotDetectController.session_passed_good_for = 24.hours

  BotDetectController.enabled                 = Settings.cf_turnstile_enabled
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
