SanePatch.patch('blacklight', '~> 7.0') do
  Deprecation.default_deprecation_behavior = :silence
end
