module RandomId
  
  DEFAULT_ID_LENGTH = 10
  
  extend ActiveSupport::Concern

  included do
    field :_id, type: String, default: -> { self._generate_id }, pre_processed: true

    #before_create :_ensure_unique_id
  end

  protected

  def _generate_id
    Utils::IdGenerator.generate(DEFAULT_ID_LENGTH)
  end

  private

  def _ensure_unique_id
    if self.embedded?
      while self.send(self.metadata.inverse).send(self.metadata.name).where(id: self.id).length > 1
        self.id = self._generate_id
      end
    else
      while self.class.where(id: self.id).first.present?
        self.id = self._generate_id
      end
    end
  end
  
end