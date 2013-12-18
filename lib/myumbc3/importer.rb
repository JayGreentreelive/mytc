require 'awesome_print'
require 'myumbc3/importer/user_importer'

module Myumbc3
  module Importer
    
    def self.reset
      UserImporter.reset
    end
    
    def self.import
      Rails.logger = Logger.new(STDOUT)
      Rails.logger.level = Logger::INFO
      Mongoid.logger.level = Logger::INFO
      Moped.logger.level = Logger::INFO
      
      output_file = File.new('importer.out', 'w')
      
      UserImporter.import(output_file)
      
      output_file.close
      
    end
  end  
end