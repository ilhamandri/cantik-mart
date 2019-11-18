class RecapMailer < ApplicationMailer
	def new_recap_email transactions, cashiers
		@transactions = transactions
		@cashiers = cashiers
	    mail(to: "kevin.rizkhy85@gmail.com", subject: "REKAP PENJUALAN - " + Date.today.to_s)
	end
end