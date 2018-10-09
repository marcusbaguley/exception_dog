$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "exception_dog"

require "minitest/autorun"
require "minitest/spec"
require "minitest/mock"
require 'webmock/minitest'
include WebMock::API
module Datadog
  class Context
    def trace_id
      123
    end
  end
end
