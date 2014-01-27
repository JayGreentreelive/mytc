module Myumbc3
  module Importer
    module UserImporter
      
      API_URL = 'https://my.umbc.edu/admin/export/users.json'
      
      def self.reset
        UmbcPerson.delete_all
      end
    
      def self.import(output_file)
        use_ldap = true
        page_number = 1
        page_size = 1000
        total_import_count = 0
          
        begin
          Rails.logger.info "Batch #{page_number}: Requesting #{page_size} users from my3..."
          
          ht = RestClient.post API_URL, key: UMBC_CONFIG[:myumbc3][:importer][:passkey], page: page_number, page_size: page_size
          user_data = JSON.parse(ht.to_str, symbolize_names: true)
          
          Rails.logger.info "Batch #{page_number}: Parsing #{user_data.length} returned users..."
      
          batch_import_count = 0
        
          Umbc::Ldap.batch do |ldap|          
            user_data.each do |user|
          
              if user[:eppn].match(/@umbc.edu/)
                if use_ldap
                  ldap_user = ldap.find_people(any_campus_id: user[:campus_id]).first
                else
                  ldap_user = {
                    eppn: user[:eppn],
                    name: user[:display_name],
                    first_name: user[:first_name],
                    last_name: user[:last_name],
                    display_email: user[:display_email] || user[:contact_email],
                    contact_email: user[:contact_email],
                    emails: user[:emails],
                    umbc_campus_id: user[:campus_id],
                    umbc_username: user[:username] 
                  }
                end

                if ldap_user.present?                
                  person = UmbcPerson.find_or_setup(user[:eppn], ldap_user)
                  person.slugs.add "my3-user-#{user[:id]}"
                  person.last_login_at = Time.zone.parse(user[:logged_in_at]) if user[:logged_in_at].present?
                
                  # Favorites
                  user[:favorites].each { |f| person.add_favorite(HTMLEntities.new.decode(f[:name]), f[:url]) }
                
                  # Settings
                  user[:settings].each do |s|
                    case s[:token]
                    when 'background-color', 'hide-role-switcher', 'notify-by-email-frequency', 'desparkle', 'use-lite-version'
                      #puts "Ignoring #{s[:token]}: #{s[:value]}"
                    when 'allow-cma-contact'
                      person.settings.allow_bb_cma_contact = (s[:value] == 'true')
                    when 'nyan-cursor'
                      person.settings.enable_nyan_cursor = (s[:value] == 'yes')
                    else
                      raise "ERROR: Unknown settings: #{s[:token]} = #{s[:value]}"
                    end
                  end
                  
                  # TODO: Privileges
                  user[:privileges].each do |s|
                    person.flags.add(s[:token])
                    # case s[:token]
#                     when 'admin'
#                       puts "admin!"
#                     when 'admin-links'
#                       # do nothing
#                     else
#                       raise "ERROR: Unknown privilege: #{s[:token]}"
#                     end
                  end
                  
                  
                  # TODO: Avatar
                
                  person.save!
                else
                  output_file.write "EPPN not found: #{user[:eppn]}\n"
                end
                batch_import_count += 1
                total_import_count += 1
                putc '.'
              
              else # if user[:eppn].match(/@umbc.edu/)
                output_file.write "NOT IMPORTING: #{user[:eppn]}\n"
                Rails.logger.error "NOT IMPORTING: #{user[:eppn]}"
              end
            end
            Rails.logger.info "Batch #{page_number}: Added #{batch_import_count} users... TOTAL: #{total_import_count}"
            page_number += 1
          end
        end while user_data.present?
        Rails.logger.info "IMPORTED: #{total_import_count} people."
        #return errors, bad_ids
      end  
    end
  end
end