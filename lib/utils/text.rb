module Utils
  class Text
    # def self.sanitize_html(str)
#       Nokogiri::HTML(str).text
#     end
    
    def self.to_plain_text(str)
      #document = Nokogiri::HTML.parse(str)
      
      document = Nokogiri::HTML(str) do |config|
        config.noblanks.nonet.recover
      end
      
      
      document.xpath('//comment()').remove
      document.xpath('style').remove
      document.xpath('script').remove
      document.css("br").each { |node| node.replace("\n") }
      document.css("div").each { |node| node.replace("\n") }
      document.css("p").each { |node| node.after("\n\n") }
      document.text
    end
    
    def self.strip_tags(str)
      Nokogiri::HTML(str).text
    end
  end
end