# ALL TABS ARE 4 SPACES IN LENGTH

#The Public File License (see https://github.com/Gip-Gip/PFL for info)

#Copyright Charles "Gip-Gip" Thompson, September 25th, 2015

#In this case, a file is a group of digital data that can be transferred and
#used.

#The copyright holder of the file LASM.RB has declared that the file and
#everything taken from it, unless stated otherwise, is free for any use by any
#one, with the exception of preventing the free use of the unmodified file
#and/or the unmodified file's derivatives, including but not limited
#to patenting and/or claiming further copyright on the unmodified file and/or
#the unmodified file's derivatives.

#THE FILE LASM.RB IS PROVIDED WITHOUT ANY WARRANTY OR GUARANTEE AT ALL. THE
#AUTHOR(S) ARE NOT LIABLE FOR CLAIMS, DAMAGES, OR REALLY ANYTHING ELSE IN
#CONNECTION TO THIS FILE, UNLESS EXPLICITLY STATED OTHERWISE.

flags = Array.new(0)

def setFlag str, flg
	safeFlg = flg
	flagCursor = 0
	while flagCursor < flg.length
		if flg[flagCursor] == str
			return false
		end
		flagCursor += 1
	end
	flg = Array.new flg.length + 1
	flg[0 ... flg.length] = safeFlg
	flg[flg.length] = str
	return flg
end

def checkFlag str, flg
	flagCursor = 0
	while flagCursor < flg.length
		if flg[flagCursor] == str
			return true
		end
		flagCursor += 1
	end
	return false
end

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#=============================================================================|
#								  INIT SCRIPT
#=============================================================================|
#//////////////////////////////////////////////////////////////////////////////

print "The Literate Assembler (LASM) v1.1.2015\n"
print "Please give me a file to compile: "
fileName = gets.chomp
if !File.exist? fileName
	print "I could not find #{fileName}!\n"
	exit
end

print "I am checking if #{fileName} is a LASM file...\n"

inFile = File.new fileName, "r"
readLine = inFile.gets.chomp.gsub(/\s+/, "")

while readLine == ""
	readLine = inFile.gets.chomp.gsub(/\s+/, "")
end

if readLine != "$lasm"
	print "I did not find $lasm on the first line!\n"
	exit
end

print "I have found $lasm on the first line! Almost ready...\n"
print "Please specify the output language(defaults to nasm): "
outLang = gets.chomp.strip

if outLang == ""
	outLang = "nasm"
elsif outLang == "nasm"
elsif outLang == "dasm"
else
	print "Sorry, that language is not supported!\n"
	exit
end

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#=============================================================================|
#								NASM FUNCTIONS
#=============================================================================|
#//////////////////////////////////////////////////////////////////////////////
if outLang == "nasm"
	asmName = "NASM:\n"
	def addressHexJump file, hex
		file.print "	JMP [#{hex}h]\n"
		return "	JMP [#{hex}h]\n"
	end

	def addressJump file, address
		file.print "	JMP [#{address}]\n"
		return "	JMP [#{address}]\n"
	end

	def literalHexJump file, hex
		file.print "	JMP #{hex}h\n"
		return "	JMP #{hex}h\n"
	end

	def literalJump file, literal
		file.print "	JMP #{literal}\n"
		return "	JMP #{literal}\n"
	end

	def addressMarker file, address
		file.print "#{address}:"
		return "#{address}:"
	end
end

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#=============================================================================|
#								DASM FUNCTIONS
#=============================================================================|
#//////////////////////////////////////////////////////////////////////////////
if outLang == "dasm"
	asmName = "DASM:\n"
	def addressHexJump file, hex
		file.print "	JMP ($#{hex})\n"
		return "	JMP ($#{hex})\n"
	end

	def addressJump file, address
		file.print "	JMP (#{address})\n"
		return "	JMP (#{address})\n"
	end

	def literalHexJump file, hex
		file.print "	JMP $#{hex}\n"
		return "	JMP $#{hex}\n"
	end

	def literalJump file, literal
		file.print "	JMP #{literal}\n"
		return "	JMP #{literal}\n"
	end

	def addressMarker file, address
		file.print "#{address}:"
		return "#{address}:"
	end
end
flags = setFlag outLang, flags

outFileName = "#{fileName}.asm"
if File.exists? outFileName
	print "The file #{outFileName} already exists! Want to overwrite(y/n)?"
	overWrite = gets.chomp.strip
	if overWrite != 'y' && overWrite != 'Y'
		print "Leaving #{outFileName} untouched.\n"
		exit
	end
end

outFile = File.new outFileName, "w"
line = 1
readLine = inFile.gets.chomp.gsub(/\s+/, "")

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#=============================================================================|
#								   COMPILER
#=============================================================================|
#//////////////////////////////////////////////////////////////////////////////

while readLine != "$EOF"
	print "LINE #{line}: #{readLine} "
	if readLine[0 .. 4] == '$flag'
		safeFlags = setFlag readLine[5 .. readLine.length], flags
		if safeFlags == false
			print "(#{readLine [5 .. readLine.length]} is already flag)\n"
		else
			flags = safeFlags
			print "(#{readLine [5 .. readLine.length]} is now a flag)\n"
		end
	elsif readLine[0 .. 2] == '$if'
		flagSet = checkFlag readLine[3 .. readLine.length], flags
		if flagSet == false
			print "(flag #{readLine[3 .. readLine.length]} not set)\n"
			endCount = 1
			while endCount > 0
				readLine = inFile.gets.chomp.gsub(/\s+/, "")
				line += 1
				if readLine[0 .. 2] == '$if' || readLine[0 .. 2] == '$raw'
					endCount += 1
				elsif readLine[0 .. 3] == '$end'
					endCount -= 1
				end
			end
		else
			print "(flag #{readLine[3 .. readLine.length]} is set)\n"
		end
	elsif readLine[0 .. 3] == '$raw'
		endCount = 1
		while endCount > 0
			readLine = inFile.gets.chomp
			line += 1
			if readLine[0 .. 2].gsub(/\s+/, "") == '$if' || readLine[0 .. 3].gsub(/\s+/, "") == '$raw'
				endCount += 1
			elsif readLine[0 .. 3].gsub(/\s+/, "") == '$end'
				endCount -= 1
			else
				outFile.puts readLine
			end
		end
		print "(copied raw code to output)\n"
	elsif readLine[0 .. 3] == '$end'
		print "(end marker ignored)\n"
	elsif readLine[0 .. 3] == 'jump'
		print asmName
		if readLine [4 .. 5] == '@#' || readLine [4 .. 5] == '#@'
			print addressHexJump outFile, readLine [6 .. readLine.length]
		elsif readLine [4] == '@'
			print addressJump outFile, readLine [5 .. readLine.length]
		elsif readLine [4] == '#'
			print literalHexJump outFile, readLine [5 .. readLine.length]
		else
			print literalJump outFile, readLine [4 .. readLine.length]
		end
	elsif readLine[0] == ':'
		print "(#{addressMarker outFile, readLine[1 .. readLine.length]})\n"
	else
		print "(gibberish, ignoring)\n"
	end
	readLine = inFile.gets.chomp.gsub(/\s+/, "")
	line += 1
end

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#=============================================================================|
#								  EXIT SCRIPT
#=============================================================================|
#//////////////////////////////////////////////////////////////////////////////

print "#{line} lines were compiled!\n"
print "The flags #{flags} where flagged!\n"
inFile.close
outFile.close
print "LASM is done!\n"
exit
