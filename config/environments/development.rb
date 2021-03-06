Tracker2::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  # config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false

  # Do care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

    # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = false

  # Bullet is used to detect N+1 queries and unused eager loading. This is being
  # commented now but may be re-enabled if we want this type of detection.
  #if defined? Bullet
  #  Bullet.enable = true
  #  Bullet.alert  = true
  #end

  # obsolete - using SupportMailer class
  # config.middleware.use ExceptionNotification::Rack,
  #   email: {
  #     sender_address: "error_log@21pstem.org",
  #     exception_recipients: "trackersupport@21pstem.org"
  #   }
  

  # Open emails to be sent in a new browser window.
  config.action_mailer.delivery_method = :letter_opener

  # run delayed jobs inline for development
  Delayed::Worker.delay_jobs = false

end

