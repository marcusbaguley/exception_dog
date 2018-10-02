module ExceptionDog
  class Handler
    def self.notify(exception:, configuration:, request_data:, priority: 'normal')
      title = exception.message
      aggregation_key = aggregation_key(exception)
      if !configuration.valid? || configuration.test_mode
        fallback_logger(exception: exception, configuration: configuration, request_data: request_data, priority: priority)
      else
        Event.notify(configuration: configuration,
                     title: exception.message,
                     text: exception_text(exception, request_data),
                     priority: priority,
                     tags: ["environment:#{configuration.environment}", "service:#{configuration.service_name}"] + configuration.tags,
                     aggregation_key: aggregation_key(exception),
                     source_type_name: configuration.source_type_name,
                     alert_type: 'error')
      end
    end

    def self.fallback_logger(exception:, configuration:, request_data:, priority: )
      configuration.logger.error(exception_text(exception, request_data))
    end

    def self.exception_text(exception, request_data)
      detail = [exception.class.name, exception.message]
      rack_request = request_data.delete(:rack_request)
      detail << rack_request_detail(rack_request) if rack_request
      request_data.keys.each do |key|
        detail << request_data[key].inspect
      end
      (detail + exception.backtrace).compact.join("\n")
    end

    def self.aggregation_key(exception)
      "#{exception.class.name}-#{exception.message}-#{exception.backtrace.first}"
    end

    def self.rack_request_detail(request)
      ["RemoteIP:#{request&.remote_ip}", "Agent:#{request.env.try(:[], 'HTTP_USER_AGENT')}"]
    end

  end
end
