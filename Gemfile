source 'https://rubygems.org'
gemspec

gem "pdf-writer",
    :git => 'https://github.com/metaskills/pdf-writer.git'
#    :ref => 'cb725fb333364621c342b3c62fb2e854c8716f6a'
# Exact specification is here, as we cannot declare a :git dependency in ydim.gemspec
gem "dbi", '0.4.5', :git => 'https://github.com/zdavatz/ruby-dbi'

group :debugger do
	if RUBY_VERSION.match(/^1/)
		gem 'pry-debugger'
	else
		gem 'pry-byebug'
    gem 'pry-doc'
	end
end
