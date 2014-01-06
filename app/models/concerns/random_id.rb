module RandomId
  
  DEFAULT_ID_LENGTH = 10
  
  extend ActiveSupport::Concern

  included do
    field :_id, type: String, default: -> { self.generate_id }, pre_processed: true

    before_create :ensure_unique_id
  end

  protected

  def generate_id
    Utils::IdGenerator.generate(DEFAULT_ID_LENGTH)
  end

  private

  def ensure_unique_id
    if self.embedded?
      while self.send(self.metadata.inverse).send(self.metadata.name).where(id: self.id).length > 1
        self.id = self.generate_id
      end
    else
      while self.class.find_by(id: self.id).present?
        self.id = self.generate_id
      end
    end
  end
  
end