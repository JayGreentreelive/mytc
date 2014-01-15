module Flaggable
  extend ActiveSupport::Concern

  included do
    field :flags, type: Array, default: []
    validates :flags, array: { presence: true, format: { with: Utils::Slugger::SLUG_REGEX } } 
  end

  # Instance Methods  
  def flags=(fl)
    Utils::SlugCollection.new(self, :flags).set(fl)
  end
  
  def flags
    Utils::SlugCollection.new(self, :flags)
  end
end