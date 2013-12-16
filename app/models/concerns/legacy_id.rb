module LegacyId
  extend ActiveSupport::Concern

  included do
    #field :_id, type: String, default: -> { self.generate_id }, pre_processed: true

    #before_create :ensure_unique_id
  end

  protected
  
end