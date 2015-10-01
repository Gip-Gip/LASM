b = 1 # "Build"
y = 2015 # Year
#^The version

# ALL TABS ARE 8 SPACES IN LENGTH

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


flags = Array.new(0) # The array used for keeping track of flags
markerCount = 0 # The variable that keeps track of the amount of markers made

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

def lineLength line
	character = 0
	while line[character] != ';' && character <= line.length
		character += 1
	end
	return character - 1
end

def seperatorDepth line, seperator
	character = 0
	while line[character] != seperator && character <= line.length
		character += 1
	end
	return character - 1
end

def finish
	print "Done! Do you want any help (y/n)? "
	helpYN = gets.chomp
	if helpYN == "y" || helpYN == "Y"
		print "SUPPORTED OUTPUT:\n\
\n\
dasm - generates 6502 code for DASM\n\
\n\
nasm - generates 16 bit code for NASM assemblers\n\
nasm32 - generate 32 bit code for NASM\n"
	end

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Check if we're on unix(SH check)...
#////////////////////////////////////

	if File.exist? "/bin/sh"
		terminalSpecs = `stty size`.chomp.strip
		terminalWidth = terminalSpecs[seperatorDepth(terminalSpecs, ' ') + 1\
		.. terminalSpecs.length].strip
		print "\n"
		banner = Array.new terminalWidth.to_i + 1, "="
		banner = banner.join("")
		banner = banner[1 .. banner.length]
		puts banner
	end
	print "\n"
	exit
end

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#=============================================================================|
#								  INIT SCRIPT
#=============================================================================|
#//////////////////////////////////////////////////////////////////////////////

print "The Literate Assembler (LASM) version #{b}.#{y}\n"
print "Please give me a file to compile: "
fileName = gets.chomp
if !File.exist? fileName
	print "I could not find #{fileName}!\n"
	finish
end

print "I am checking if #{fileName} is a LASM file...\n"

inFile = File.new fileName, "r"
readLine = inFile.gets.chomp.gsub(/\s+/, "")

while readLine == "" || readLine[0] == ';'
	readLine = inFile.gets.chomp.gsub(/\s+/, "")
end

if readLine[0 .. 4] != '$lasm'
	print "I did not find $lasm on the first line!\n"
	finish
end

print "I have found $lasm on the first line! Almost ready...\n"

outFileName = "#{fileName}.asm"
if File.exists? outFileName
	print "The file #{outFileName} already exists! Want to overwrite(y/n)?"
	overWrite = gets.chomp.strip
	if overWrite != 'y' && overWrite != 'Y'
		print "Leaving #{outFileName} untouched.\n"
		finish
	end
end

outFile = File.new outFileName, "w"

print "Please specify the output language(defaults to nasm): "
outLang = gets.chomp.strip

if outLang == ""
	outLang = "nasm"
end

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#=============================================================================|
#								NASM FUNCTIONS
#=============================================================================|
#//////////////////////////////////////////////////////////////////////////////
if outLang == "nasm" || outLang == "nasm16" || outLang == "nasm32"
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

	def incrementHexByte file, hex
		file.print "	INC BYTE [#{hex}h]\n"
		return "	INC BYTE [#{hex}h]\n"
	end

	def incrementByte file, byte
		file.print "	INC BYTE [#{byte}]\n"
		return "	INC BYTE [#{byte}]\n"
	end

	def addressMarker file, address
		file.print "#{address}:\n"
		return "#{address}:"
	end

	def byteHex file, data
		file.print "	DB #{data}h\n"
	end

	def byte file, data
		file.print "	DB #{data}\n"
	end

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# Since there are a few diffrent modes that nasm can assemble in, let's define
# a few things that would make sense with the mode////////////////////////////
#/////////////////////////////////////////////////

	if outLang == "nasm" || outLang == "nasm16"
		outFile.print "	BITS 16\n"

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# With NASM, or really any other compiler/assembler that can generate two forms
# of code, we should always set a base flag that tells the code that it's still
# NASM compiling, and a flag that tells the code that there might be a few/////
# extra features enabled//////////////////////////////////////////////////
#///////////////////////

		flags = setFlag "nasm", flags
		flags = setFlag "nasm16", flags
		def intHex file, data
			file.print "	DW #{data}h\n"
		end

		def int file, data
			file.print "	DW #{data}\n"
		end
		def incrementHexInt file, hex
			file.print "	INC WORD [#{hex}h]\n"
			return "	INC WORD [#{hex}h]\n"
		end

		def incrementInt file, int
			file.print "	INC WORD [#{int}]\n"
			return "	INC WORD [#{int}]\n"
		end
	end
	if outLang == "nasm32"
		outFile.print "	BITS 32"

		flags = setFlag "nasm", flags
		flags = setFlag "nasm32", flags
		def intHex file, data
			file.print "	DD #{data}h\n"
		end

		def int file, data
			file.print "	DD #{data}\n"
		end
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
		file.print "#{address}:\n"
		return "#{address}:\n"
	end

	def byteHex file, data
		file.print "	HEX #{data}\n"
	end

	def byte file, data
		file.print "	DC.B #{data}\n"
	end
end

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#=============================================================================|
#								  INIT SCRIPT
#=============================================================================|
#//////////////////////////////////////////////////////////////////////////////

if flags.empty?
	print "I'm sorry, \"#{outLang}\" does not match a supported assembler.\n"
	inFile.close
	outFile.close
	finish
end

line = 1

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#=============================================================================|
#								   COMPILER
#=============================================================================|
#//////////////////////////////////////////////////////////////////////////////

while readLine = inFile.gets
	readLine = readLine.chomp.gsub(/\s+/, "")
	line += 1
	print "LINE #{line}: #{readLine} "

#\\\\\\\\\\\\\\\\\\\\\\\\\\\
# If there's a blank line...
#///////////////////////////

	if readLine == ""
		print "\n"

#\\\\\\\\\\\\\\\\\\\\\\\\
# If there's a comment...
#////////////////////////

	elsif readLine[0] == ';'
		print "(comment)\n"

#\\\\\\\\\\\\\\\\\\\\\\\\
# If we're setting a flag
#////////////////////////

	elsif readLine[0 .. 4] == '$flag'
		safeFlags = setFlag readLine[5 .. lineLength(readLine)], flags
		if safeFlags == false
			print "(#{readLine [5 .. lineLength(readLine)]} is already flag)\n"
		else
			flags = safeFlags
			print "(#{readLine [5 .. lineLength(readLine)]} is now a flag)\n"
		end

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# If we're checking for a flag...
#////////////////////////////////

	elsif readLine[0 .. 2] == '$if'
		flagSet = checkFlag readLine[3 .. lineLength(readLine)], flags
		if flagSet == false
			print "(flag #{readLine[3 .. lineLength(readLine)]} not set)\n"
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
			print "(flag #{readLine[3 .. lineLength(readLine)]} is set)\n"
		end

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# If we're just copying raw code...
#//////////////////////////////////

	elsif readLine[0 .. 3] == '$raw'
		endCount = 1
		while endCount > 0
			readLine = inFile.gets.chomp
			line += 1
			if readLine[0 .. 2].gsub(/\s+/, "") == '$if' || \
			readLine[0 .. 3].gsub(/\s+/, "") == '$raw' || \
			readLine[0 .. 3].gsub(/\s+/, "") == '$bytes'
				endCount += 1
			elsif readLine[0 .. 3].gsub(/\s+/, "") == '$end'
				endCount -= 1
			else
				outFile.puts readLine
			end
		end
		print "(copied raw code to output)\n"

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# If it's just a stray $end...
#/////////////////////////////

	elsif readLine[0 .. 3] == '$end'
		print "(end marker ignored)\n"

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# If there's a jump instruction...
#/////////////////////////////////

	elsif readLine[0 .. 3] == 'jump'
		print asmName
		if readLine[4 .. 5] == '@#' || readLine[4 .. 5] == '#@'
			print addressHexJump outFile, readLine[6 .. lineLength(readLine)]
		elsif readLine[4] == '@'
			print addressJump outFile, readLine[5 .. lineLength(readLine)]
		elsif readLine[4] == '#'
			print literalHexJump outFile, readLine[5 .. lineLength(readLine)]
		else
			print literalJump outFile, readLine[4 .. lineLength(readLine)]
		end

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# If there's an increment instruction...
#///////////////////////////////////////

	elsif readLine[0 .. 8] == 'increment'
		print asmName

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# If we're incrementing a byte...
#////////////////////////////////

		if readLine[9 .. 12] == 'byte'
			if readLine[13 .. 14] == '@#' || readLine[13 .. 14] == '#@'
				print \
				incrementHexByte outFile, readLine[15 .. lineLength(readLine)]
			elsif readLine[13] == '@'
				print \
				incrementByte outFile, readLine[14 .. lineLength(readLine)]
			elsif readLine[13] == '#'
				print\
				incrementHexByte(outFile, \
				readLine[14 .. lineLength(readLine)]).chomp
				print "(converted to #@#{\
				readLine[14 .. lineLength(readLine)]}. Please correct)\n"
			else
				print\
				incrementByte(outFile, \
				readLine[13 .. lineLength(readLine)]).chomp
				print "{converted to @#{\
				readLine[13 .. lineLength(readLine)]}. Please correct\n"
			end

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# If we're incrementing an interger...
#/////////////////////////////////////

		else
			if readLine[9 .. 10] == '@#' || readLine[9 .. 10] == '#@'
				print \
				incrementHexInt outFile, readLine[11 .. lineLength(readLine)]
			elsif readLine[9] == '@'
				print \
				incrementInt outFile, readLine[10 .. lineLength(readLine)]
			elsif readLine[9] == '#'
				print\
				incrementHexInt(outFile, \
				readLine[10 .. lineLength(readLine)]).chomp
				print "(converted to #@#{\
				readLine[14 .. lineLength(readLine)]}. Please correct)\n"
			else
				print\
				incrementInt(outFile, \
				readLine[9 .. lineLength(readLine)]).chomp
				print "{converted to @#{\
				readLine[9 .. lineLength(readLine)]}. Please correct\n"
			end
		end

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# If we're just making a bunch of bytes...
#/////////////////////////////////////////

	elsif readLine[0 .. 5] == '$bytes'
		print "(a bunch of bytes)\n"
		endCount = 1
		while endCount > 0
			readLine = inFile.gets.chomp.strip
			if readLine[0 .. 2].gsub(/\s+/, "") == '$if' || \
			readLine[0 .. 3].gsub(/\s+/, "") == '$raw' || \
			readLine[0 .. 3].gsub(/\s+/, "") == '$bytes'
				endCount += 1
			elsif readLine[0 .. 3] == '$end'
				endCount -= 1
			elsif readLine[0] == '#'
				byteHex outFile, readLine[1 .. lineLength(readLine)]
			elsif readLine != ""
				byte outFile, readLine
			end
		end

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# If we're just making a bunch of bytes...
#/////////////////////////////////////////

	elsif readLine[0 .. 8] == '$interger'
		print "(a bunch of number)\n"
		endCount = 1
		while endCount > 0
			readLine = inFile.gets.chomp.strip
			if readLine[0 .. 2].gsub(/\s+/, "") == '$if' || \
			readLine[0 .. 3].gsub(/\s+/, "") == '$raw' || \
			readLine[0 .. 5].gsub(/\s+/, "") == '$bytes' || \
			readLine[0 .. 8].gsub(/\s+/, "") == '$interger'
				endCount += 1
			elsif readLine[0 .. 3] == '$end'
				endCount -= 1
			elsif readLine[0] == '#'
				intHex outFile, readLine[1 .. lineLength(readLine)]
			elsif readLine != ""
				int outFile, readLine
			end
		end

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# If there's an address marker...
#////////////////////////////////

	elsif readLine[0] == ':'
		print "(#{addressMarker outFile,\
		readLine[1 .. lineLength(readLine)]})\n"

#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
# If this just doesn't make sense...
#///////////////////////////////////

	else
		print "(gibberish, ignoring)\n"
	end
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
finish
