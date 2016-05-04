source 'https://rubygems.org'
gemspec

# Exact specification is here, as we cannot declare a :git dependency in ydim.gemspec
gem "dbi", :branch => 'master', :git => 'https://github.com/ngiger/ruby-dbi'
gem "odba", :git => 'https://github.com/ngiger/odba.git'
gem "pdf-writer",:git => 'https://github.com/ngiger/pdf-writer.git'


group :debugger do
	if RUBY_VERSION.match(/^1/)
		gem 'pry-debugger'
	else
		gem 'pry-byebug'
    gem 'pry-doc'
	end
end
