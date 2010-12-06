class FormMailer < ActionMailer::Base
  default :from => "webmaster@housing.siu.edu"
  
  def new_forms_notification(object, response_id)
    mail(:to =>  object.email_notification_address,
         :from => 'webmaster@housing.siu.edu', 
         :subject => object.title + " Form submission.",
         :body => "The Form: #{object.title} has been submitted.You can view the submission here: /form_submissions/view_result/#{response_id}")
  end
  
  def new_forms_alt_notification(form_object, result_id, email)
    mail(:to => email,
         :from => "webmaster@housing.siu.edu",
         :subject => "#{form_object.title} Form Submission",
         :body => "The Form: #{form_object.title} has been submitted. You can view the submission here: /form_submissions/view_alt_result/#{result_id}")
  end
  
end
