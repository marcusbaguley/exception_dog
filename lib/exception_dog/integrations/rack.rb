module ExceptionDog::Integrations
  class Rack
    def initialize(app)
      @app = app
    end

    def call(env)
      begin
        response = @app.call(env)
      rescue Exception => raised
        data = {
          request_uri: env["REQUEST_URI"],
          remote_ip: env["HTTP_X_FORWARDED_FOR"] || env["HTTP_FORWARDED_FOR"]
        }
        ExceptionDog.notify(raised, data)
        raise raised
      end
      response
    end
  end
end
