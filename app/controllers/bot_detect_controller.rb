# This controller has actions for issuing a challenge page for CloudFlare Turnstile product,
# and then redirecting back to desired page.
#
# It also includes logic for configuring rack attack and a Rails controller filter to enforce
# redirection to these actions. All the logic related to bot detection with turnstile is
# mostly in this file -- with very flexible configuration in class_attributes -- to faciliate
# future extraction to a re-usable gem if desired.
#
# See more local docs at https://sciencehistory.atlassian.net/wiki/spaces/HDC/pages/2645098498/Cloudflare+Turnstile+bot+detection
#
class BotDetectController < ApplicationController
  # Config for bot detection is held here in class_attributes, kind of wonky, but it works
  #
  # These are defaults ready for extraction to a gem, in general here at Sci Hist if we want
  # to set config we do it in ./config/initializers/rack_attack.rb

  class_attribute :enabled, default: false # Must set to true to turn on at all

  class_attribute :cf_turnstile_sitekey, default: "1x00000000000000000000AA" # a testing key that always passes
  class_attribute :cf_turnstile_secret_key, default: "1x0000000000000000000000000000000AA" # a testing key always passes
  # Turnstile testing keys: https://developers.cloudflare.com/turnstile/troubleshooting/testing/

  # up to rate_limit_count requests in rate_limit_period before challenged
  class_attribute :rate_limit_period, default: 12.hour
  class_attribute :rate_limit_count, default: 10

  # how long is a challenge pass good for before re-challenge?
  class_attribute :session_passed_good_for, default: 24.hours

  # An array, can be:
  #   * a string, path prefix
  #   * a hash of rails route-decoded params, like `{ controller: "something" }`,
  #     or `{ controller: "something", action: "index" }
  #     The hash is more expensive to check and uses some not-technically-public
  #     Rails api, but it's just so convenient.
  #
  # Used by default :location_matcher, if set custom may not be used
  class_attribute :rate_limited_locations, default: []

  # Executed at the _controller_ filter level, to last minute exempt certain
  # actions from protection.
  class_attribute :allow_exempt, default: ->(controller) { false }


  # rate limit per subnet, following lehigh's lead, although we use a smaller
  # subnet: /24 for IPv4, and /72 for IPv6
  # https://git.drupalcode.org/project/turnstile_protect/-/blob/0dae9f95d48f9d8cae5a8e61e767c69f64490983/src/EventSubscriber/Challenge.php#L140-151
  class_attribute :rate_limit_discriminator, default: (lambda do |req|
    ip = Rails.env.production? ? req.remote_ip : ip
    if req.ip.index(":") # ipv6
      IPAddr.new("#{req.ip}/24").to_string
    else
      IPAddr.new("#{req.ip}/72").to_string
    end
  rescue IPAddr::InvalidAddressError
    req.ip
  end)

  class_attribute :location_matcher, default: ->(rack_req) {
    parsed_route = nil
    rate_limited_locations.any? do |val|
      case val
      when Hash
        begin
          # #recognize_path may e not techinically public API, and may be expensive, but
          # no other way to do this, and it's mentioned in rack-attack:
          # https://github.com/rack/rack-attack/blob/86650c4f7ea1af24fe4a89d3040e1309ee8a88bc/docs/advanced_configuration.md#match-actions-in-rails
          # We do it lazily only if needed so if you don't want that don't use it.
          parsed_route ||= rack_req.env["action_dispatch.routes"].recognize_path(rack_req.url, method: rack_req.request_method)
          parsed_route && parsed_route >= val
        rescue ActionController::RoutingError
          false
        end
      when String
        # string complete path at beginning, must end in ?, or end of string
        /\A#{Regexp.escape val}(\/|\?|\Z)/ =~ rack_req.path
      end
    end
  }
  class_attribute :cf_turnstile_js_url, default: "https://challenges.cloudflare.com/turnstile/v0/api.js"
  class_attribute :cf_turnstile_validation_url, default:  "https://challenges.cloudflare.com/turnstile/v0/siteverify"
  class_attribute :cf_timeout, default: 3 # max timeout seconds waiting on Cloudfront Turnstile api
  helper_method :cf_turnstile_js_url, :cf_turnstile_sitekey

  # key stored in Rails session object with channge passed confirmed
  class_attribute :session_passed_key, default: "bot_detection-passed"

  # key in rack env that says challenge is required
  class_attribute :env_challenge_trigger_key, default: "bot_detect.should_challenge"

  # for allowing unsubscribe for testing
  class_attribute :_track_notification_subscription, instance_accessor: false

  # perhaps in an initializer, and after changing any config, run:
  #
  #     Rails.application.config.to_prepare do
  #       BotDetectController.rack_attack_init
  #     end
  #
  # Safe to call more than once if you change config and want to call again, say in testing.
  def self.rack_attack_init
    self._rack_attack_uninit # make it safe for calling multiple times

    ## Turnstile bot detection throttling
    #
    # for paths matched by `rate_limited_locations`, after over rate_limit count requests in rate_limit_period,
    # token will be stored in rack env instructing challenge is required.
    #
    # For actual challenge, need before_action in controller.
    #
    # You could rate limit detect on wider paths than you actually challenge on, or the same. You probably
    # don't want to rate-limit detect on narrower list of paths than you challenge on!
    Rack::Attack.track("bot_detect/rate_exceeded",
        limit: self.rate_limit_count,
        period: self.rate_limit_period) do |req|
      if self.enabled && self.location_matcher.call(req)
        self.rate_limit_discriminator.call(req)
      end
    end

    self._track_notification_subscription = ActiveSupport::Notifications.subscribe("track.rack_attack") do |_name, _start, _finish, request_id, payload|
      rack_request = payload[:request]
      rack_env     = rack_request.env
      match_name = rack_env["rack.attack.matched"]  # name of rack-attack rule

      if match_name == "bot_detect/rate_exceeded"
        match_data   = rack_env["rack.attack.match_data"]
        match_data_formatted = match_data.slice(:count, :limit, :period).map { |k, v| "#{k}=#{v}"}.join(" ")
        discriminator = rack_env["rack.attack.match_discriminator"] # unique key for rate limit, usually includes ip

        rack_env[self.env_challenge_trigger_key] = true
      end
    end
  end

  def self._rack_attack_uninit
    Rack::Attack.track("bot_detect/rate_exceeded") {} # overwrite track name with empty proc
    ActiveSupport::Notifications.unsubscribe(self._track_notification_subscription) if self._track_notification_subscription
    self._track_notification_subscription = nil
  end

  # Usually in your ApplicationController,
  #
  #     before_action { |controller| BotDetectController.bot_detection_enforce_filter(controller) }
  def self.bot_detection_enforce_filter(controller)
    if self.enabled &&
        controller.request.env[self.env_challenge_trigger_key] &&
        !controller.session[self.session_passed_key].try { |date| Time.now - Time.new(date) < self.session_passed_good_for } &&
        !controller.kind_of?(self) && # don't ever guard ourself, that'd be a mess!
        ! self.allow_exempt.call(controller)

      # we can only do GET requests right now
      if !controller.request.get?
        Rails.logger.warn("#{self}: Asked to protect request we could not, unprotected: #{controller.requet.method} #{controller.request.url}, (#{controller.request.remote_ip}, #{controller.request.user_agent})")
        return
      end

      Rails.logger.info("#{self.name}: Cloudflare Turnstile challenge redirect: (#{controller.request.remote_ip}, #{controller.request.user_agent}): from #{controller.request.url}")
      # status code temporary
      controller.redirect_to controller.bot_detect_challenge_path(dest: controller.request.original_fullpath), status: 307
    end
  end


  def challenge
  end

  def verify_challenge
    body = {
      secret: self.cf_turnstile_secret_key,
      response: params["cf_turnstile_response"],
      remoteip: request.remote_ip
    }

    http = HTTP.timeout(self.cf_timeout)
    response = http.post(self.cf_turnstile_validation_url,
      json: body)

    result = response.parse
    # {"success"=>true, "error-codes"=>[], "challenge_ts"=>"2025-01-06T17:44:28.544Z", "hostname"=>"example.com", "metadata"=>{"result_with_testing_key"=>true}}
    # {"success"=>false, "error-codes"=>["invalid-input-response"], "messages"=>[], "metadata"=>{"result_with_testing_key"=>true}}

    if result["success"]
      # mark it as succesful in session, and record time. They do need a session/cookies
      # to get through the challenge.
      session[self.session_passed_key] = Time.now.utc.iso8601
    else
      Rails.logger.warn("#{self.class.name}: Cloudflare Turnstile validation failed (#{request.remote_ip}, #{request.user_agent}): #{result}")
    end

    # let's just return the whole thing to client? Is there anything confidential there?
    render json: result
  rescue HTTP::Error, JSON::ParserError => e
    # probably an http timeout? or something weird.
    Rails.logger.warn("#{self.class.name}: Cloudflare turnstile validation error (#{request.remote_ip}, #{request.user_agent}): #{e}: #{response&.body}")
    render json: {
      success: false,
      http_exception: e
    }
  end
end