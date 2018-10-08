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

  def exception_hash
    {"title":"Hello","text":"StandardError\nHello\nline1","priority":"normal","tags":["environment:prod","service:mini_test_specs"],"aggregation_key":"StandardError-Hello-line1".hash.to_s,"source_type_name":"my_apps","alert_type":"error"}
  end

  it 'has a version number' do
    refute_nil ::ExceptionDog::VERSION
  end

  describe 'with a api configuration' do
    before do
      ExceptionDog.configure do |config|
        config.api_key = api_key
        config.service_name = 'mini_test_specs'
        config.notifier = "ExceptionDog::HttpNotifier"
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
        assert_requested :post, "https://api.datadoghq.com/api/v1/events?api_key=#{api_key}", body: exception_hash.to_json
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
          rescue => e
            assert_equal e.class, StandardError, e
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
      end
    end
  end

  describe 'with an agent configuration' do
    before do
      ExceptionDog.configure do |config|
        config.service_name = 'mini_test_specs'
        config.notifier = "ExceptionDog::AgentNotifier"
        config.logger = Logger.new(nil)
      end
    end

    it 'configures the agent' do
      config = ExceptionDog.configuration
      assert_equal config.agent_host, 'localhost'
      assert_equal config.agent_port, 8125
    end

    it 'configures the service_name' do
      assert_equal ExceptionDog.configuration.service_name, 'mini_test_specs'
    end

    it 'is valid' do
      assert_equal ExceptionDog.configuration.errors, []
      assert_equal ExceptionDog.configuration.valid?, true
    end

    it 'does not raise' do
      ExceptionDog.notify(exception)
    end
  end
end
