When /^I create a collection and save the pid$/ do
  steps %{
    Given I am on the home page
    And I go to "create new collection"
    And I enter valid metadata for a collection
    And I check "deposit"
    And I press the button to "create a collection"
  }
  @pid = URI.parse(current_url).path.split('/').last
end

When /^I create an object and save the pid$/ do
  steps %{
    When I create a collection and save the pid
    And I go to the "collection" "show" page for "the saved pid"
    And I follow the link to add an object
    And I enter valid metadata
    And I press the button to "continue"
  }
  @collection_pid = @pid
  @pid = URI.parse(current_url).path.split('/').last
end


Then /^an AIP should exist for the saved pid$/ do
  dir = ""
  index = 0
  4.times {
    dir = File.join(dir, @pid[index..index+1])
    index += 2
  }
  aip_dir = File.join(Settings.dri.files, dir, @pid)
  File.exist?(aip_dir).should be true
end

Then /^the AIP for the saved pid should have "(.*?)" version(?:|s)$/ do |count|
  dir = ""
  index = 0
  4.times {
    dir = File.join(dir, @pid[index..index+1])
    index += 2
  }
  aip_dir = File.join(Settings.dri.files, dir, @pid)
  (Dir.entries(aip_dir).size - 2).to_s.should eql count
end
