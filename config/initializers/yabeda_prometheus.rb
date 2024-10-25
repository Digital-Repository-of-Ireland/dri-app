unless Rails.env.development? || Rails.env.test?
  Yabeda::Prometheus::Exporter.start_metrics_server!
end
