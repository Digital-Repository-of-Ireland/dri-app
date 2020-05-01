ENV['RAILS_ENV'] = ARGV.first || ENV['RAILS_ENV'] || 'development'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

require 'net/http'

report = open("#{Dir.home}/fixity_report.txt", 'w')

File.foreach("#{Dir.home}/fixity_collections.txt").with_index do |line, line_num|
  collection_id = line.strip
  check = FixityCheck.where(collection_id: collection_id)

  unless check.latest.first.nil?
    time = check.latest.first.created_at
    date = time.to_datetime
  else
    first_check = true
    time = Time.now
  end

  if first_check || (date < Time.now - 1.day)
    uri = URI.parse("https://repository.dri.ie/collections/#{collection_id}/fixity")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    req = Net::HTTP::Put.new(uri.request_uri, 'Accept' => 'application/json')
    req.basic_auth 'admin@dri.ie', ''
    resp = http.request(req)

    report.write("#{collection_id} #{time} running\n")
  else
    failed = check.failed.to_a
    result = failed.any? ? 'failed' : 'passed'
    report.write("#{collection_id} #{time} #{result}\n")
  end
end

report.close
