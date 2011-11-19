#!/usr/bin/env ruby

newFileCount = 0
newFileSize = 0
newOutput = ""
contents = ""

Dir.glob('/home/ubuntu/mnt/docs/*.txt') do |fileName|

	newFileSize += File.size(fileName)

	File.open( fileName , "r+") do |file|
		contents = file.read
	end

	docID = File.basename(fileName, ".txt")
	newOutput += "%BEGIN FILE "+docID+"%"+contents+"%END FILE "+docID+"%\n"

	if newFileSize > 64000000
		# print newOutput to new file
		tmpFileName = "file_"+newFileCount.to_s+".txt"
		f = File.new(tmpFileName, "w+")
		f.write(newOutput)
		f.close
		
		newFileSize = 0 # reset newFileSize
		newOutput = "" # reset newOutput
		newFileCount+=1
	end

end

unless newOutput.nil?
	tmpFileName = "file_"+newFileCount.to_s+".txt"
	f = File.new(tmpFileName, "w+")
	f.write(newOutput)
	f.close
end
