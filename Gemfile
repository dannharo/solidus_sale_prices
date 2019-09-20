source 'http://rubygems.org'

branch = ENV.fetch('SOLIDUS_BRANCH', 'master')
gem "solidus", github: "solidusio/solidus", branch: branch

# Needed to help Bundler figure out how to resolve dependencies, otherwise it takes forever to
# resolve them
if branch == 'master' || Gem::Version.new(branch[1..-1]) >= Gem::Version.new('2.10.0')
  gem 'rails', '~> 6.0'
else
  gem 'rails', '~> 5.0'
end

gem 'pg', '~> 0.21'
gem 'mysql2'

# In order to allow testing on older version of Solidus that still
# use the gem factory_girl we need to bundle an older version of
# factory_bot:
gem 'factory_bot', github: 'thoughtbot/factory_bot', ref: 'f1f77'

gemspec
