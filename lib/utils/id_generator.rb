module Utils
  class IdGenerator
    #ID_START_CHARS = %w(0 1 2 3 4 5 6 7 8 9)
    ID_CHARS = %w(0 1 2 3 4 5 6 7 8 9 a b c d e f g h j k m n o p q r s t u v w x y z)

    def self.is_id?(id)
      false
    end

    def self.generate(len = 10)
      Array.new(len).map { ID_CHARS[SecureRandom.random_number(ID_CHARS.length)] }.join
    end
  end
end