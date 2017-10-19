class AnalyticsObjectUsers
    extend Legato::Model

    filter :collection, &lambda {|collectionid| matches(:dimension1, collectionid)}

    metrics :users
    dimensions :dimension3
end
