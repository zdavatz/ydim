# ydim

* https://github.com/zdavatz/ydim.git

## DESCRIPTION:

ywesee distributed invoice manager, Ruby

## Install Ruby

* git clone https://github.com/rbenv/rbenv.git ~/.rbenv
* echo 'eval "$(~/.rbenv/bin/rbenv init - bash)"' >> ~/.bashrc
* git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build

## Install Postgresql

* sudo apt-get install postgresql-10 postgresql-contrib-10
* wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
* echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/postgresql-pgdg.list &gt; /dev/null
* sudo echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/postgresql-pgdg.list &gt; /dev/null
* sudo apt-get install postgresql-10

## INSTALL:

* gem install ydim

If you have a non standard path of postgres use something like

* gem install pg -- --with-pg-config=/usr/local/pgsql-10.1/bin/pg_config

Or if you are using bundler

* bundle config build.pg --with-pg-config=/usr/local/pgsql-10.1/bin/pg_config
* bundle install

## Migrating an old database

An old database can be migrated to UTF-8 by calling

    bundle install --path vendor
    bundle exec bin/migrate_to_utf_8

## DEVELOPERS:

* Masaomi Hatakeyama
* Zeno R.R. Davatz
* Hannes Wyss (up to Version 1.0)
* Niklaus Giger (ported to Ruby 2.3.0)

## LICENSE:

* GPLv2
