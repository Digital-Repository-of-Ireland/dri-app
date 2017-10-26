require 'net/http'

report = open("#{Dir.home}/fixity_report.txt", 'w')

File.foreach("#{Dir.home}/fixity_collections.txt").with_index do |collection_id, line_num|
  check = FixityCheck.where(collection_id: collection_id)
  time = check.latest.first.created_at
  date = time.to_datetime
  if date < Time.now - 1.day
    url = URI.parse("http://localhost:3000/collections/#{collection_id}/fixity")
    req = Net::HTTP::Put.new(url.path)
    req.basic_auth 'admin@dri.ie', 'CHANGEME'

    resp = Net::HTTP.new(url.host, url.port).start {|http| http.request(req) }
    report.write("#{collection_id} #{time} running\n")
  else
    failed = check.failed.pluck(:object_id)
    result = failed.any? ? 'failed' : 'passed'
    report.write("#{collection_id} #{time} #{result}\n")
  end
end

report.close
