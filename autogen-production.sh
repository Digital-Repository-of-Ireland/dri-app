#!/bin/sh
bundle exec rake RAILS_ENV=production assets:precompile
bundle exec rake RAILS_ENV=production db:schema:load
bundle exec rake RAILS_ENV=production db:migrate
