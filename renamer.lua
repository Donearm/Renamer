#!/usr/bin/env lua

---
-- @author Gianluca Fiore
-- @copyright 2012, Gianluca Fiore <forod.g@gmail.com>
--

local lfs = require("lfs")

local _O = {}

function print_help()
	print([[Wrong arguments

USAGE:
	rename.lua [-h][-s|--substitute][-a|--append APPEND_STRING][-p|--prefix PREFIX_STRING]
		[-r|--remove REMOVE_STRING][-m|--minimize][-t|--translate TRANSLATE_FROM TRANSLATE_TO]
		[-n|--numbering NAME NUMBERING][-d|--date DATE_FMT][-D|--no-dashes] 
		files|directory [files|directories ...]

Arguments:
	-h					this help
	-s, --substitute			substitute spaces with underscores
	-a, --append				append a string to filenames
	-p, --prefix				prefix a string to filenames
	-r, --remove <string>			remove <string> from filenames
	-m, --minimize				minimize extensions from filenames
	-t, --translate <from> <to>		translate all <from> characters to <to> characters in filenames
	-n, --numbering <name> <numbering>	rename all filenames as <name> with a progressive numeration starting at <numbering>
	-d, --date				add a date to the beginning of filenames (use [today|yesterday|tomorrow|number])
	-D, --no-dashes				strip dashes from dates. Only meaningful with -d, --date
		]])
end

function print_date_help()
	print([[Incorrect/missing arguments

USAGE
	today			for today's date
	yesterday		for yesterday's date
	tomorrow		for tomorrow's date
	year-month-day		for the exact date (as in '2012-10-01')
	a single number		for a specific date of current the month ('20' will become '2012-10-20'),
				or only the year as it is (if the number is biggest than 31, which is always
				considered a day then)

all dates will be in the "yyyy-mm-dd" format unless the -D or --no-dashes options was given; in this case, dashes are removed]])
end


--- Extract flags from an arguments list.
-- Given string arguments, extract flag arguments into a flags set.
-- For example, given "foo", "--tux=beep", "--bla", "bar", "--baz",
-- it would return the following:
-- {["bla"] = true, ["tux"] = "beep", ["baz"] = true}, "foo", "bar".
--
-- taken from 
-- http://snippets.luacode.org/snippets/Parsing_Command-line_arguments_9
function parse_flags(...)
	local args = {...}
	local flags = {}
	for i = #args, 1, -1 do
		local flag = args[i]:match("^%-%-(.*)")
		if flag then
			local var,val = flag:match("(a-z_%-]*)=(.*)")
			if val then
				flags[var] = val
			else
				flags[flag] = true
			end
			table.remove(args, i)
		end
	end
--	return flags, unpack(args)
	return flags, args
end

function cli_parse(...)
	local args = ...
	local files = {}
	for i = #args, 1, -1 do
		local a = arg[i]
		if a:match("^%-h") then
			print_help()
			os.exit(0)
		elseif a:match ("^[-]+(.*)") then
			if a:match("^%-s") or a:match("^[-]+substitute") then
				_O.substitute = true
			elseif a:match("^%-m") or a:match("^[-]+minimize") then
				_O.minimize = true
			elseif a:match("^%-a") or a:match("^[-]+append") then
				_O.append = true
			elseif a:match("^%-p") or a:match("^[-]+prefix") then
				_O.prefix = true
			elseif a:match("^%-r") or a:match("^[-]+remove") then
				_O.remove = true
			elseif a:match("^%-t") or a:match("^[-]+translate") then
				_O.translate = true
			elseif a:match("^%-n") or a:match("^[-]+numbering") then
				_O.numbering = true
			elseif a:match("^%-d") or a:match("^[-]+date") then
				_O.date = true
			elseif a:match("^%-D") or a:match("^[-]+no[-]dashes") then
				_O.dashes = false
			else
				print_help()
				os.exit(1)
			end
		elseif a:match("^([^-][%w_%p]+)") then
			table.insert(files, a)
		else
			print_help()
			os.exit(1)
		end
	end
	return files
end

---Check that the length for the given type is exactly as it should
--@param typ the type
--@param length the desired minimum length
function check_length(typ, length)
	if #typ < length then
		print("Wrong number of arguments, you need to give at least " .. length .. " arguments")
		os.exit(1)
	else
		return true
	end
end

---Extract only the file name from a path string
--@param str the path
function basename(str)
	local name = string.gsub(str, "(.*/)(.*)", "%2")
	return name
end

---Extract only the directory name from a path string
--@param str the path
function dirname(str)
	local name = string.gsub(str, "(.*/)(.*)", "%1")
	return name
end

---Extract only the file extension from a path string. Returns the full
--path and the extension (period included)
--@param str the path
function get_extension(str)
	-- let's check whether the filename seems to have an extension or
	-- not
	if string.match(str, "(.-/)(.-)([.].*)$") then
		local name = string.gsub(str, "(.-/)(.-)([.].*)$", "%1%2")
		local ext = string.gsub(str, "(.-/)(.-)([.].*)$", "%3")
		return name, ext
	else
		local name = string.gsub(str, "(.-/)(.-)([.].*)$", "%1%2")
		return name, ext
	end
end

---Check if a string is a valid path
--@param path the string to check
function ispath(path)
	-- try to rename path to itself; if it works, the original path 
	-- existed
	local s = os.rename(path, path)
	if s == true then
		return true
	else
		return false
	end
end

---Given either a valid path or a number of files (or a mix of both), 
--return a list of filenames in the given directory or comprising the 
--files as arguments
--@param ... the path(s) and/or file(s)
function filelist(...)
	local path = ...
	local files = {}
	for _,e in pairs(path) do
		::continue::
		if lfs.attributes(e, "mode") == "file" then
			table.insert(files, e)
		elseif lfs.attributes(e, "mode") == "directory" then
			for l in lfs.dir(e) do
				if l ~= "." and f ~= ".." then
					local filename = e .. l
					local attr = lfs.attributes(filename)
					if attr.mode == "file" then
						table.insert(files, filename)
					end
				end
			end
		else
			-- neither a file nor a directory? Skip it
			goto continue
		end
	end
	return files
end

---Transform user numerical or alphabetical input in a meaningful date 
--string
--@param input the user input, a string
function dateize(input)
	local date = ''
	if type(input) == "string" then
		if input == "today" then
			date = os.date("%Y-%m-%d")
		elseif input == "yesterday" then
			date = os.date("%Y-%m-%d", os.time()-24*60*60)
		elseif input == "tomorrow" then
			date = os.date("%Y-%m-%d", os.time()+24*60*60)
		elseif string.match(input, "%d+%-%d+%-%d+") then
			date = input
		else
			print_date_help()
			os.exit(1)
		end
	else
		if input <= 31 then
			-- take the input as day of the month and build the date 
			-- string from it
			local m = os.date("%Y-%m")
			date = m .. '-' .. input
		elseif input > 31 then
			-- take input as year and be it the date
			date = input
		else
			-- nothing to do, yet
			print_date_help()
			os.exit(1)
		end
	end
	-- check if the no-dashes cli options has been used
	if _O.dashes == false then
		-- remove dashes from the date string
		date = string.gsub(date, "[-]+", '')
	end
	return date
end

---Substitute all spaces in filename(s) with underscores
--@param filenames a table with the file names
function sub_spaces(filenames)
	for _, f in pairs(filenames) do
		local newname = string.gsub(f, "\\?%s", '_')
		os.rename(f, newname)
	end
end

---Append a string to the end of all filenames given
--@param filenames the files
--@param s the string to append
function append_str(filenames, s)
	local s = tostring(s) -- make sure s is a string
	for _, f in pairs(filenames) do
		local newname = f .. s
		os.rename(f, newname)
	end
end

---Prefix all given filenames with a string
--@param filenames the files
--@param s the string to prefix
function prefix_str(filenames, s)
	local s = tostring(s) -- make sure s is a string
	for _, f in pairs(filenames) do
		local newname = dirname(f) .. s .. basename(f)
		os.rename(f, newname)
	end
end

---Remove a string from all given filenames
--@param filenames the files
--@param s the string to remove
function remove_str(filenames, s)
	local s = tostring(s) -- make sure s is a string
	for _, f in pairs(filenames) do
		local newname = dirname(f) .. string.gsub(basename(f), s, '')
		os.rename(f, newname)
	end
end

---Minimize the extension of given files
--@param filenames the files
function minimize_ext(filenames)
	for _, f in pairs(filenames) do
		local n, e = get_extension(f)
		local newname = n .. string.lower(e)
		os.rename(f, newname)
	end
end

---Translate a list of characters to another in the given filenames
--@param filenames the files
--@param char_f the characters to translate
--@param char_t the characters to translate to
function translate_chars(filenames, char_f, char_t)
	-- have 2 tables to contain each characters in char_f and char_t
	local from_table = {}
	local to_table = {}
	-- make sure characters are strings
	local char_f = tostring(char_f)
	local char_t = tostring(char_t)
	-- limit char_f to the length of char_t. The opposite is already 
	-- done automatically by the lua interpreter
	local correct_char_f = string.sub(char_f, 1, #char_t)
	for _, f in pairs(filenames) do
		local oldname = basename(f) -- save original name
		local newname = oldname -- newname is oldname at the beginning
		-- insert every char in char_f and char_t in corresponding 
		-- tables
		for c in string.gmatch(correct_char_f, ".") do
			table.insert(from_table, c)
		end
		for c in string.gmatch(char_t, ".") do
			table.insert(to_table, c)
		end
		-- iterate over every from_table item and substitute it with the 
		-- same positioned ones in to_table
		for i = 1, #from_table, 1 do
			newname = string.gsub(newname, from_table[i], to_table[i])
		end
		os.rename(f, dirname(f) .. newname)
	end
end

---Rename files with a fixed name and a numbering starting at a given 
--integer
--@param filenames the files
--@param name the string for the new filename
--@param start the integer from which to start the numbering
function idx_numbering(filenames, name, start)
	local idx = start
	for _, f in pairs(filenames) do
		local root = dirname(f)
		local oldname, ext = get_extension(f)
		-- prefix enough 0s if the number is not already at least 3 digits 
		-- long
		if idx < 10 then
			idx = '00' .. idx
		elseif idx >= 10 and idx < 100 then
			idx = '0' .. idx
		else
			idx = idx
		end
		local newname = root .. name .. idx .. ext
		os.rename(f, newname)
		idx = idx + 1
	end
end

---Prepend each file with the current or an arbitrary date
--@param filenames the files
--@param date_fmt the format of the date
function prepend_date(filenames, date_fmt)
	local d = dateize(date_fmt)
	for _,f in pairs(filenames) do
		local root = dirname(f)
		local newname = root .. d .. basename(f)
		os.rename(f, newname)
	end
end


function main()
	local f = cli_parse(arg)
	local fil = filelist(f)
end

main()
