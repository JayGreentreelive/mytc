class PersonSettings
  include Mongoid::Document
  include Nillable
  
  embedded_in :person
  
  field :_id, type: String, default: nil
  field :allow_bb_cma_contact, type: Boolean
  field :enable_nyan_cursor, type: Boolean
  
  normalize_attribute :allow_bb_cma_contact, with: :true_or_nil
  normalize_attribute :enable_nyan_cursor, with: :true_or_nil
end
