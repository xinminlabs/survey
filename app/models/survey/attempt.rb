class Survey::Attempt < ActiveRecord::Base

  self.table_name = "survey_attempts"

  acceptable_attributes :winner, :survey, :survey_id,
    :participant,
    :participant_id,
    :answers_attributes => ::Survey::Answer::AccessibleAttributes

  # relations
  belongs_to :survey
  belongs_to :participant, :polymorphic => true
  has_many :answers, :dependent => :destroy
  accepts_nested_attributes_for :answers,
    :reject_if => ->(q) { q[:question_id].blank? || (q[:option_id].blank? && q[:text].blank? && q[:rating].blank?) }

  # validations
  validate :check_number_of_attempts_by_survey

  #scopes
  scope :wins,   -> { where(:winner => true) }
  scope :looses, -> { where(:winner => false) }
  scope :scores, -> { order("score DESC") }
  scope :for_survey, ->(survey) { where(:survey_id => survey.id) }
  scope :exclude_survey,  ->(survey) { where("NOT survey_id = #{survey.id}") }
  scope :for_participant, ->(participant) {
    where(:participant_id => participant.try(:id), :participant_type => participant.class)
  }

  # callbacks
  after_create :collect_scores

  def correct_answers
    return self.answers.where(:correct => true)
  end

  def incorrect_answers
    return self.answers.where(:correct => false)
  end

  def self.high_score
    return scores.first.score
  end

  private

  def check_number_of_attempts_by_survey
    attempts = self.class.for_survey(survey).for_participant(participant)
    upper_bound = self.survey.attempts_number

    if attempts.size >= upper_bound && upper_bound != 0
      errors.add(:survey_id, "Number of attempts exceeded")
    end
  end

  def collect_scores
    self.score = self.survey.questions.inject(0) do |total, question|
      if question.correct_options.present? && question.answers.where(attempt_id: self.id, option_id: question.correct_options.ids).pluck(:option_id) == question.correct_options.ids
        total += 1
      else
        total
      end
    end
    self.save
  end
end
