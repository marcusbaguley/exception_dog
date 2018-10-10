require 'net/http'
require 'uri'
require 'json'
require 'datadog/statsd'

module ExceptionDog
  class LogNotifier

    attr_reader :configuration
    attr_reader :logger

    def initialize(configuration)
      @configuration = configuration
      @logger = configuration.logger
    end

    def notify(title, text, opts)
      logger.info "#{title}, #{text}, #{opts}"
      @@last_log = [title, text, opts]
    end

    def self.last_log
      @@last_log
    end

    def self.clear_log
      @@last_log = nil
    end

    def errors
      []
    end

  end
end

