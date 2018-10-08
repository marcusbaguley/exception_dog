module ExceptionDog::Integrations
  class Rack
    def initialize(app)
      @app = app
    end

    def call(env)
      ExceptionDog.configuration.set_request_data(:rack_request, env)
      begin
        response = @app.call(env)
      rescue Exception => raised
        ExceptionDog.notify(raised)
        raise raised
      end
      ExceptionDog.notify(env["rack.exception"]) if env["rack.exception"]
      response
    ensure
      ExceptionDog.configuration.clear_request_data
    end
  end
end
