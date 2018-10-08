require "rubygems"

require "exception_dog/version"
require "exception_dog/agent_notifier"
require "exception_dog/http_notifier"
require "exception_dog/log_notifier"
require "exception_dog/handler"

module ExceptionDog
  class Configuration
    attr_accessor :api_key
    attr_accessor :app_name
    attr_accessor :source_type_name
    attr_accessor :alert_type
    attr_accessor :environment
    attr_accessor :logger
    attr_accessor :service_name
    attr_accessor :tags
    attr_accessor :test_mode
    attr_accessor :agent_host
    attr_accessor :agent_port
    attr_accessor :notifier
    attr_accessor :notifier_instance

    def initialize
      self.source_type_name = 'my_apps'
      self.alert_type = 'error'
      self.environment = 'prod'
      self.test_mode = false
      self.agent_host = 'localhost'
      self.agent_port = 8125
      self.tags = []
      self.logger = Logger.new(STDOUT)
    end

    def errors
      @errors = []
      @errors << "No service_name supplied" unless service_name
      @errors << "No notifier configured" unless notifier
      @errors
    end

    def valid?
      errors.empty?
    end
  end

  class << self

    def configuration
      @configuration
    end

    def configure
      @configuration = Configuration.new
      yield @configuration
      @configuration.logger ||= Logger.new(STDOUT)
      if !configuration.valid?
        @configuration.logger.error "Invalid ExceptionDog config #{configuration.errors.inspect}"
        @configuration.notifier = "LogNotifier"
      end
      @handler = Handler.new(configuration)
      @configuration
    end

    def notify(exception, opts = {})
      @handler.notify(exception, opts)
    end

    def default_hostname
      Socket.gethostname;
    end
  end
end
