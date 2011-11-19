#!/usr/bin/env ruby

currentWord = nil
currentWordHash = nil
totalWordOccurences = 0

ARGF.read.split("\n").each do |pair|
	pair=~ /(.*)\t(.*)/
	word = $1
	miniHash = $2

	miniHash.chomp! #remove newline.
	tmpTotalCount = 0 # holds total occurences for given tuple.

	miniHash.split(" ").each do |docOccurPair|
		docOccurPair=~ /\[.+,([0-9]+)\]/ # capture group $1 contains number of occurences for given doc. 
		tmpTotalCount += $1.to_i # add all occurences per docID together.
	end

	
	if currentWord != word # We have a new term (key). 
		unless currentWordHash.nil? # If the previous term has no associated [docID,occurrences], then don't print.
			print "#{currentWord}: #{totalWordOccurences}: #{currentWordHash}\n"
		end
		currentWord = word # Set the current key/term/word to what was read from STDIN.
		currentWordHash = miniHash # Set the value to what was read from STDIN (capture group $2).
		totalWordOccurences = tmpTotalCount
	else
		currentWordHash += miniHash # If we're on the same term, append [docID_1,occurence_1] [docID_2,occurence_2] ...[docID_N,occurence_N]
		totalWordOccurences += tmpTotalCount # Increase count for num occurences of given word.
	end
	
end

