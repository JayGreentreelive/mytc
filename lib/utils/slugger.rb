module Utils
  class Slugger

    SLUG_REGEX = /\A([a-z0-9-]+)\z/
    SLUG_SEPARATOR = '-'

    def self.valid?(obj)
      obj.present? && obj.match(SLUG_REGEX)
    end

    def self.slugify(obj, sep = SLUG_SEPARATOR)
      if obj.blank?
        return sep
      end

      if obj.respond_to? :slug
        return obj.slug
      end

      if obj.respond_to? :to_s
        obj = obj.to_s
      end

      # replace accented chars with ther ascii equivalents
      slugified_string = ActiveSupport::Inflector.transliterate(obj) #::Iconv.iconv('ascii//ignore//translit', 'utf-8', obj).to_s #transliterate(self)

      # replacments for words/punctuation
      slugified_string.gsub!(/[\&]/i, ' and ')
      slugified_string.gsub!(/[\@]/i, ' at ')
      slugified_string.gsub!(/[\']/i, '')

      # Turn unwanted chars into the seperator
      slugified_string.gsub!(/[^a-z0-9\-]+/i, sep)

      re_sep = Regexp.escape(sep)

      # No more than one of the separator in a row.
      slugified_string.gsub!(/#{re_sep}{2,}/, sep)

      # Chop the string to 64 characters
      #slugified_string = tokenized_string[0..63]

      # Remove leading/trailing separator.
      slugified_string.gsub!(/^#{re_sep}|#{re_sep}$/i, '')

      # lowercase and strip the token
      slugified_string.downcase.strip
    end
  end
end
