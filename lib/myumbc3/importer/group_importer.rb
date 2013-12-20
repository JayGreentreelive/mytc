module Myumbc3
  module Importer
    module GroupImporter
      
      API_URL = 'https://my.umbc.edu/admin/export/groups.json'
      
      def self.reset
        Group.delete_all
      end
      
      def self.dump(id)
        ht = RestClient.post API_URL, key: UMBC_CONFIG[:myumbc3][:importer][:passkey], ids: id
        js = JSON.parse(ht.to_str, symbolize_names: true).first
        out = JSON.pretty_generate(js)
        
        output_file = File.new("group-#{js[:id]}.json", 'w')
        output_file << out
        output_file.close
      end
    
      @entity_cache = {}
    
      def self.entity_cache(my3_id)
        if !@entity_cache[my3_id]
          @entity_cache[my3_id] = Entity.find_by_slug(my3_id)
        end
        @entity_cache[my3_id]
      end
    
      def self.import(output_file)
        self.reset
        page_number = 1
        page_size = 10
        total_import_count = 0
          
        begin
          Rails.logger.info "Batch #{page_number}: Requesting #{page_size} groups from my3..."
          
          ht = RestClient.post API_URL, key: UMBC_CONFIG[:myumbc3][:importer][:passkey], page: page_number, page_size: page_size
          group_data = JSON.parse(ht.to_str, symbolize_names: true)
          
          Rails.logger.info "Batch #{page_number}: Parsing #{group_data.length} returned groups..."
      
          batch_import_count = 0

          group_data.each do |old_group|
            new_group = Group.new
            new_group.add_slug "my3-group-#{old_group[:id]}"
            new_group.add_slug old_group[:token]
            new_group.slug = old_group[:token]
            new_group.name = old_group[:name]
            new_group.tagline = Utils::Text.to_plain_text(old_group[:tagline])
            new_group.description = Utils::Text.to_plain_text(old_group[:description])
            
            #new_group.kind = (old_group[:kind] == 'retired') ? 'institutional' : old_group[:kind]
            
            #new_group.show_in_directory = old_group[:show_in_directory]
            new_group.created_at = old_group[:created_at]
            new_group.analytics_id = old_group[:google_analytics_id]
            
            old_group[:group_members].each do |gm|
              e = self.entity_cache("my3-user-#{gm[:user_id]}")
              
              if e.present?
                nots = (gm[:watching] ? 'important' : 'none')
              
                if gm[:status] == 'invited'
                  new_gm = GroupInvitation.new
                  new_gm.entity_id = e.id
                  new_gm.created_at = gm[:invited_at]
                  creator = self.entity_cache("my3-user-#{gm[:invited_by_id]}")
                  raise "Could not find creator: #{gm[:invited_by_id]}" if creator.nil?
                  new_gm.created_by_id = creator.id
                else
                  case gm[:role]
                  when 'owner', 'admin', 'member'
                    #is_admin = ((gm[:role] == 'owner') || (gm[:role] == 'admin'))
                    new_gm = GroupMembership.new
                    new_gm.entity_id = e.id
                    new_gm.notifications = nots
                    new_gm.admin = ((gm[:role] == 'owner') || (gm[:role] == 'admin'))
                    new_gm.locked = gm[:auto]
                    new_gm.title = gm[:custom_title]
                    new_gm.email = gm[:custom_email]
                    new_gm.created_at = gm[:joined_at]
                    creator = self.entity_cache("my3-user-#{gm[:joined_by_id]}")
                    raise "Could not find creator: #{gm[:joined_by_id]}" if creator.nil?
                    new_gm.created_by_id = creator.id
                  when 'follower'
                    new_gm = GroupFollowership.new
                    new_gm.entity_id = e.id
                    new_gm.notifications = nots
                    new_gm.created_at = gm[:joined_at]
                    new_gm.created_by_id = e.id
                  end
                end
                
                if new_gm && !new_gm.valid?
                  raise "#{new_gm.errors.messages}"
                  raise "BAD: Group: #{old_group[:id]}, Entity: #{gm[:user_id]} / #{gm[:role]}"
                end
                
                new_group.group_relationships << new_gm
              end
            end
            
            #ap old_group
            puts "#{new_group.name}"
            new_group.save!
            
            batch_import_count += 1
            total_import_count += 1
          end 

          Rails.logger.info "Batch #{page_number}: Added #{batch_import_count} groups... TOTAL: #{total_import_count}"
          page_number += 1
          
        end while group_data.present?
        
        Rails.logger.info "IMPORTED: #{total_import_count} groups."
      end  
    end
  end
end