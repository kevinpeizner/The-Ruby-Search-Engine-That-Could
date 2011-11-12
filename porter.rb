#!/usr/bin/env ruby


class Porter

	@@dictionary = Hash.new()
	$docCount = 0

	def cvWord(givenWord)
		cvWordRep = ""
		givenWord.each_char do |char|
			if char =~ /[aeiou]/
				cvWordRep += 'v'
			else
				if char == 'y' && givenWord[givenWord.index("y").to_i-1].to_s =~ /[^aeiou]/
					cvWordRep += 'v'
				else
					cvWordRep += 'c'
				end
			end
		end
		tmp = cvWordRep
		cvWordRep = cvWordRep.gsub(/(c)+/,"C") # compress series of 'c' to 'C'
		cvWordRep = cvWordRep.gsub(/(v)+/, "V") # compress series of 'v' to 'V'
		measure = cvWordRep.scan("VC").length
		return tmp, measure
	end

	# Porter's rule 1a
	def porterRuleOneA(translation)
		if translation=~ /(.+)(sses$|ss$)/
			return $1 + "ss"
		end	
		if translation=~ /(.+)(ies$)/
			return $1 + "i"
		end
		if translation=~ /(.+)(s$)/
			if ($1.length != 1)
				return $1
			end
		end
		return translation
	end

	# Only called if case 2 or 3 from rule 1b succeeds
	def porterRuleOneBextra(translation)
		if translation=~ /(.+)(at$|bl$|iz$)/
			return $& + "e"
		end
		cvRep = cvWord(translation)
		if (cvRep[0] =~ /(.+)(c)(c$)/) && (translation[translation.length-2].eql?translation[translation.length-1])
			if translation =~ /(.+)(.)([^lsz]$)/
				return $1 + $2
			end
		end 
		if (cvRep[1] == 1) && (cvRep[0]=~ /(.*)(cvc$)/)
			if translation=~ /(.+)([^wxy]$)/
				return $& + "e"
			end
		end
		return translation
	end

	# Porter's rule 1b
	def porterRuleOneB(translation)
		if translation=~ /(.+)(eed$)/
			if cvWord($1)[1] > 0
				return $1 + "ee"
			else
				return $&
			end
		end
		if translation=~ /(.+)(ed$)/
			if cvWord($1)[0].include? "v"
				return porterRuleOneBextra($1)
			else
				return $&
			end
		end
		if translation=~ /(.+)(ing$)/
			if cvWord($1)[0].include? "v"
				return porterRuleOneBextra($1)
			else
				return $&
			end
		end
		return translation
	end

	# Porter's rule 1c
	def porterRuleOneC(translation)
		if translation=~ /(.+)(y$)/
			if cvWord($1)[0].include? "v"
				return $1 + "i"
			else
				return $&
			end
		end
		return translation
	end

	# Porter's rule 2
	def porterRuleTwo(translation)
		while translation=~ /(.+)(ational|tional|ization|enci|anci|izer|abli|alli|entli|eli|ousli|ator|alism|iveness|fulness|ousness|aliti|iviti|biliti|ation)($)/
			if cvWord($1)[1] > 0
				case $2
				when "ational", "ator"
					translation = $1 + "ate"
				when "tional"
					translation = $1 + "tion"
				when "enci"
					translation = $1 + "ence"
				when "anci"
					translation = $1 + "ance"
				when "izer"
					translation = $1 + "ize"
				when "abli"
					translation = $1 + "able"
				when "alli", "alism", "aliti"
					translation = $1 + "al"
				when "entli"
					translation = $1 + "ent"
				when "eli"
					translation = $1 + "e"
				when "ousli"
					translation = $1 + "ous"
				when "ation"
					tmp = $1
					if (tmp[tmp.length-1] == "z") && (tmp[tmp.length-2] == "i")
						translation = tmp + "e"
					else
						translation = tmp + "ate"
					end
				when "iveness"
					translation = $1 + "ive"
				when "fulness"
					translation = $1 + "ful"
				when "ousness"
					translation = $1 + "ous"
				when "iviti"
					translation = $1 + "ive"
				when "biliti"
					translation = $1 + "ble"
				else
					break # If we haven't hit any of the above rules, we don't need to loop again.
				end
			else
				break # If we don't me "measure" requirements, we can't apply any of the above rules.
			end
		end
		return translation
	end

	# Porter's rule 3
	def porterRuleThree(translation)
		while translation=~ /(.+)(icate|ative|alize|iciti|ical|ful|ness)($)/
			if cvWord($1)[1] > 0
				case $2
				when "icate", "iciti", "ical"
					translation = $1 + "ic"
				when "ative", "ful", "ness"
					translation = $1
				when "alize"
					translation = $1 + "al"
				else
					break # If we haven't hit any of the above rules, we don't need to loop again.
				end
			else
				break # If we don't me "measure" requirements, we can't apply any of the above rules.
			end
		end
		return translation
	end

	# Porter's rule 4
	def porterRuleFour(translation)
		while translation=~ /(.+)(al|ance|ence|er|ic|able|ible|ant|ement|ment|ent|ion|ou|ism|ate|iti|ous|ive|ize)($)/
			if cvWord($1)[1] > 1
				case $2
				when "al", "ance", "ence", "er", "ic", "able", "ible", "ant", "ou", "ism", "ate", "iti", "ive", "ize"
					translation = $1
				when "ent" # takes care of "ement" and "ment" cases aswell.
					tmp = $1
					if tmp[x = tmp.length-1] == "m"
						if tmp[y = tmp.length-2] == "e"
							translation = tmp[0,y]
						else
							translation = tmp[0,x]
						end
					else
						translation = $1
					end
				when "ion"
					if ($1[$1.length-1]=="s") || ($1[$1.length-1]=="t")
						translation = $1
					else
						break
					end
				else
					break # If we haven't hit any of the above rules, we don't need to loop again.
				end
			else
				break # If we don't me "measure" requirements, we can't apply any of the above rules.
			end
		end
		return translation
	end

	# Porter's rule 5a
	def porterRuleFiveA(translation)
		if translation=~ /(.+)(e$)/
			cvRep = cvWord($1)
			if cvRep[1] > 1
				return $1
			elsif (cvRep[1] == 1) && !(cvRep[0][-3, $1.length].eql?"cvc")
				return $1
			end
		end
		return translation
	end

	# Porter's rule 5b
	def porterRuleFiveB(translation)
		cvRep = cvWord(translation)
		if (cvRep[0] =~ /(.+)(c)(c$)/) && (translation[translation.length-2].eql?translation[translation.length-1] && cvRep[1]>1)
			if translation =~ /(.+)(.)(l$)/
				return $1 + $2
			end
		end
		return translation
	end

	# Runs through all of porter's rules
	def transformWord(aWord)
		translation = porterRuleOneA(aWord)
		translation = porterRuleOneB(translation)
		translation = porterRuleOneC(translation)
		translation = porterRuleTwo(translation)
		translation = porterRuleThree(translation)
		translation = porterRuleFour(translation)
		translation = porterRuleFiveA(translation)
		translation = porterRuleFiveB(translation)
		return translation
	end

	def pullInData
		if File.directory?("/mnt/report/")
			File.open("/mnt/report/word_hash.txt", "r") do |hashFile|
				hashFile.readlines.each do |line|
					line =~ (/(\s)/)
					next if $`.length > 30
					unless $`.eql?(newWord = transformWord($`))
						@@dictionary[$`]= newWord
					end
				end
			end
			File.open("/mnt/report/stem_hash.txt", "w") do |stemFile|
				stemFile.puts "Hash size = #{@@dictionary.size}\n\n"
				@@dictionary.sort.each do |pair|
					stemFile.puts "#{pair[0]} => #{pair[1]}"
				end
			end
		else
			return nil
		end
	end

	# iterate through hash table instead
	def translateDoc(fileName)
		t = Time.now
		file = File.open( fileName , "r+")
		output = file.read
		output.split.uniq.each do |word|
			if @@dictionary.has_key?(word)
				output.gsub!(/(\s)(#{word})(\s)/, " "+@@dictionary[word]+" ")
			end
		end
#		@@dictionary.each{ |key, value|
#			output.gsub!(/(\s)(#{key})(\s)/, " "+value+" ")
#		}
		file.pos = 0 # Reset buffer to beginning of file.
		file.print output # Print output to file
		file.truncate(file.pos) # Delete whatever is left over.
		file.close
		p "Stemming file #{$docCount+=1}: #{fileName} --- Time: #{Time.now-t}"
	end

	def transformDocs
		# If docs directory does not exist, break out and return false.
		if File.directory?("/mnt/docs/")
			Dir.glob('/mnt/docs/*.txt') do |fileName|
				translateDoc(fileName)
			end
		else
			return nil
		end
	end

end

t = Time.now()
myStemmer = Porter.new()
if myStemmer.pullInData
	p "PULLED IN DATA... took: #{Time.now()-t}"
	puts "Read in dictionary, created translation table!"
	myStemmer.transformDocs
	puts "Transformed all docs! ---- DONE!"
else
	puts "Could not create translation table --- Check path to word_hash.txt?"
end
p Time.now()-t
