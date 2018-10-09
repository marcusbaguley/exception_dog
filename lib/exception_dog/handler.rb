module ExceptionDog
  class Handler
    MAX_LINE_LENGTH = 80
    MAX_TITLE_LENGTH = 100
    MAX_TEXT_LEGNTH = 4000
    BACKTRACE_LINES = 7
    attr_reader :configuration
    attr_reader :logger

    def initialize(configuration)
      @configuration = configuration
      @logger = @configuration.logger
      @notifier = Object.const_get(@configuration.notifier).new(configuration)
    end


    def notify(exception, data)
      attach_dd_trace_id(data)
      title = exception.message[0..MAX_TITLE_LENGTH]
      text = exception_text(exception, data)[0..MAX_TEXT_LEGNTH]
      opts = {}
      opts[:priority] ||= 'normal'
      opts[:tags] = ["environment:#{configuration.environment}", "service:#{configuration.service_name}"] + configuration.tags
      opts[:aggregation_key] = aggregation_key(exception)
      opts[:source_type_name] = configuration.source_type_name
      opts[:alert_type] = 'error'
      @notifier.notify(title, text, opts)
    end

    def exception_text(exception, data)
      detail = [exception.class.name[0..MAX_LINE_LENGTH], exception.message[0..MAX_LINE_LENGTH]]
      data.each do |key, val|
        detail << "#{key}: #{val && val.to_s[0..MAX_LINE_LENGTH]}"
      end
      (detail + (exception.backtrace || []))[0..BACKTRACE_LINES].compact.join("\n")
    end

    def aggregation_key(exception)
      "#{exception.class.name}-#{exception.message}-#{exception.backtrace&.first}".hash.to_s
    end

    def attach_dd_trace_id(data)
      enabled = Object.const_get('Datadog::Context') rescue nil
      if enabled
        context = Thread.current[:datadog_context]
        data[:trace_id] = context&.trace_id
      end
    end
  end
end
