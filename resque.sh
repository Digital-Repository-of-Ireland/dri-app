#!/bin/sh
# Start resque workers
bundle exec rake environment resque:work RAILS_ENV=development QUEUE="*" VERBOSE=1 
