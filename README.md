# ExceptionDog


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'exception_dog'
```

## Usage
Initialise exception_dog in a `config/initializers/exception_dog.rb`
```
ExceptionDog.configure do |config|
  config.environment = ENV["RAILS_ENV"]
  config.api_key = ENV["DATA_DOG_API_KEY"]
  config.test_mode = Rails.env.test?
  config.logger = Rails.logger
  config.service_name = Rails.application.class.name.underscore
end

Rails.application.config.middleware.insert_before Rack::Request, ExceptionDog::Integration::RackMiddleware
```

## Running tests

```
ruby -Ilib -Itest test/*.rb
```
## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
