module Myumbc3
  module Importer
    module GroupImporter
      
      API_URL = 'https://dev.my.umbc.edu/admin/export/groups.json'
      
      def self.reset
        Group.delete_all
      end
      
      def self.dump(id)
        ht = RestClient.post API_URL, key: UMBC_CONFIG[:myumbc3][:importer][:passkey], ids: id
        js = JSON.parse(ht.to_str, symbolize_names: true).first
        out = JSON.pretty_generate(js)
        
        output_file = File.new("tmp/group-#{js[:id]}.json", 'w')
        output_file << out
        output_file.close
      end
    
      @entity_cache = {}
    
      def self.entity_cache(my3_id)
        if !@entity_cache[my3_id]
          #puts "Loading #{my3_id}"
          begin
            @entity_cache[my3_id] = Entity.find_by_slug(my3_id)
          rescue
            nil
          end
        end
        @entity_cache[my3_id]
      end
      
      def self.setup_topic_groups
        topics = {
          admissions_and_orientation: "Admissions & Orientation",
          advising_and_student_support: "Advising & Student Support",
          arts_culture_and_entertainment: "Arts, Culture & Entertainment",
          athletics_and_recreation: "Athletics & Recreation",
          billing_and_personal_finances: "Billing & Personal Finances",
          books_goods_and_services: "Books, Goods & Services",
          classes_and_grades: "Classes & Grades",
          community_news_and_opinion: "Community News & Opinion",
          computing_and_technology: "Computing & Technology",
          diversity: "Diversity",
          facilities_and_operations: "Facilities & Operations",
          financial_services_and_accounting: "Financial Services & Accounting",
          food_and_dining: "Food & Dining",
          health_wellness_and_safety: "Health, Wellness & Safety",
          housing_on_and_off_campus: "Housing (On & Off Campus)",
          human_resources: "Human Resources",
          involvement_and_leadership: "Involvement & Leadership",
          jobs_and_internships: "Jobs & Internships",
          library: "Library",
          myumbc: "myUMBC",
          parking_and_transportation: "Parking & Transportation",
          professional_development: "Professional Development",
          research_and_grants: "Research & Grants",
          teaching_and_learning: "Teaching & Learning"
        }
        
        topics.keys.each do |topic|
          new_group = Group.new
          new_group.status = :active
          new_group.slug = "my3-topic-#{topic}"
          new_group.name = "#{topics[topic]}"
          new_group.description = "An archive of posts made in past version of myUMBC"
          new_group.created_at = Time.zone.now
          new_group.kind = :legacy
          new_group.access = :public
          
          
          
          c = new_group.categories.add('News', format: :list, posting: :members)
          c.slugs.add 'my3-news'
          
          c = new_group.categories.add('Discussions', format: :forum, posting: :members)
          c.slugs.add 'my3-discussions'
          
          c = new_group.categories.add('Media', format: :gallery, posting: :members)
          c.slugs.add 'my3-media'
          
          c = new_group.categories.add('Spotlights Archive', format: :list, posting: :members)
          c.slugs.add 'my3-spotlights'
          
          new_group.categories.remove(new_group.categories.first)
          
          #new_group.events.posting = :members
          #new_group.events.slugs.add 'my3-events'
          
          #new_group.library.posting = :members
          
          new_group.show_members = :admins
          
          new_group.save!
          Rails.logger.info "Topic: #{new_group.slug} added..." 
        end
      end
    
      def self.import(output_file)
        start = Group.count
        
        page_size = 100
        page_number = (start / page_size)
        puts "#{start} existing... starting on page number #{page_number}"
        total_import_count = 0

        if start == 0
          self.setup_topic_groups
        end
          
        begin
          Rails.logger.info "Batch #{page_number}: Requesting #{page_size} groups from my3..."
          
          ht = RestClient.post API_URL, key: UMBC_CONFIG[:myumbc3][:importer][:passkey], page: page_number, page_size: page_size
          group_data = JSON.parse(ht.to_str, symbolize_names: true)
          
          Rails.logger.info "Batch #{page_number}: Parsing #{group_data.length} returned groups..."
      
          batch_import_count = 0

          group_data.each do |old_group|
            next if Group.where(slugs: "my3-group-#{old_group[:id]}").first
            new_group = Group.new
            
            # Status
            if old_group[:kind] == 'retired'
              new_group.status = :retired
            elsif old_group[:status] == 'active'
              new_group.status = :active
            elsif (old_group[:status] == 'inactive') && (old_group[:token].match(/denied/))
              new_group.status = :denied
            elsif old_group[:status] == 'pending'
              new_group.status = :pending
            else
              raise "Unknown status, for #{old_group[:token]}:#{old_group[:id]} -- #{old_group[:status]}"
            end
            
            # Slug
            new_group.slugs.add "my3-group-#{old_group[:id]}"
            if old_group[:kind] == 'retired'
              # no slug
            elsif new_group.status == :active
              new_group.slug = old_group[:token]
            end
            
            new_group.name = old_group[:name]
            new_group.tagline = Utils::Text.to_plain_text(old_group[:tagline])
            new_group.description = old_group[:description]
            new_group.analytics_id = old_group[:google_analytics_id]
            
            if old_group[:avatar].present? && old_group[:avatar][:urls].present? && old_group[:avatar][:urls][:xxxlarge].present?
              new_group.avatar_url = "http://my.umbc.edu" + old_group[:avatar][:urls][:xxxlarge].to_s
            end
            
            if old_group[:header].present? && old_group[:header][:urls].present? && old_group[:header][:urls][:original].present?
              new_group.header_url = "http://my.umbc.edu" + old_group[:header][:urls][:original].to_s
            end
            
            
            
            # Creation
            new_group.created_at = old_group[:created_at]
            new_group.created_by = Entity.get("my3-user-#{old_group[:created_by_id]}")
            
            # Kind
            new_group.kind = (old_group[:kind] == 'retired') ? :legacy : old_group[:kind].to_sym
            # TODO Map these to new kinds?
            
            # Access
            public = old_group[:public] == true
            open = old_group[:membership] == 'open'

            if public
              new_group.access = :public #new_group.visbility.add('public')
            end
            
            #####
            # Tools -> Categories
            
            default_cat = new_group.categories.first
            
            any_anyone_tools = false
            any_member_tools = false
            
            old_group[:group_tools].sort_by { |t| t[:position] }.each do |tool|
              
              if tool[:write_access] == 'admin'
                posting = :admins
              elsif !public
                posting = :members
                any_member_tools = true
              elsif open && (tool[:write_access] == 'member')
                posting = :anyone
                any_anyone_tools = true
              elsif public && !open
                posting = :members
                any_member_tools = true
              else
                puts old_group[:token]
                raise "Unknown posting scenario"
              end
              
              # if public && (tool[:read_access] != 'anyone')
              #   raise "Take a look at group #{old_group[:token]}:#{old_group[:id]} for tools"
              # end
              
              # Remove the initial 
              
              case tool[:kind]
              when 'home'
                # Ignore
              when 'news'
                #next if tool[:count] == 0
                if (tool[:count] > 0)
                  c = new_group.categories.add('News', format: :list, posting: posting)
                  c.slugs.add 'my3-news'
                  if default_cat
                    new_group.categories.remove(default_cat)
                    default_cat = nil
                  end
                end
                #new_group..posting = (posting == :admins) ? posting : :members
              when 'events'
                #new_group.events.slugs.add 'my3-events'
                #new_group.events.posting = posting
              when 'discussions'
                #next if tool[:count] == 0
                if (tool[:count] > 0)
                  c = new_group.categories.add('Discussions', format: :forum, posting: posting)
                  c.slugs.add 'my3-discussions'
                  if default_cat
                    new_group.categories.remove(default_cat)
                    default_cat = nil
                  end
                end
              when 'media'
                #next if tool[:count] == 0
                if (tool[:count] > 0)
                  c = new_group.categories.add('Media', format: :gallery, posting: posting)                  
                  c.slugs.add 'my3-media'
                  if default_cat
                    new_group.categories.remove(default_cat)
                    default_cat = nil
                  end
                end
              when 'documents'
                #new_group.library.posting = (posting == :admins) ? posting : :members
                #new_group.library.slugs.add 'my3-documents'
              when 'members'
                if tool[:read_access] == 'anyone'
                  new_group.show_members = :anyone
                else
                  new_group.show_members = :members
                end
              when 'settings'
                # Ignore
              when 'spotlights'
                next if tool[:count] == 0
                c = new_group.categories.add('Spotlight Archive', format: :list, posting: posting)
                c.slugs.add 'my3-spotlights'
              when 'statuses'
                # Ignore
              end
            end
            
            # Documents
            old_group[:group_document_folders].each do |f|
              #f = new_group.library.folders.add(f[:title])
              #f.slugs.add "my3-documents-#{f[:id]}"
            end
            
            
            
            # Group Memberships
            member_slugs = old_group[:group_members].map{ |gm| "my3-user-#{gm[:user_id]}" }
            member_entities = Entity.in(slugs: member_slugs)
            
            es = {}
            member_entities.each do |me|
              me.slugs.each do |s|
                es[s] = me
              end
            end
            
            #puts "Merging..."
            @entity_cache ||= {}          
            @entity_cache = @entity_cache.merge(es)
            #puts @entity_cache
            #return
            
            old_group[:group_members].each do |gm|
              e = self.entity_cache("my3-user-#{gm[:user_id]}")
              #e = es["my3-user-#{gm[:user_id]}"]
              
              if e.present?
                nots = (gm[:watching] ? 'important' : 'none')
              
                if gm[:status] == 'invited'
                  
                  #new_gm = GroupInvitation.new
                  #new_gm.entity_id = e.id
                  #new_gm.created_at = gm[:invited_at]
                  creator = self.entity_cache("my3-user-#{gm[:invited_by_id]}")
                  raise "Could not find creator: #{gm[:invited_by_id]}" if creator.nil?
                  #new_gm.created_by_id = creator.id
                  
                  new_group.invitations.add(e, { created_at: gm[:invited_at], created_by: creator })
                else
                  case gm[:role]
                  when 'owner', 'admin', 'member'
                    #is_admin = ((gm[:role] == 'owner') || (gm[:role] == 'admin'))
                    #new_gm = GroupMembership.new
                    #new_gm.entity_id = e.id
                    #new_gm.notifications = nots
                    #new_gm.admin = ((gm[:role] == 'owner') || (gm[:role] == 'admin'))
                    #new_gm.locked = gm[:auto]
                    #new_gm.title = gm[:custom_title]
                    #new_gm.email = gm[:custom_email]
                    #new_gm.created_at = gm[:joined_at]
                    creator = self.entity_cache("my3-user-#{gm[:joined_by_id]}")
                    raise "Could not find creator: #{gm[:joined_by_id]}" if creator.nil?
                    #new_gm.created_by_id = creator.id
                    
                    if (gm[:role] == 'member') && (gm[:auto] == false) && (gm[:officer] == false) && open && (any_anyone_tools || !any_member_tools) && (gm[:invited_by_id] == gm[:user_id])
                      new_group.followerships.add(e, { notifications: nots, created_at: gm[:joined_at], created_by: e })
                    else
                      new_group.memberships.add(e, { created_at: gm[:joined_at], notifications: nots, admin: ((gm[:role] == 'owner') || (gm[:role] == 'admin')), locked: (gm[:auto] == true), officer: (gm[:officer] == true), title: gm[:title], email: gm[:email], created_by: creator})
                    end
                    #if ((gm[:role] == 'owner') || (gm[:role] == 'admin')) || !any_open_tools
                      
                      #else
                      #new_group.followerships.add(e, { notifications: nots, created_at: gm[:joined_at], created_by: e })
                      #end
                    
                  when 'follower'
                    #new_gm = GroupFollowership.new
                    #new_gm.entity_id = e.id
                    #new_gm.notifications = nots
                    #new_gm.created_at = gm[:joined_at]
                    #new_gm.created_by_id = e.id
                    new_group.followerships.add(e, { notifications: nots, created_at: gm[:joined_at], created_by: e })
                  end
                end
                
                #if new_gm && !new_gm.valid?
                #  raise "#{new_gm.errors.messages}"
                #  raise "BAD: Group: #{old_group[:id]}, Entity: #{gm[:user_id]} / #{gm[:role]}"
                #end
                
                #new_group.group_relationships << new_gm
              end
            end
            
            #ap old_group
            #puts "#{new_group.name}"
            new_group.save!
            
            # Force the slug to the id (but can only do after save)
            if (old_group[:kind] == 'retired') || (new_group.status != :active)
             new_group.slug = new_group.id
             new_group.save!
            end
            
            batch_import_count += 1
            total_import_count += 1
            putc '.'
          end 

          Rails.logger.info "Batch #{page_number}: Added #{batch_import_count} groups... TOTAL: #{total_import_count}"
          page_number += 1
          
        end while group_data.present?
        
        Rails.logger.info "IMPORTED: #{total_import_count} groups."
      end  
    end
  end
end