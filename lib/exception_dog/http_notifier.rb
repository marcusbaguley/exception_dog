require 'net/http'
require 'uri'
require 'json'
require 'datadog/statsd'

module ExceptionDog
  class HttpNotifier

    attr_reader :configuration
    attr_reader :logger

    def initialize(configuration)
      @configuration = configuration
      @logger = configuration.logger
    end

    def notify(title, text, opts)
      uri = URI.parse("https://api.datadoghq.com/api/v1/events?api_key=#{configuration.api_key}")
      logger = configuration.logger
      header = {'Content-Type': 'application/json'}
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri, header)
      request.body = {title: title, text: text}.merge(opts).to_json
      logger.info "ExceptionDog::send_to_api"
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

    def errors
      @errors  = []
      @errors << "Invalid API Key" unless configuration.api_key && configuration.api_key =~ /[0-9a-f]{32}/i
    end
  end
end

