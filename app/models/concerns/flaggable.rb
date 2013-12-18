module Flaggable
  extend ActiveSupport::Concern

  included do
    field :flags, type: Array, default: []
    validates :flags, array: { presence: true, format: { with: Utils::Slugger::SLUG_REGEX } } 
  end

  # Class Methods
  module ClassMethods
  end

  # Instance Methods
  def add_flag(fl)
    fl = Utils::Slugger.slugify(fl)
    self.flags_will_change!
    self.flags << fl unless self.has_flag?(fl)
    fl
  end
  
  def remove_flag(fl)
    fl = Utils::Slugger.slugify(fl)
    self.flags_will_change!
    self.flags.delete(fl)
    fl
  end
  
  def has_flag?(fl)
    fl = Utils::Slugger.slugify(fl)
    self.flags.include? fl
  end

  private
end