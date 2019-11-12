class ExampleMailer < ActionMailer::Base

  def sample_email(user)
    @user = user
    a = mail(to: "kevin.rizkhy85@gmail.com", subject: 'Sample Email')
  end

end
