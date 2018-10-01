require 'net/http'
require 'uri'
require 'json'

module ExceptionDog
  class Event
    def self.post(api_key:, logger:, title:, text:, priority: 'normal', tags:, aggregation_key:, source_type_name: 'my_apps', alert_type: 'error')
      args = {}
      method(__method__).parameters.map do |_, name|
        args[name] = binding.local_variable_get(name) unless [:api_key, :logger].include?(name)
      end
      uri = URI.parse("https://api.datadoghq.com/api/v1/events?api_key=#{api_key}")
      header = {'Content-Type': 'application/json'}
      # Create the HTTP objects
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri, header)
      request.body = args.to_json
      # Send the request
      logger.info "ExceptionDog::Sending error event to datadog"
      response = http.request(request)
      logger.debug response.body if response.respond_to?(:body)
      logger.debug "ExceptionDog:Response: #{response.inspect}"
    end
  end
end

