class AnalyticsCollectionUsers
    extend Legato::Model

    filter :collections, &lambda {|*collections| collections.map {|collectionid| matches(:dimension1, collectionid)}}

    metrics :users
    dimensions :dimension1
end
