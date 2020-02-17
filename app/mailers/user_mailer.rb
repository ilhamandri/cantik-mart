class UserMailer < ApplicationMailer
	def welcome_email(email, subject)
    	mail(to: email, subject: subject)
  	end
end
