require "rubygems"

require "exception_dog/version"
require "exception_dog/event"
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

    def initialize
      self.source_type_name = 'my_apps'
      self.alert_type = 'error'
      self.environment = 'prod'
      self.test_mode = false
      self.tags = []
      self.logger = Logger.new(STDOUT)
    end

    def errors
      @errors = []
      @errors << "Invalid API Key" unless api_key && api_key =~ /[0-9a-f]{32}/i
      @errors << "No service_name supplied" unless service_name
      @errors
    end

    def valid?
      errors.empty?
    end
  end

  class << self
    THREAD_LOCAL_NAME = "exception_dog_request"

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield configuration
      configuration.logger ||= Logger.new(STDOUT)
      configuration.logger.error "Invalid ExceptionDog config #{configuration.errors.inspect}" unless configuration.valid?
      configuration
    end

    def notify(exception)
      Handler.notify(exception: exception, configuration: configuration, request_data: request_data)
    end

    def request_data
      Thread.current[THREAD_LOCAL_NAME] ||= {}
    end

    def set_request_data(key, value)
      self.request_data[key] = value
    end

    def clear_request_data
      Thread.current[THREAD_LOCAL_NAME] = nil
    end

    def default_hostname
      Socket.gethostname;
    end
  end
end
