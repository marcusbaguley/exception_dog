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


    def notify(exception, opts)
      title = exception.message[0..MAX_TITLE_LENGTH]
      text = exception_text(exception, opts)[0..MAX_TEXT_LEGNTH]
      opts[:priority] ||= 'normal'
      opts[:tags] = ["environment:#{configuration.environment}", "service:#{configuration.service_name}"] + configuration.tags
      opts[:aggregation_key] = aggregation_key(exception)
      opts[:source_type_name] = configuration.source_type_name
      opts[:alert_type] = 'error'
      @notifier.notify(title, text, opts)
    end

    def exception_text(exception, opts)
      detail = [exception.class.name[0..MAX_LINE_LENGTH], exception.message[0..MAX_LINE_LENGTH]]
      opts.keys.each do |key|
        detail << "#{key}: #{opts[key].inspect[0..MAX_LINE_LENGTH]}"
      end
      (detail + (exception.backtrace || []))[0..BACKTRACE_LINES].compact.join("\n")
    end

    def aggregation_key(exception)
      "#{exception.class.name}-#{exception.message}-#{exception.backtrace&.first}".hash.to_s
    end

  end
end
