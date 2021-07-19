class CodesController < ApplicationController
	def index
		alphabet = {}
		alphabet["I"] = "1"
		alphabet["N"] = "2"
		alphabet["D"] = "3"
		alphabet["O"] = "4"
		alphabet["S"] = "5"
		alphabet["E"] = "6"
		alphabet["H"] = "7"
		alphabet["A"] = "8"
		alphabet["T"] = "9"
		alphabet["Q"] = "00000"
		alphabet["W"] = "0000"
		alphabet["X"] = "000"
		alphabet["Y"] = "00"
		alphabet["Z"] = "0"
		gon.alphabet = alphabet
	end
end