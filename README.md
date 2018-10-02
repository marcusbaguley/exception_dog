# ExceptionDog

Exception dog is a simple exception notifier gem that pushes exceptions out to Dotadog as metric events. You can set up rules within datadog to push new occurrences of the events into slack for instance, to have a reasonably good exception service.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'exception_dog'
```

## Usage

`exception_dog` can be configured to use the datadog agent or the public cloud API.
You can configure in an initialiser, for example: in a file `config/initializers/exception_dog.rb`

Agent Configuration Example
```
ExceptionDog.configure do |config|
  config.environment = ENV["RAILS_ENV"]
  config.notifier = Rails.env.test? ? "ExceptionDog::LogNotifier" : "ExceptionDog::AgentNotifier"
  config.agent_host = 'localhost'
  config.agent_port = 8125
  config.logger = Rails.logger
  config.service_name = Rails.application.class.name.underscore
end
```

Cloud API configuration

```
ExceptionDog.configure do |config|
  config.environment = ENV["RAILS_ENV"]
  config.api_key = ENV["DATA_DOG_API_KEY"]
  config.notifier = Rails.env.test? ? "ExceptionDog::LogNotifier" : "ExceptionDog::HttpNotifier"
  config.logger = Rails.logger
  config.service_name = Rails.application.class.name.underscore
end
```

Middleware Configuration
You can set up a simple middleware to catch and report exceptions for Rack based apps.

```
Rails.application.config.middleware.insert_before Rack::Request, ExceptionDog::Integration::RackMiddleware
```

## Running tests

```
ruby -Ilib -Itest test/*.rb
```
## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
