module SocialMediaHelper
  def fetch_rss_feed(urls, channel)
    feeds = Feedjira::Feed.fetch_and_parse urls
    feed = feeds[channel]

    return feed.is_a?(Fixnum) ? {} : feed.entries
  end

end
