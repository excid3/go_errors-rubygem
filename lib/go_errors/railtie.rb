module GoErrors
  class Railtie < ::Rails::Railtie
    initializer('go_errors.middleware') do |app|
      if ::Rails.version.start_with?('5.')
        app.config.middleware.insert_after(ActionDispatch::DebugExceptions, GoErrors::Middleware)
      else
        app.config.middleware.insert_after(ActionDispatch::DebugExceptions, 'GoErrors::Middleware')
      end
    end
  end
end
