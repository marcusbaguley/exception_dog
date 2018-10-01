require 'test_helper'
require 'exception_dog'
require 'exception_dog/integrations/rack'

describe ExceptionDog do

  def exception
    exception = StandardError.new("Hello")
    exception.set_backtrace( ["line1"] )
    exception
  end

  def api_key
    "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  end

  it 'has a version number' do
    refute_nil ::ExceptionDog::VERSION
  end

  describe 'with a valid configuration' do
    before do
      ExceptionDog.configure do |config|
        config.api_key = api_key
        config.service_name = 'mini_test_specs'
        config.logger = Logger.new(nil)
      end
    end

    it 'configures the api_key' do
      assert_equal ExceptionDog.configuration.api_key, api_key
    end

    it 'configures the service_name' do
      assert_equal ExceptionDog.configuration.service_name, 'mini_test_specs'
    end

    it 'is valid' do
      assert ExceptionDog.configuration.valid?
    end

    describe 'with a mocked request' do
      before do
        stub_request(:post, "https://api.datadoghq.com/api/v1/events?api_key=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
      end

      it 'notifies with an exception' do
        ExceptionDog.notify(exception)
        assert_requested :post, "https://api.datadoghq.com/api/v1/events?api_key=#{api_key}", body: {"title":"Hello","text":"StandardError\nHello\nline1","tags":["environment:prod","service:mini_test_specs"],"aggregation_key":"StandardError-Hello-line1","priority":"normal","source_type_name":"my_apps","alert_type":"error"}.to_json
      end

      describe ' using middleware' do
        class MyExceptionRaisingMiddleware
          def initialize(app)
            @exception = app[:exception]
          end
          def call(env)
            raise @exception if @exception
          end
        end

        it 'notifies from an exception and raises in middleware' do
          app =  MyExceptionRaisingMiddleware.new({exception: exception})
          middleware = ExceptionDog::Integrations::Rack.new(app)
          begin
            middleware.call({})
            assert false
          rescue
            assert true
          end
          assert_requested :post, "https://api.datadoghq.com/api/v1/events?api_key=#{api_key}"
        end

        it 'does not notify or raise exception in middleware' do
          app =  MyExceptionRaisingMiddleware.new({})
          middleware = ExceptionDog::Integrations::Rack.new(app)
          begin
            middleware.call({})
            assert true
          rescue
            assert false
          end
          assert_not_requested :post, "https://api.datadoghq.com/api/v1/events?api_key=#{api_key}"
        end

        it 'notifies from a rack exception and does not raise' do
          app =  MyExceptionRaisingMiddleware.new({})
          middleware = ExceptionDog::Integrations::Rack.new(app)
          begin
            env = {"rack.exception" => exception}
            middleware.call(env)
            assert true
          rescue
            assert false
          end
          assert_requested :post, "https://api.datadoghq.com/api/v1/events?api_key=#{api_key}"
        end
      end
    end
  end
end
