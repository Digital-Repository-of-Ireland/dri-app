When(/^I upload the virus file "(.*?)"$/) do |file|
  attach_file("Filedata", File.join(cc_fixture_path, file))

  error = Exceptions::VirusDetected.new('Eicar-Test-Signature')
  Validators.should_receive(:virus_scan).and_raise(error)

  click_link_or_button(button_to_id('upload a file'))
end
