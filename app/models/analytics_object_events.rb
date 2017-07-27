class AnalyticsObjectEvents
    extend Legato::Model

    filter :collection, &lambda {|collection| matches(:eventCategory, collection)}
    filter :action, &lambda {|action| matches(:eventAction, action)}

    metrics :totalEvents, :uniqueEvents
    dimensions :eventAction, :eventCategory, :eventLabel
end
