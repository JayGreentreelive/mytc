Myumbc4::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = true

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log


  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true
  
  # Set logging level to DEBUG, gotta love the logs
  config.log_level = :debug
  config.log_formatter = proc do |sev, ts, prog, msg|
    # Colors from here: http://misc.flogisoft.com/bash/tip_colors_and_formatting
    color = {'DEBUG'=>'243', 'INFO'=>'39', 'WARN'=>'208', 'ERROR'=>'196', 'FATAL'=>'165', 'UNKNOWN'=>'255'}[sev]
    log = "\033[38;5;#{color}m#{ts.strftime("%H:%M:%S")} #{sev.rjust(5)} : #{msg}\033[0m\n"
    
    if log.match(/MOPED:/)
      if log.match(/ QUERY /)
        log.gsub!(/ QUERY /, " \033[38;5;24mQUERY \033[38;5;#{color}m")
        log.gsub!(/selector=(\{.*\})/, "selector=\033[38;5;24m\\1\033[38;5;#{color}m")
      end
      if log.match(/ INSERT /)
        log.gsub!(/ INSERT /, " \033[38;5;64mINSERT \033[38;5;#{color}m")
        log.gsub!(/documents=(\[.*\]) /, "documents=\033[38;5;64m\\1\033[38;5;#{color}m ")
      end
      if log.match(/ UPDATE /)
        log.gsub!(/ UPDATE /, " \033[38;5;64mUPDATE \033[38;5;#{color}m")
        log.gsub!(/selector=(\{.*\}) update=(\{.*\})/, "selector=\033[38;5;24m\\1\033[38;5;#{color}m update=\033[38;5;64m\\2\033[38;5;#{color}m ")
      end
      if log.match(/ DELETE /)
        log.gsub!(/ DELETE /, " \033[38;5;196mDELETE \033[38;5;#{color}m")
        log.gsub!(/selector=(\{.*\})/, "selector=\033[38;5;196m\\1\033[38;5;#{color}m")
      end
      if log.match(/ COMMAND /)
        log.gsub!(/ COMMAND /, " \033[38;5;196mCOMMAND \033[38;5;#{color}m")
        log.gsub!(/command=(\{.*\})/, "command=\033[38;5;196m\\1\033[38;5;#{color}m")
      end
    end
    log.gsub!(/runtime: ([0-9\.ms]+)/, " runtime: \033[38;5;88m\\1\033[38;5;#{color}m\\2")
    
    log
  end  
  
  # Mongoid Configuration
  Mongoid.logger.level = Logger::DEBUG
  Mongoid.logger.formatter = config.log_formatter
  Moped.logger.level = Logger::DEBUG
  Moped.logger.formatter = config.log_formatter
end
