class AnalyticsObjectUsers
    extend Legato::Model

    filter :collection, &lambda {|collectionid| matches(:dimension1, collectionid)}

    metrics :users, :pageviews
    dimensions :pagepath#, :dimension3
end
