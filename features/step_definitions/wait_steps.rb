Then /^I should wait$/ do
  sleep 2
end

Then /^I should wait for "(.*?)" seconds$/ do |time|
  sleep(time.to_i)
end

When /^I wait for the ajax request to finish$/ do
  start_time = Time.now
  page.evaluate_script('jQuery.isReady&&jQuery.active==0').class.should_not eql(String) until page.evaluate_script('jQuery.isReady&&jQuery.active==0') or (start_time + 5.seconds) < Time.now do
    sleep 1
  end
end
