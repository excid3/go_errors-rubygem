module GoErrors
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      response = @app.call(env)
      exception_handler(env['action_dispatch.exception'], env) if env['action_dispatch.exception']
      response
    rescue Exception => ex
      exception_handler(ex, env)
      raise ex
    end

    def exception_handler(exception, env)
      payload = build_payload(exception, env)
      send_payload(payload)
    end

    def send_payload(payload)
      begin
        headers  = {"Content-Type" => "application/json", "Accept" => "application/json"}
        uri      = URI.parse("#{GoErrors.config.host}/api/v1/bugs")
        http     = Net::HTTP.new(uri.host, uri.port)
        response = http.post("#{uri.path}?api_token=#{GoErrors.config.api_token}", payload.to_json, headers)
      end
    end

    def build_payload(exception, env)
      request = ::Rack::Request.new(env)

      {
        class_name: exception.class.to_s,
        message: clean_message(exception.message),
        environment: Rails.env,
        backtrace: clean_backtrace(exception.backtrace),
        request: {
          method: request.request_method,
          params: request.env['action_dispatch.request.parameters'] || request.params,
          referer: request.referer,
          session: request.session.to_hash,
          cookies: request.cookies.to_hash,
          content_type: request.content_type,
          xhr: request.xhr?,
          user_agent: request.user_agent,
          host: request.host,
          port: request.port,
          ip: request.ip,
          url: request.url
        },
        user: user(env)
      }
    end

    def clean_backtrace(backtrace)
      backtrace.map do |line|
        match = /(?<file>.+):(?<line>\d+):in `(?<function>.+)'/.match(line)
        {
          file: match[:file],
          line: match[:line],
          function: match[:function]
        }
      end
    end

    def clean_message(message)
      # Strip out the suggestions like 'Did you mean @users?
      message.split("\n").first
    end

    def user(env)
      user = if env['warden']
               env['warden'].user(run_callbacks: false)
             else
               env['action_controller.instance'].try(:current_user)
             end

      return unless user.present?

      {
        id: user.id,
        email: user.try(:email),
        name: user.try(:name),
        first_name: user.try(:first_name),
        last_name: user.try(:last_name),
        username: user.try(:username)
      }
    end
  end
end
