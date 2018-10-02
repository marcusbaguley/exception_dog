module ExceptionDog
  class Handler
    attr_reader :configuration
    attr_reader :logger

    def initialize(configuration)
      @configuration = configuration
      @logger = @configuration.logger
      @notifier = Object.const_get(@configuration.notifier).new(configuration)
    end

    def notify(exception, opts = {})
      title = exception.message[0..40]
      text = exception_text(exception, configuration.request_data)[0..1024]
      opts[:priority] ||= 'normal'
      opts[:tags] = ["environment:#{configuration.environment}", "service:#{configuration.service_name}"] + configuration.tags
      opts[:aggregation_key] = aggregation_key(exception)[0..30]
      opts[:source_type_name] = configuration.source_type_name
      opts[:alert_type] = 'error'
      @notifier.notify(title, text, opts)
    end

    def exception_text(exception, request_data)
      detail = [exception.class.name, exception.message]
      rack_request = request_data.delete(:rack_request)
      detail << rack_request_detail(rack_request) if rack_request
      request_data.keys.each do |key|
        detail << request_data[key].inspect
      end
      (detail + (exception.backtrace || [])).compact.join("\n")
    end

    def aggregation_key(exception)
      "#{exception.class.name}-#{exception.message}-#{exception.backtrace&.first}"
    end

    def rack_request_detail(request)
      ["RemoteIP:#{request&.remote_ip}", "Agent:#{request.env.try(:[], 'HTTP_USER_AGENT')}"]
    end

  end
end
