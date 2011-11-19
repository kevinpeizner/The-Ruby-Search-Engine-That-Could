#!/usr/bin/env ruby

miniInvertedList = Hash.new()

STDIN.read.split("\n").each do |smallFile| # NOTE: here we are assuming each file is on a separate line!

	unless (smallFile=~ /\%BEGIN FILE ([0-9]+)\%(.+)\%END FILE [0-9]+\%/).nil?
		docID = $1
		content = $2

		content.chomp!(" ")

		content.split.each do |word|

			if miniInvertedList.has_key?(word)
				tmp = miniInvertedList[word] # returns a separate hash table.
				if tmp.has_key?(docID)
					tmp[docID]+=1 # inc count of term for given doc.
				else
					tmp[docID]= 1
				end
			else
				miniInvertedList[word]= Hash.new(0)
				miniInvertedList[word][docID]+=1
			end
		end
	end
end

#p miniInvertedList

miniInvertedList.each_pair do |word, wordCountPerDocHash|
	string = "#{word}\t"
	wordCountPerDocHash.each_pair do |docID, count|
		string+= "[#{docID},#{count}] "
	end
	puts string
end
