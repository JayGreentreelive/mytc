module Visible
  extend ActiveSupport::Concern

  included do
    field :visibility, type: Array, default: []
  end

  # Class Methods
  module ClassMethods
  end

  # Instance Methods

  private
end