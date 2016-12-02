World(ShowMeTheCookies)

Given /^I reset the sessions$/ do
  Capybara.reset_sessions!
end

Given /^I have a "([^\"]+)" cookie set to "([^\"]+)"$/ do |key, value|
  headers = {}
  Rack::Utils.set_cookie_header!(headers, key, value)
  cookie_string = headers['Set-Cookie']

  Capybara.current_session.driver.browser.set_cookie(cookie_string)
end

Given /^I delete a "([^\"]+)" cookie$/ do |key|
  headers = {}
  Rack::Utils.set_cookie_header!(headers, key)
  cookie_string = headers['Set-Cookie']

  Capybara.current_session.driver.browser.delete_cookie(cookie_string)
end


Then /^I should have a cookie (.*)$/ do |cookie|
  if Capybara.current_driver.to_s != "rack_test"
    expect(page.driver.cookies.find(cookie)).to_not be_nil
  else
    expect(get_me_the_cookie(cookie)).to_not be_nil
  end
end

Then /^I should not have a cookie (.*)$/ do |cookie|
  if Capybara.current_driver.to_s != "rack_test"
    expect(page.driver.cookies.find(cookie)).to be_nil
  else
    expect(get_me_the_cookie(cookie)).to be_nil
  end
end

Then /^The language cookie content should be (.*)$/ do |value|
  if Capybara.current_driver.to_s != "rack_test"
    expect(page.driver.cookies.find('lang')[:value]).to eq(value)
  else
    expect(get_me_the_cookie('lang')[:value]).to eq(value)
  end
end

Given /^I accept cookies terms$/ do
  find('#accept_cookies').trigger('click')
end
