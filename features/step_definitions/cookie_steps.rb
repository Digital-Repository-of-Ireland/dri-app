World(ShowMeTheCookies)

Then /^I should have a cookie (.*)$/ do |cookie|
  if Capybara.current_driver.to_s == "webkit"
    page.driver.cookies.find(cookie).should_not be_nil
  else
    get_me_the_cookie(cookie).should_not be_nil
  end
end

Then /^I should not have a cookie (.*)$/ do |cookie|
  if Capybara.current_driver.to_s == "webkit"
    page.driver.cookies.find(cookie).should be_nil
  else
    get_me_the_cookie(cookie).should be_nil
  end
end
