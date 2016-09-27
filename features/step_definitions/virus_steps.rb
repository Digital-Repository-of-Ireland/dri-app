When(/^I upload the virus file "(.*?)"$/) do |file|
  attach_file("Filedata", File.join(cc_fixture_path, file))

  error = DRI::Exceptions::VirusDetected.new('Eicar-Test-Signature')
  Validators.should_receive(:virus_scan).and_raise(error)

  click_link_or_button(button_to_id('upload a file'))
end

When(/^I upload the logo virus file "(.*?)"$/) do |file|
  attach_file("logo_file", File.join(cc_fixture_path, file))

  error = DRI::Exceptions::VirusDetected.new('Eicar-Test-Signature')
  Validators.should_receive(:virus_scan).and_raise(error)

  click_link_or_button(button_to_id('add a licence'))
end
