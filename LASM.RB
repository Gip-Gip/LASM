#!/usr/bin/env ruby
v = 4 # Version
y = 2015 # Year
#^The version

# ALL TABS ARE 8 SPACES IN LENGTH

#The Public File License (see https://github.com/Gip-Gip/PFL for info)

#Copyright Charles "Gip-Gip" Thompson, October 14th, 2015

#In this case, a file is a group of digital data that can be transferred and
#used.

#The copyright holder of the file LASM.RB has declared that the file and
#everything taken from it, unless stated otherwise, is free for any use by any
#one, with the exception of preventing the free use of the unmodified file,
#including but not limited to patenting and/or claiming further copyright on
#the unmodified file.

#THE FILE LASM.RB IS PROVIDED WITHOUT ANY WARRANTY OR GUARANTEE AT ALL. THE
#AUTHOR(S) ARE NOT LIABLE FOR CLAIMS, DAMAGES, OR REALLY ANYTHING ELSE IN
#CONNECTION TO THIS FILE, UNLESS EXPLICITLY STATED OTHERWISE.


#MARK: SYMBOLS

$MARKER = 0;
$ENDMARKER = 1;

$args = ARGV # The command line arguments, aliased to the global $args

$assembler = "nasm" # The default output format

$source = nil # The global for the source file
$output = nil # The global for the output file

$verbose = false;
$skip = false;

$flags = Array.new 0;

$time = Time.new;

$usage = "\n\
USAGE:\n\
(ruby) ./lasm.rb in.file (arguments)\n\
\n\
ARGUMENTS:\n\
-a assembler, --assembler assembler = Specify the assembler to use.\n\
-f flag, --flag flag = Set a flag.\n\
-h, --help = Display this message and exit.\n\
-o out.file, --out out.file = Provide the output file's name.\n\
-s, --skip = Answer yes to all questions\n\
-v, --verbose = Display all messages\n\
\n";

$duck = "\n\
    ____ \n\
 __/*   \\________ \n\
/__              \\ \n\
   |              | \n\
   \\_____________/ \n\
\n\
RETARD PUFFIN NUFF \n\
\n\
\n";

$done = "\n\
LASM is done! Continue with your day...\n\
\n";

#MARK: FUNCTIONS

def beep
	print "\a";
end

def help
	puts $usage;
	exit;
end

def seperate
	print "\n\n\n";
end

def log str
	if $logFile != nil
		$logFile.print str;
	end
	if $verbose == true
		print str;
	end
end

def error str
	$verbose = true;
	log("\n\n\nERROR @ LINE #{$line}: #{str}\n\n\n");
	exit;
end

def publish str
	$outputFile.puts str;
	log(" (#{str.strip})");
end

def formatLine str
	str = str.chomp.gsub(/\s+/, "").downcase;
	commentDepth = 0;
	while str[commentDepth] != ';' and commentDepth < str.length
		commentDepth += 1;
	end
	if commentDepth == str.length
		return str;
	else
		return str[0 .. commentDepth - 1];
	end
end

def operatorDepth str
	opDepth = 0;
	while str[opDepth] != '+' and str[opDepth] != '-' and \
			str[opDepth] != '=' and opDepth < str.length
		opDepth += 1;
	end
	return opDepth;
end

def checkMarker str
	stats = Array.new(2);
	if str[0] == '$'
		stats[$MARKER] = true;
	end
	
	if str[1 .. 3] == 'end' or str[1 .. 4] == 'else'
		stats[$ENDMARKER] = true;
	elsif str[1 .. 4] == 'flag'
		stats[$ENDMARKER] = nil;
	else
		stats[$ENDMARKER] = false;
	end
	return stats;
end

def replaceExt str, ext
	extDepth = str.length;
	while str[extDepth] != '.' and extDepth > 0
		extDepth -= 1;
	end
	if extDepth == 0
		extDepth = str.length;
	end
	return "#{str[0 ... extDepth]}#{ext}";
end

def setFlag str
	safeFlags = $flags;
	flagCursor = 0;
	while flagCursor < $flags.length
		if $flags[flagCursor] == str
			return false;
		end
		flagCursor += 1;
	end
	$flags = Array.new $flags.length + 1;
	$flags[0 ... $flags.length] = safeFlags;
	$flags[$flags.length] = str;
	return true;
end

def getTypes str
	stringCursor = 0;
	prevTypeCode = 0;
	typeCodes = "";
	while stringCursor < str.length
		if str[stringCursor .. stringCursor + 1] == '@#' or \
				str[stringCursor .. stringCursor + 1] == '#@'
			typeCodes += "b";
			prevTypeCode = 0;
			stringCursor += 2;
		elsif str[stringCursor] == '@'
			typeCodes += "a";
			prevTypeCode = 0;
			stringCursor += 1;
		elsif str[stringCursor] == '#'
			typeCodes += "h";
			prevTypeCode = 0;
			stringCursor += 1;
		elsif str[stringCursor] == '+'
			typeCodes += "s";
			prevTypeCode = 0;
			stringCursor += 1;
		elsif str[stringCursor] == '-'
			typeCodes += "d";
			prevTypeCode = 0;
			stringCursor += 1;
		elsif str[stringCursor] == '='
			typeCodes += "e";
			prevTypeCode = 0;
			stringCursor += 1;
		elsif typeCodes[typeCodes.length - 1] != 'b' and \
				typeCodes[typeCodes.length - 1] != 'a' and \
				typeCodes[typeCodes.length - 1] != 'h' and \
				prevTypeCode == 1
			typeCodes += "r"
			stringCursor += 1;
		else
			stringCursor += 1;
		end
		prevTypeCode += 1;
	end
	return typeCodes
end

def getStatementDepth str, num
	stringCursor = 0;
	statementCount = 0;
	while statementCount < num - 1
		while str[stringCursor] != '+' and \
				str[stringCursor ] != '-' and \
				str[stringCursor] != '=' and \
				stringCursor < str.length
			stringCursor += 1;
		end
		stringCursor += 1;
		statementCount += 1;
	end
	if str[stringCursor .. stringCursor + 1] == '@#' or \
			str[stringCursor .. stringCursor + 1] == '#@'
		stringCursor += 2;
	elsif str[stringCursor] == '@' or str[stringCursor] == '#'
		stringCursor += 1;
	end
	return stringCursor;
end

def checkFlag str
	flagCursor = 0;
	while flagCursor <= $flags.length
		if $flags[flagCursor] == str
			return true;
		end
		flagCursor += 1;
	end
	return false;
end

#MARK: INIT SCRIPT

puts "the Literate ASseMbler(LASM) #{v}.#{y} is under the PFL. See LICENSE.TXT";

if $args.length == 0
	help;
end

#MARK: ARGUMENT READER

puts "LASM is reading your arguments... ";

argCounter = -1;

while argCounter < $args.length
	argCounter += 1;
	if $args[argCounter] == "-a" or $args[argCounter] == "--assembler"
		argCounter += 1;
		puts "Will check for #{$args[argCounter]} support!";
	elsif $args[argCounter] == "-d" or $args[argCounter] == "--duck"
		puts $duck;
		exit;
	elsif $args[argCounter] == "-h" or $args[argCounter] == "--help"
		help;
	elsif $args[argCounter] == "-f" or $args[argCounter] == "--flag"
		argCounter += 1;
		flagSet = setFlag($args[argCounter]);
		if flagSet == false
			puts "#{$args[argCounter]} is already flagged!";
		else
			puts "Flag #{$args[argCounter]} is now set!";
		end
	elsif $args[argCounter] == "-o" or $args[argCounter] == "--out"
		argCounter += 1;
		$output = $args[argCounter];
		puts "Will try to write the output to #{$output}!";
	elsif $args[argCounter] == "-l" or $args[argCounter] == "--log"
		argCounter += 1;
		$logName = $args[argCounter];
		puts "Will try to log all events to #{$log}!";
	elsif $args[argCounter] == "-s" or $args[argCounter] == "--skip"
		$skip = true;
		puts "Will skip all Y/N questions!";
	elsif $args[argCounter] == "-v" or $args[argCounter] == "--verbose"
		$verbose = true;
		puts "Verbose is enabled! Prepared for a flooded console...";
	elsif $args[argCounter] != nil
		$source = $args[argCounter];
		puts "Will try to use the file #{$source} to compile!";
	end
end

if $source == nil
	help;
end

if $output == nil
	$output = replaceExt($source, '.asm');
end

#MARK: FILE MANAGMENT

if !File.exists? $source
	puts "Source file #{$source} not found!";
	exit;
end

$sourceFile = File.new $source, "r";

if File.exists? $output and $skip == false
	print "Do you wish to overwrite #{$output}(y/n)? ";
	yn = $stdin.gets.chomp.strip;
	if yn != "y" and yn != "Y"
		puts "Not overwriting.";
		exit;
	end
	puts "Overwriting!";
else
	puts "Creating #{$output}!";
end

$outputFile = File.new $output, "w";

if $logName != nil
	$logFile = File.new $logName, "a";
	$logFile.puts "\nWRITTEN TO BY LASM #{v}.#{y}, #{$time.month}/#{\
		$time.day}/#{$time.year} @ #{$time.hour}:#{$time.min}";
end

#MARK: NASM CODE GENERATION

validASM = false;

if $assembler == "nasm" or $assembler == "nasm16" or $assembler == "nasm32"
	setFlag("nasm");
	validASM = true;
	def gen_addressLabel str
		return "#{str}:";
	end
	def gen_jump one, two, flg
		code_one = nil, code_two = nil, code_op = nil;
		case flg[0]
			when 'b'
				code_one = "[#{one}h]";
			when 'a'
				code_one = "[#{one}]";
			when 'h'
				code_one = "#{one}h";
			when 'r'
				code_one = "#{one}";
			else
				error("LONE JUMP INSTRUCTION!");
		end
		case flg[1]
			when 's'
				code_op = "ADD";
			when 'd'
				code_op = "SUB";
		end
		case flg[2]
			when 'b'
				code_two = "[#{two}h]";
			when 'a'
				code_two = "[#{two}]";
			when 'h'
				code_two = "#{two}h";
			when 'r'
				code_two = "#{two}";
		end
		if code_two == nil and code_op != nil
			error("STRAY OPERATOR!");
		elsif code_op == nil and code_two != nil
			error("INVALID OPERATOR!");
		elsif code_two == nil
			return "	JMP #{code_one}";
		else
			return "	MOV AX, #{code_one}\n" + \
				"	#{code_op} AX, #{code_two}\n" + \
				"	JMP AX\n";
		end
	end
end

#MARK: FINAL INIT STUFF

if validASM == false
	$verbose = true;
	log("ASSEMBLER #{$assembler} IS NOT SUPPORTED! ABORTING...");
	exit;
end

#MARK: COMPILER

$line = 0;

while readLine = $sourceFile.gets
	rawLine = readLine.chomp;
	readLine = formatLine(readLine);
	$line += 1;
	log("LINE #{$line}: #{rawLine}");
	if readLine[0 .. 4] == '$flag'
		flagState = setFlag(readLine[5 .. readLine.length]);
		if flagState == false
			log(" (#{readLine[5 .. readLine.length]\
			} has already been flagged)");
		else
			log(" (#{readLine[5 .. readLine.length]\
			} is now flagged!)");
		end
	elsif readLine[0 .. 5] == '$ifnot'
		flagState = checkFlag(readLine[6 .. readLine.length]);
		if flagState == true
			log(" (#{readLine[6 .. readLine.length]\
			} has been flagged. Skipping code...)");
			endCount = 1;
			while endCount > 0
				readLine = $sourceFile.gets;
				if readLine == nil
					seperate;
					$verbose = true;
					log("NO $END FOR THE $IF AT LINE #{\
					ifStart}! ABORTING...");
					endCount = 0;
				else
					readLine = formatLine(readLine);
					$line += 1;
					markerStatus = checkMarker(readLine);
					
					if markerStatus[$MARKER] == true and\
					markerStatus[$ENDMARKER] == false
						
						endCount += 1;
						
					elsif markerStatus[$MARKER] == true\
					and markerStatus[$ENDMARKER] == true
						
						endCount -= 1;
					
					end
				end
			end
		else
			log(" (#{readLine[6 .. readLine.length]\
			} has not been set.)");
		end
	elsif readLine[0 .. 2] == '$if'
		flagState = checkFlag(readLine[3 .. readLine.length]);
		if flagState == false
			ifStart = $line
			log(" (#{readLine[3 .. readLine.length]\
			} has not been flagged. Skipping code...)");
			endCount = 1;
			while endCount > 0
				readLine = $sourceFile.gets;
				if readLine == nil
					seperate;
					$verbose = true;
					log("NO $END FOR THE $IFNOT AT LINE #{\
					ifStart}! ABORTING...");
					endCount = 0;
				else
					readLine = formatLine(readLine);
					$line += 1;
					markerStatus = checkMarker(readLine);
					
					if markerStatus[$MARKER] == true and\
					markerStatus[$ENDMARKER] == false
						
						endCount += 1;
						
					elsif markerStatus[$MARKER] == true \
					and markerStatus[$ENDMARKER] == true
						
						endCount -= 1;
					
					end
				end
			end
		else
			log(" (#{readLine[3 .. readLine.length]\
			} has been flagged.)");
		end
	elsif readLine[0 .. 4] == '$else'
		log("(Nothing against $else. Skipping code...)");
		elseStart = $line;
		endCount = 1;
		while endCount > 0
			readLine = $sourceFile.gets;
			if readLine == nil
				seperate;
				$verbose = true;
				log("NO $END FOR THE $ELSE AT LINE #{\
				elseStart}! ABORTING...");
				endCount = 0;
			else
				readLine = formatLine(readLine);
				$line += 1;
				markerStatus = checkMarker(readLine);
				
				if markerStatus[$MARKER] == true and\
				markerStatus[$ENDMARKER] == false
					
					endCount += 1;
					
				elsif markerStatus[$MARKER] == true and\
				markerStatus[$ENDMARKER] == true
					
					endCount -= 1;
				
				end
			end
		end
	elsif readLine[0] == ':'
		publish(gen_addressLabel(readLine[1 .. readLine.length]));
	elsif readLine[0 .. 3] == 'jump'
		if getTypes(readLine[4 .. readLine.length]).length == 1
			publish(gen_jump( \
				readLine[getStatementDepth(\
				readLine[4 .. readLine.length], 1) + 4 .. \
				readLine.length], nil, \
				getTypes(readLine[4 .. readLine.length] \
				) + "nn"));
		else
			publish(gen_jump( \
				readLine[getStatementDepth(\
				readLine[4 .. readLine.length], 1) + 4 .. \
				operatorDepth(readLine) - 1], \
				readLine[getStatementDepth(\
				readLine[4 .. readLine.length], 2) + 4 .. \
				readLine.length], \
				getTypes(readLine[4 .. readLine.length] \
				)));
		end
	elsif readLine != "" and readLine[0] != ';' and \
			readLine[0 .. 3] != '$end'
		log(" (gibberish, ignoring)");
	end
	log("\n");
end

#MARK: EXIT SCRIPT

$sourceFile.close;
$outputFile.close;

log("#{$line} lines where compiled!\n");
log("The flags #{$flags} were set!\n");
$verbose = true;
beep;
log($done);

exit;
