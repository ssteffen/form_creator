class FormSubmission < ActiveRecord::Base
  belongs_to :form
  cattr_reader :per_page
  @@per_page = 15
end
