module ExceptionDog::Integrations
  class Rack
    def initialize(app)
      @app = app
    end

    def call(env)
      ExceptionDog.set_request_data(:rack_env, env)
      begin
        response = @app.call(env)
      rescue Exception => raised
        ExceptionDog.notify(raised)
        raise raised
      end
      ExceptionDog.notify(env["rack.exception"]) if env["rack.exception"]
      response
    ensure
      ExceptionDog.clear_request_data
    end
  end
end
