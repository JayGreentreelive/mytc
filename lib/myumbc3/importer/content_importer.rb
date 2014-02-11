module Myumbc3
  module Importer
    module ContentImporter
      
      API_BASE = 'https://dev.my.umbc.edu/admin/export'
      
      def self.reset
        Post.delete_all
      end
      
      def self.news_dump(id)
        ht = RestClient.post API_BASE + '/news.json', key: UMBC_CONFIG[:myumbc3][:importer][:passkey], ids: id
        js = JSON.parse(ht.to_str, symbolize_names: true).first
        out = JSON.pretty_generate(js)
        
        output_file = File.new("tmp/news-#{js[:id]}.json", 'w')
        output_file << out
        output_file.close
      end
    
      @entity_cache = {}
    
      def self.entity_cache(my3_id)
        if !@entity_cache[my3_id]
          puts "Loading #{my3_id}"
          @entity_cache[my3_id] = Entity.find_by_slug(my3_id)
          
          if !@entity_cache[my3_id]
            @entity_cache[my3_id] = entity_cache('unknown')
          end
        end
        @entity_cache[my3_id]
      end

      def self.import(output_file)
        self.reset
        self.import_content(:news, output_file)
        self.import_content(:discussions, output_file)
        self.import_content(:media, output_file)
        self.import_content(:spotlights, output_file)
        #self.import_content(:events, output_file)
      end
    
    
      def self.import_content(content_type, output_file)
        page_number = 1
        page_size = 1000
        total_import_count = 0
        
        begin
          batch_import_count = 0
          
          Rails.logger.info "Batch #{page_number}: Requesting #{page_size} content of type '#{content_type}' from my3..."
          
          # Retrieve the JSON fom myUMBC
          ht = RestClient.post (API_BASE + "/#{content_type}.json"), key: UMBC_CONFIG[:myumbc3][:importer][:passkey], page: page_number, page_size: page_size
          content_data = JSON.parse(ht.to_str, symbolize_names: true)
          
          Rails.logger.info "Batch #{page_number}: Parsing #{content_data.length} retreieved items..."
          
          content_data.each do |old_content|
            # Ignore things that aren't posted, unless they're comments
            next if (old_content[:status] != 'posted') && (content_type != :comments)
            
            # Ignore if already imported
            next if Node.where(slugs: "my3-#{content_type}-#{old_content[:id]}").first
            
            new_post = Post.new
            
            # Get the owning group, or pick the topic if it was public
            if old_content[:group_id]
              owner = entity_cache("my3-group-#{old_content[:group_id]}")
            else
              owner = Group.get("my3-topic-#{old_content[:topics].first[:token]}")
            end

            # Basics
            new_post.title = old_content[:title]
            new_post.tagline = old_content[:tagline]
            new_post.body = old_content[:body]
            new_post.owner = owner
            new_post.author = entity_cache("my3-user-#{old_content[:created_by_id]}")
            new_post.slugs.add("my3-#{content_type}-#{old_content[:id]}")
            
            if old_content[:thumbnail].present? && old_content[:thumbnail][:urls].present? && old_content[:thumbnail][:urls][:xxxlarge].present?
              new_post.cover_url = "http://my.umbc.edu" + old_content[:thumbnail][:urls][:xxxlarge].to_s
            end
          
            # Access
            if new_post.owner.access == :private
              new_post.access = :private
            elsif old_content[:group_tool][:read_access] == 'member'
              new_post.access = :private
            else
              new_post.access = :public
            end
            
            # Tags
            old_tags = old_content[:tags].map { |t| t[:token] }
            old_topics = old_content[:topics].map { |t| t[:name] }
            new_post.tags = [old_tags].flatten + [old_topics].flatten + ["my3-import-#{content_type}"]
            
            # Postings
            p = new_post.postings.build
            p.target = new_post.owner
            p.by = new_post.author
            p.at = old_content[:posted_at]

            begin
              p.container_id = p.target.categories.find_by_slug("my3-#{content_type}").try(:id)
            rescue
              puts "ERROR: #{p.target.slug} does not have 'my3-#{content_type}' to hold #{old_content[:id]} - #{new_post.title}"
            end
            
            # Cross post into the categories of the my3 legacy group
            if old_content[:public] && (new_post.access == :public)
              old_content[:topics].each do |topic|
                xowner = Group.get("my3-topic-#{topic[:token]}")
                if xowner != new_post.owner
                  p = new_post.postings.build
                  p.target = xowner
                  p.by = new_post.author
                  p.at = old_content[:posted_at]
                  p.container_id = p.target.categories.find_by_slug("my3-#{content_type}").try(:id)
                end
              end
            end
            
            new_post.save!
            batch_import_count += 1
            total_import_count += 1
            putc '.'
          end
          
          Rails.logger.info "Batch #{page_number}: Added #{batch_import_count} posts... TOTAL: #{total_import_count}"
          page_number += 1
          
        end while content_data.present?
        
        Rails.logger.info "IMPORTED: #{total_import_count} posts."
      end
    end
  end
end