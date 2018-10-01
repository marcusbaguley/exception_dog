require 'net/http'
require 'uri'
require 'json'

module ExceptionDog
  class Event
    def self.post(api_key:, title:, text:, priority: 'normal', tags:, aggregation_key:, source_type_name: 'my_apps', alert_type: 'error')
      args = {}
      method(__method__).parameters.map do |_, name|
        args[name] = binding.local_variable_get(name) unless name == :api_key
      end
      uri = URI.parse("https://api.datadoghq.com/api/v1/events?api_key=#{api_key}")
      header = {'Content-Type': 'text/json'}
      # Create the HTTP objects
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri, header)
      request.body = args.to_json
      # Send the request
      response = http.request(request)
    end
  end
end

