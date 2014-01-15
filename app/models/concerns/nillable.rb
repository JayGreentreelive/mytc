module Nillable
  extend ActiveSupport::Concern

  included do
    before_validation :_remove_nils
  end

  private

  def _remove_nils
    self.fields.select { |k,v| v.default_val == nil }.keys.each do |k|
      self.remove_attribute(k) if self.send(k).nil? && self.has_attribute?(k)
    end
  end  
end





