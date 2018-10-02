require 'net/http'
require 'uri'
require 'json'
require 'datadog/statsd'

module ExceptionDog
  class LogNotifier

    attr_reader :configuration
    attr_reader :logger
    attr_reader :messages

    def initialize(configuration)
      @configuration = configuration
      @logger = configuration.logger
      @messages = []
    end

    def notify(title, text, opts)
      logger.info "#{title}, #{text}, #{opts}"
      @messages << [title, text, opts]
    end

    def errors
      []
    end

  end
end

