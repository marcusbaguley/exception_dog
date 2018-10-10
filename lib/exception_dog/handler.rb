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
      return if ignored(exception)
      attach_dd_trace_id(data) if self.class.dd_trace_enabled
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
      (detail + format_backtrace(exception.backtrace)).compact.join("\n")
    end

    def aggregation_key(exception)
      "#{exception.class.name}-#{exception.message}-#{exception.backtrace&.first}".hash.to_s
    end

    def attach_dd_trace_id(data)
      data[:trace_id] = self.class.current_trace_id
    end

    def ignored(exception)
      configuration.ignore_exceptions&.include?(exception.class.name)
    end

    # remove backticks, single quotes, \n and ensure each line is reasonably small
    def format_backtrace(backtrace)
      backtrace ||= []
      backtrace[0..BACKTRACE_LINES].collect do |line|
        "`#{line.gsub(/\n|\`|\'/, '')}`\n"[0..MAX_LINE_LENGTH]
      end
    end

    def self.current_trace_id
      context = Thread.current[:datadog_context]
      context&.trace_id
    end

    def self.dd_trace_enabled
      @dd_trace_enabled ||= Object.const_get('Datadog::Context') rescue false
    end
  end
end
