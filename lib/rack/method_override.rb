# frozen_string_literal: true

module Rack
  class MethodOverride
    HTTP_METHODS = %w[GET HEAD PUT POST DELETE OPTIONS PATCH LINK UNLINK]

    METHOD_OVERRIDE_PARAM_KEY = "_method"
    HTTP_METHOD_OVERRIDE_HEADER = "HTTP_X_HTTP_METHOD_OVERRIDE"
    ALLOWED_METHODS = %w[POST]

    def initialize(app)
      @app = app
    end

    def call(env)
      if allowed_methods.include?(env[REQUEST_METHOD])

        Jets.logger.info "Rack::MethodOverride called"
        env.keys.sort.each do |k|
          v = env[k]
          next unless v.is_a?(String)
          puts "#{k}: #{v}"
        end

        method = method_override(env)
        puts "method #{method}"
        puts "HTTP_METHODS.include?(method) #{HTTP_METHODS.include?(method)}"
        if HTTP_METHODS.include?(method)
          env[RACK_METHODOVERRIDE_ORIGINAL_METHOD] = env[REQUEST_METHOD]
          env[REQUEST_METHOD] = method
        end
      end

      @app.call(env)
    end

    def method_override(env)
      req = Request.new(env)
      method = method_override_param(req) ||
        env[HTTP_METHOD_OVERRIDE_HEADER]
      begin
        method.to_s.upcase
      rescue ArgumentError
        env[RACK_ERRORS].puts "Invalid string for method"
      end
    end

    private

    def allowed_methods
      ALLOWED_METHODS
    end

    def method_override_param(req)
      req.POST[METHOD_OVERRIDE_PARAM_KEY]
    rescue Utils::InvalidParameterError, Utils::ParameterTypeError
      req.get_header(RACK_ERRORS).puts "Invalid or incomplete POST params"
    rescue EOFError
      req.get_header(RACK_ERRORS).puts "Bad request content body"
    end
  end
end
