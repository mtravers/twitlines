source "https://rubygems.org"
ruby "1.8.7"
gem "rails", "~> 2.3.11"
# gem "rack", "~> 1.4.1"
gem "json"
gem "libxml-ruby"
gem "oauth"
# gem "oauth-plugin"
gem "httparty"
# gem "thin"

group :production , :staging do
  gem "pg"
end

group :development, :test do
  gem "sqlite3"
end
