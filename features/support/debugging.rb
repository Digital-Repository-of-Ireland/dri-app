require "pp"
After do |scenario|
  save_and_open_page if scenario.failed? and (ENV["debug"] == "open")
  pp(page) if ENV["debug"] == "pp"
end
