class IncurredIncidental < ActiveRecord::Base
  belongs_to :rental
  belongs_to :incidental_type
  has_one :financial_transaction, as: :transactable

  has_many :notes, as: :noteable
  has_many :incurred_incidentals_documents, dependent: :destroy
  has_many :documents, through: :incurred_incidentals_documents

  after_create :create_financial_transaction

  validates :times_modified, presence: true
  validates_associated :incidental_type

  def fee
    incidental_type.base + (times_modified * incidental_type.modifier_amount)
  end

  # private
  def create_financial_transaction
    FinancialTransaction.create rental: rental, amount: fee, transactable_type: self.class, transactable_id: id
  end
end
