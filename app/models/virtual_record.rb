class VirtualRecord
  include ActiveModel::Model

  def initialize
    @id = SecureRandom.hex(16)
    @errors = ActiveModel::Errors.new(self)
  end
end
