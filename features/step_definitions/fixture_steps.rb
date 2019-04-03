# Copyright © 2012 The Pennsylvania State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "rake"

def loaded_files_excluding_current_rake_file
  $".reject { |file| file.include? "lib/tasks/dri-fixtures" }
end

def activefedora_path
  Gem.loaded_specs['active-fedora'].full_gem_path
end

Given /^an object with pid "([^\"]*)" exists$/ do |pid|
  @rake = Rake::Application.new
  Rake.application = @rake
  Rake.application.rake_require("lib/tasks/dri-fixtures", ["."], loaded_files_excluding_current_rake_file)
  Rake.application.rake_require("lib/tasks/active_fedora", [activefedora_path], loaded_files_excluding_current_rake_file)
  Rake::Task.define_task(:environment)
  @rake['dri:fixtures:refresh'].invoke

  object = ActiveFedora::Base.find(pid, {:cast => true})
end

Given /^a swagger fixture$/ do
  # TODO: find a better way to ensure swagger.json exists so api-docs feature passes  
  system("cp #{File.join(cc_fixture_path, 'swagger.json')} #{File.join(Rails.root, 'swagger', 'v1', 'swagger.json')}")

end
