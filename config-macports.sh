#!/bin/sh
gem install mysql2 -- --with-mysql-lib=/opt/local/lib/mysql55/mysql --with-mysql-include=/opt/local/include/mysql55/mysql
gem install clamav -- --with-cflags=`clamav-config --cflags` --with-ldflags=`clamav-config --libs`
bundle
