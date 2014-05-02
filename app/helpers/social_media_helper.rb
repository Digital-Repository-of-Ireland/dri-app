module SocialMediaHelper
  def fetch_rss_feed(urls, channel)
    feeds = Feedjira::Feed.fetch_and_parse urls
    feed = feeds[channel]

    return feed == 0 ? {} : feed.entries
  end

end
