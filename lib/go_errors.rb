require "go_errors/version"
require "go_errors/middleware"
require "go_errors/railtie"

# Override the error templates path to serve our modified ones
ActionDispatch::DebugExceptions.send(:remove_const, :RESCUES_TEMPLATE_PATH)
ActionDispatch::DebugExceptions.const_set(:RESCUES_TEMPLATE_PATH, File.expand_path('../templates', __FILE__))

module GoErrors
  class << self
    attr_accessor :configuration
  end

  def self.config
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
    self.configuration
  end

  class Configuration
    attr_accessor :host, :api_token

    def initialize
      @host = "http://goerrors.com"
    end
  end
end
