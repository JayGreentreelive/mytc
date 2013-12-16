require 'awesome_print'

module Myumbc3
  module Importer
    
    def self.reset
      self.reset_users
    end
    
    def self.import
      Rails.logger = Logger.new(STDOUT)
      Rails.logger.level = Logger::INFO
      Mongoid.logger.level = Logger::INFO
      Moped.logger.level = Logger::INFO
      
      errors, bad_ids = self.import_users
      puts "ERRORS"
      puts errors
      puts "BAD USERS"
      puts bad_ids.join(' ')
    end
    
    def self.reset_users
      UmbcPerson.delete_all
    end
    
    def self.import_users
      page_number = 1
      page_size = 100
      import_count = 0
      
      bad_ids = []
      errors = []
      
      begin
        Rails.logger.info "Batch #{page_number}: Requesting #{page_size} users from my3..."
        ht = RestClient.post 'https://my.umbc.edu/admin/export/users.json', key: UMBC_CONFIG[:myumbc3][:importer][:passkey], page: page_number, page_size: page_size
        user_data = JSON.parse(ht.to_str, symbolize_names: true)
        Rails.logger.info "Batch #{page_number}: Parsing #{user_data.length} returned users..."
      
        batch_size = 0
        
        Umbc::Ldap.batch do |ldap|
          
          #campus_ids = user_data.map { |u| u[:campus_id] }.compact.uniq
          #return
          
          #ldap_users = ldap.find_people(any_campus_id: user_data.map { |u| u[:campus_id] }.compact.uniq).index_by(&:campus_id)
          #puts ldap_users
          #return
          
          user_data.each do |user|
          
            if user[:eppn].match(/@umbc.edu/)
              #ldap_user = ldap_users[user[:campus_id]] 
              ldap_user = ldap.find_people(any_campus_id: user[:campus_id]).first

              if ldap_user.blank?
                bad_ids << user[:campus_id]
                errors << "No longer in LDAP, but was in myUMBC 3: #{user[:campus_id]}"
                Rails.logger.error "BAD CAMPUS ID: #{user[:campus_id]}"
              else
                
                person = UmbcPerson.find_or_setup(ldap_user.eppn, ldap_user)
                person.add_slug "my3-user-#{user[:id]}"
                person.last_login_at = Time.zone.parse(user[:logged_in_at]) if user[:logged_in_at].present?
                
                # Favorites
                user[:favorites].each { |f| person.add_favorite(HTMLEntities.new.decode(f[:name]), f[:url]) }
                
                # Settings
                # TODO
                
                # Privileges
                # TODO
                
                # Avatar
                # TODO
                
                person.save!
              end
              import_count += 1
              batch_size += 1
              putc '.'
            else
              errors << "NOT IMPORTING: #{user[:eppn]}"
            end
          end
          puts "\n"
          Rails.logger.info "Batch #{page_number}: Added #{batch_size} users... TOTAL: #{import_count}"
          page_number += 1
        end
      end while user_data.present?
      Rails.logger.info "IMPORTED: #{import_count} people."
      return errors, bad_ids
    end  
  end
  
end