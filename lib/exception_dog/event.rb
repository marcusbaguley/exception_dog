require 'net/http'
require 'uri'
require 'json'
require 'datadog/statsd'

module ExceptionDog
  class Event
    def self.notify(configuration:, title:, text:, priority: 'normal', tags:, aggregation_key:, source_type_name: 'my_apps', alert_type: 'error')
      logger = configuration.logger
      args = {}
      method(__method__).parameters.map do |_, name|
        args[name] = binding.local_variable_get(name) unless [:configuration].include?(name)
      end
      if configuration.use_agent
        send_to_agent(configuration, args)
      else
        send_to_api(configuration, args)
      end
    end

    def self.send_to_agent(configuration, args)
      @@socket = Datadog::Statsd.new(configuration.agent_host, configuration.agent_port)
      @@socket.event(args[:title], args[:text], args)
    end

    def self.send_to_api(configuration, args)
      uri = URI.parse("https://api.datadoghq.com/api/v1/events?api_key=#{configuration.api_key}")
      logger = configuration.logger
      header = {'Content-Type': 'application/json'}
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri, header)
      request.body = args.to_json
      logger.info "ExceptionDog::Sending error event to datadog"
      begin
        response = http.request(request)
        logger.debug response.body if response.respond_to?(:body)
        logger.debug "ExceptionDog:Response: #{response.inspect}"
      rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
               Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
        logger.error("ExceptionDog::Failed to send to datadog")
        logger.error(e)
      end
    end
  end
end

