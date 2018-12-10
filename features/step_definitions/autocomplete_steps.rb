When /^I click the first autocomplete result$/ do
  first(".ui-autocomplete li a").click
end

Then /^the text in "([^"]*)" should( not)? have link styling$/ do |selector, negation|
  elem = first("##{escape_id(selector)}", visible: true)
  has_underline = elem.style('text-decoration').values.any? { |v| v.include? 'underline' }
  is_blue = elem.style('color').values == ['rgba(0, 0, 255, 1)']
  expect(has_underline).to be !negation
  expect(is_blue).to be !negation
end

# Then /^the hidden "([^"]*)" input should contain "([^"]*)"$/ do

# end
