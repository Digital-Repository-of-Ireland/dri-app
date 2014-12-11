Then /^I should wait$/ do
  sleep 2
end

Then /^I should wait for "(.*?)" seconds$/ do |time|
  sleep(time.to_i)
end

When /^I wait for the ajax request to finish$/ do
  counter = 0
  while page.execute_script("return $.active").to_i > 0
    counter += 1
    sleep(0.1)
    raise "AJAX request took longer than 5 seconds." if counter >= 50
  end
end
