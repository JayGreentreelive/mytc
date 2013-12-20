module Nillable
  extend ActiveSupport::Concern

  included do
    before_validation :remove_nils
  end

  private

  def remove_nils
    self.fields.select { |k,v| v.default_val == nil }.keys.each do |k|
      self.remove_attribute(k) if self.send(k).nil?
    end
  end  
end





