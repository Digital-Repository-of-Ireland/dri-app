When /^I click the first autocomplete result$/ do
  first(".ui-autocomplete li a", visible: true).click
end

When /^I "([^"]*)" and fill in "([^"]*)" and choose the first autocomplete result$/ do |add, text|
  steps %{
    When I press the edit collection button with text "#{add}"
    And I fill in "#{button_to_input_id(add)}" with "#{text}"
    And I click the first autocomplete result
  }
end

When /^I select "([^"]*)" from the autocomplete menu$/ do |text|
  find(".vocab-dropdown", visible: true).select(text)
end

Then /^the text in "([^"]*)" should( not)? have link styling$/ do |selector, negation|
  elem = first("##{escape_id(selector)}", visible: true)
  has_underline = elem.style('text-decoration').values.any? { |v| v.include? 'underline' }
  is_blue = elem.style('color').values == ['rgba(0, 0, 255, 1)']
  expect(has_underline).to be !negation
  expect(is_blue).to be !negation
end

