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
      body = args
      if configuration.use_agent
        send_to_agent(configuration.logger, configuration.agent_host, configuration.agent_port, body)
      else
        uri = URI.parse("https://api.datadoghq.com/api/v1/events?api_key=#{configuration.api_key}")
        send_to_api(configuration.logger, uri, body)
      end
    end

    def self.send_to_agent(logger, host, port, event)
      @@socket = Datadog::Statsd.new(host, port)
      @@socket.event(event[:title], event[:text], event)
    end

    def self.send_to_api(logger, uri, body)
      header = {'Content-Type': 'application/json'}
      # Create the HTTP objects
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri, header)
      request.body = body.to_json
      # Send the request
      logger.info "ExceptionDog::Sending error event to datadog"
      response = http.request(request)
      logger.debug response.body if response.respond_to?(:body)
      logger.debug "ExceptionDog:Response: #{response.inspect}"
    end
  end
end

