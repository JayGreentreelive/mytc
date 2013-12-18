module Sluggable
  extend ActiveSupport::Concern

  included do
    field :slugs, type: Array, default: []
    field :display_slug, type: String
    
    index({ slugs: 1, _type: 1 }, { unique: true, sparse: true })
    
    validates :slugs, array: { presence: true, format: { with: Utils::Slugger::SLUG_REGEX } }
    validates :display_slug, allow_nil: true, format: { with: Utils::Slugger::SLUG_REGEX }

    before_save :ensure_id_in_slugs
  end

  # Class Methods
  module ClassMethods
    def get(sl)
      self.find_by_slug(sl)
    end

    def find_by_slug(sl)
      sl = Utils::Slugger.slugify(sl)
      self.in(slugs: sl).first
    end
  end

  # Instance Methods
  def slug
    self.display_slug || self.slugs.first
  end

  def slug=(sl)
    self.display_slug = self.add_slug(sl)
  end

  def add_slug(sl)
    sl = Utils::Slugger.slugify(sl)
    if !self.has_slug?(sl)
      self.slugs_will_change!
      self.slugs << sl 
    end
    sl
  end
  
  def has_slug?(sl)
    sl = Utils::Slugger.slugify(sl)
    self.slugs.include?(sl)
  end

  private

  def ensure_id_in_slugs
    self.add_slug(self.id)
  end
end