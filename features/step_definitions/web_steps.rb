Given /^(?:|I )am on (.+)$/ do |page_name|
  visit path_to(page_name)
end

When /^I attach the metadata file "(.*?)"$/ do |file|
  attach_file("metadata_file", "spec/fixtures/#{file}")
end

Then /^I press "(.*?)"$/ do |button|
  click_button(button)
end

Then /^(?:|I )should see "([^"]*)"$/ do |text|
  if page.respond_to? :should
    page.should have_content(text)
  else
    assert page.has_content?(text)
  end
end

Then /^(?:|I )should see \/([^\/]*)\/$/ do |regexp|
  regexp = Regexp.new(regexp)

  if page.respond_to? :should
    page.should have_xpath('//*', :text => regexp)
  else
    assert page.has_xpath?('//*', :text => regexp)
  end
end

Then /^show me the page$/ do
  save_and_open_page
end

def path_to(page_name)
    
    case page_name
  
    when /new Digital Object page/
      '/audios/new'

    end
end

