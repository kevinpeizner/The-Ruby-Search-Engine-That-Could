#!/usr/bin/env ruby

# Author: Kevin Peizner

#PUNC = "?.,!'&:;\"()@#$\%*`~[]{}|\\/<>=+-_" # not for final version.

class Stopper
	
	# Class variable (the whole class has access to it)
	@@wordHash = Hash.new(0)
	
	# Count number of times a word occurs
	def getWords(file)
		File.open( file , "r").each do |line|
			line.split.each do |word|
				@@wordHash[word] += 1 # remove downcase and delete before final version. .downcase.delete(PUNC)
				$wordCnt += 1
			end
		end
	end
	
	def runThroughDocs
		# If docs directory does not exist, break out and return false.
		if File.directory?("/mnt/docs/")
			Dir.glob('/mnt/docs/*.txt') do |fileName|
				getWords(fileName)
			end
		else
			return nil
		end
	end
	
	# Sort hash table key by their value (# of occurrences).
	def sortHash
		# sort hashtable
		@@wordHash = @@wordHash.sort_by { |word, occurrance| occurrance }.reverse

		# just printing results and other info to ./report/stopper_results.txt
		unless(File.exists?("/mnt/report/") && File.directory?("/mnt/report/"))
			Dir.mkdir("/mnt/report/")
		end
		File.open("/mnt/report/stopper_results.txt", "w+") do |resultsFile|
			resultsFile.write("\nTotal word count = #{$wordCnt}\nUnique word count = #{@@wordHash.size}\n\n")
		end

		#File.open("./report/word_hash.txt", "w+") do |hashFile|
		#	@@wordHash.each do |pair|
		#		hashFile.write("#{pair[0]} => #{pair[1]}\n")
		#	end
		#end
	end
	
	def removeStopWords(threshold = 0.001) # default threshold 0.1%
	
		topWords = Array.new()

		# Keep popping off hash keys if their assoc value exceededs the
		# given threshold (default 0.3%).
		while ((@@wordHash[0][1].to_f / $wordCnt.to_f) > threshold) do
			topWords.push(@@wordHash.shift[0])
		end
	
		File.open("/mnt/report/word_hash.txt", "w+") do |hashFile|
			@@wordHash.each do |pair|
				hashFile.write("#{pair[0]} => #{pair[1]}\n")
			end
		end

		# The regex created should be in the form:
		# [^\S]someWord[^\S]|[^\S]someWord[^\S]|...etc.
		# The [^\S] means no non-white space characters.
		# Looking back at it now...you could say [\s] instead.
		regex = "[^\\S]"
		regex += topWords.join("[^\\S]|[^\\S]")
		regex += "[^\\S]"

		# More reporting info.
		if File.exists?("/mnt/report/stopper_results.txt")
			reportFile = File.open("/mnt/report/stopper_results.txt", "a+")
			reportFile.puts "\nTOP WORDS:\n"
			reportFile.puts topWords
			reportFile.puts "\nCustom Regex:\n"
			reportFile.puts regex
			reportFile.close
		end

		# For each *.txt file in the docs directory do the following...
		Dir.glob('/mnt/docs/*.txt') do |fileName|
			file = File.open(fileName, "r+")
			output = ""

			# For each line in the document...
			file.each do |line|
				line = ' ' + line # Add white space at the beginning of the line (allows regex to catch special cases)
				line.gsub!(/\s+/, "\s\s") # Double spacing to ensure regex catches all stop words.
				line.gsub!(/(#{regex})/, " ") # Actual removal of stop word
				output << line.gsub!(/\s+/, "\s") # Reduce amount of white space.
			end
			file.pos = 0 # Reset buffer to beginning of file.
			file.print output # Print output to file
			file.truncate(file.pos) # Delete whatever is left over.
			file.close
		end
	end
end

# http://pleac.sourceforge.net/pleac_ruby/fileaccess.html
#File.open('itest', 'r+') do |f|   
#    out = ""
#    f.each do |line|
#        out << line.gsub(/DATE/) {Time.now}
#    end
#    f.pos = 0                     
#    f.print out
#    f.truncate(f.pos)             
#end


t = Time.now
$wordCnt = 0
myStopList = Stopper.new()
unless myStopList.runThroughDocs
	p "GOOD"
	myStopList.sortHash
	p "HASH TALBE CREATED"
	myStopList.removeStopWords
	p "STOP WORDS REMOVED"
end
p Time.now - t
