# Inspired by https://github.com/benedikt/mongoid-tree/blob/master/lib/mongoid/tree.rb
# Needed to work in and out of embedded documents

module Orderable
  extend ActiveSupport::Concern
  
  included do
    field :_position, type: Integer, default: 0
    
    #validate :_validate_order
  end
  
  # Class Methods
  module ClassMethods
  end
  
  #private
  
  # def order_scope
  #   @order_scope
  # end
  
  # def _order_query_base
  #   # By default, this 
  #   if self.embedded?
  #     self.send(self.metadata.inverse).send(self.metadata.name).type(self.class)
  #   else
  #     self.class
  #   end
  # end
end





