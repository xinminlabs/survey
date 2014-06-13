class Survey::Answer < ActiveRecord::Base

  self.table_name = "survey_answers"

  acceptable_attributes :attempt, :option, :correct, :option_id, :question, :question_id, :text, :rating

  # associations
  belongs_to :attempt
  belongs_to :option
  belongs_to :question

  # validations
  validates :question_id, :presence => true

  # callbacks
  after_create :characterize_answer

  scope :by_question, ->(question) { where("question_id = ?", question.id) }

  def value
    # points = (self.option.nil? ? Survey::Option.find(option_id) : self.option).weight
    # correct?? points : - points
    0
  end

  def correct?
    self.correct ||= self.option.correct? if self.option
  end

  private

  def characterize_answer
    update_attribute(:correct, option.correct?) if self.option
  end

end
