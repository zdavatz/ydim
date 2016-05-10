source 'https://rubygems.org'
gemspec

# Exact specification is here, as we cannot declare a :git dependency in ydim.gemspec
gem "dbi",       :git => 'https://github.com/zdavatz/ruby-dbi'
gem "odba",      :git => 'https://github.com/zdavatz/odba.git'
gem "pdf-writer",:git => 'https://github.com/zdavatz/pdf-writer.git'


group :debugger do
	if RUBY_VERSION.match(/^1/)
		gem 'pry-debugger'
	else
		gem 'pry-byebug'
    gem 'pry-doc'
	end
end
