require 'net/http'
require 'uri'
require 'json'
require 'datadog/statsd'

module ExceptionDog
  class AgentNotifier

    attr_reader :configuration
    attr_reader :logger

    OPTS_WHITELIST = [:priority, :tags, :aggregation_key, :source_type_name, :alert_type]

    def initialize(configuration)
      @configuration = configuration
      @logger = configuration.logger
    end

    def notify(title, text, opts)
      logger.info "ExceptionDog::send_to_agent"
      @@socket ||= Datadog::Statsd.new(configuration.agent_host, configuration.agent_port, logger: configuration.logger)
      response = @@socket.event(title, text, opts)
    end

    def errors
      @errors  = []
      @errors << "Invalid host setup" unless configuration.agent_port && configuration.agent_host
      @errors
    end

  end
end

