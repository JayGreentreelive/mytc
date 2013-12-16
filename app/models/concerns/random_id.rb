module RandomId
  
  ID_LENGTH = 10
  
  extend ActiveSupport::Concern

  included do
    field :_id, type: String, default: -> { self.generate_id }, pre_processed: true

    before_create :ensure_unique_id
  end

  protected

  def generate_id
    Utils::IdGenerator.generate(ID_LENGTH)
  end

  private

  def ensure_unique_id
    while self.class.find_by(id: self.id).present?
      self.id = self.generate_id
    end
  end
  
end