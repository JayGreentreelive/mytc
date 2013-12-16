module Utils
  class IdGenerator
    extend ActionView::Helpers::NumberHelper

    #ID_START_CHARS = %w(0 1 2 3 4 5 6 7 8 9)
    ID_CHARS = %w(0 1 2 3 4 5 6 7 8 9 a b c d e f g h j k m n o p q r s t u v w x y z)

    def self.is_id?(id)
      false
    end

    def self.generate(len = 10)
      new_id = [] #[ID_START_CHARS[SecureRandom.random_number(ID_START_CHARS.length)]]
      new_id += Array.new(len).map { ID_CHARS[SecureRandom.random_number(ID_CHARS.length)] }
      new_id.join
    end
  end
end