module Visible
  extend ActiveSupport::Concern

  included do
    field :visibility, type: Array, default: []
    
    #index({ visibility: 1, _type: 1 }, { sparse: true })
  end

  # Class Methods
  module ClassMethods
  end

  # Instance Methods

  private
  
  class VisibilityCollection
    
  end
end