module Sluggable
  extend ActiveSupport::Concern

  included do
    field :slugs, type: Array, default: []
    field :display_slug, type: String
    
    index({ slugs: 1, _type: 1 }, { unique: true, sparse: true })
    
    validates :slugs, array: { presence: true, format: { with: Utils::Slugger::SLUG_REGEX } }
    validates :display_slug, allow_nil: true, format: { with: Utils::Slugger::SLUG_REGEX }
    validate :_validate_display_slug_in_slugs

    before_save :_ensure_id_in_slugs    
  end

  # Class Methods
  module ClassMethods
    def get(sl)
      self.find_by_slug(sl)
    end

    def find_by_slug(sl)
      self.find_by(slugs: Utils::Slugger.slugify(sl))
    end
  end

  # Instance Methods  
  def slug
    self.display_slug || self.id
  end

  def slug=(sl)
    self.display_slug = sl
    self.slugs.add(sl)
  end
  
  def display_slug=(sl)
    super Utils::Slugger.slugify(sl)
  end
  
  def slugs=(sl)
    Utils::SlugCollection.new(self, :slugs).set(sl)
  end
  
  def slugs
    Utils::SlugCollection.new(self, :slugs)
  end

  private

  def _ensure_id_in_slugs
    self.slugs.add(self.id)
  end
  
  def _validate_display_slug_in_slugs
    if self.display_slug.present? && !self.slugs.include?(self.display_slug)
      errors.add(:display_slug, "is not in slugs array")
    end
  end

end