require 'awesome_print'
require 'myumbc3/importer/user_importer'
require 'myumbc3/importer/group_importer'

module Myumbc3
  module Importer
    
    def self.reset
      UserImporter.reset
      GroupImporter.reset
    end
    
    def self.import
      Rails.logger = Logger.new(STDOUT)
      Rails.logger.formatter = proc do |sev, ts, prog, msg|
        "#{ts.strftime("%H:%M:%S")} #{sev.rjust(5)} : #{msg}\n"
      end
      Mongoid.logger = Logger.new(STDOUT)
      Mongoid.logger.formatter = proc do |sev, ts, prog, msg|
        "#{ts.strftime("%H:%M:%S")} #{sev.rjust(6)} : #{msg}\n"
      end
      Moped.logger = Logger.new(STDOUT)
      Moped.logger.formatter = proc do |sev, ts, prog, msg|
        "#{ts.strftime("%H:%M:%S")} #{sev.rjust(6)} : #{msg}\n"
      end
      
      Rails.logger.level = Logger::INFO
      Mongoid.logger.level = Logger::INFO
      Moped.logger.level = Logger::INFO
      
      output_file = File.new('tmp/importer.out', 'w')
      
      UserImporter.import(output_file)
      GroupImporter.import(output_file)
      
      output_file.close
      
    end
  end  
end