Then /^I should wait$/ do
  sleep 2
end

Then /^I should wait for "(.*?)" seconds$/ do |time|
  sleep(time.to_i)
end
