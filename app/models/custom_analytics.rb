class CustomAnalytics
    extend Legato::Model

    filter(:for_collection) {|collectionid| matches(:dimension1, collectionid)}
    metrics :sessions, :pageviews
    dimensions :pagePath, :pageDepth
end
