class AnalyticsObjectUsers
    extend Legato::Model

    filter :collections, &lambda {|*collections| collections.map {|collectionid| matches(:dimension1, collectionid)}}

    metrics :users
    dimensions :dimension3
end
