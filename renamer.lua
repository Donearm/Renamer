#!/usr/bin/env lua

---
-- @author Gianluca Fiore
-- @copyright 2012-2013, Gianluca Fiore <forod.g@gmail.com>
--

local lfs = require("lfs")

local _O = {}

function print_help()
	print([[Wrong arguments

USAGE:
	rename.lua [-h][-s|--substitute][-a|--append=APPEND_STRING][-p|--prefix=PREFIX_STRING]
		[-r|--remove=REMOVE_STRING][-m|--minimize][-t|--translate=TRANSLATE_FROM,TRANSLATE_TO]
		[-n|--numbering=NUMBERING,NAME][-d|--date=DATE_FMT][-D|--no-dashes] 
		files|directory [files|directories ...]

Arguments:
	-h					this help
	-s, --substitute			substitute spaces with underscores
	-a, --append=<string>			append a string to filenames
	-p, --prefix=<string>			prefix a string to filenames
	-r, --remove=<string>			remove <string> from filenames
	-m, --minimize				minimize extensions from filenames
	-t, --translate=<from>,<to>		translate all <from> characters to <to> characters in filenames
	-n, --numbering=<numbering>,<name>	rename all filenames as <name> with a progressive numeration starting at <numbering>
	-d, --date=<date>			add a date to the beginning of filenames (use [today|yesterday|tomorrow|number])
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


function cli_parse(...)
	-- this is probably too long/convoluted. I didn't want to use 
	-- external libraries so WillFixThisLater™
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
				local var, val = a:match("([a-z_%-]*)=(.*)")
				if val then
					_O.append_string = val
				else
					-- no flag=string pattern? Then assume -flag string 
					-- pattern. Same thing in the others occurrences
					_O.append_string = arg[i+1]
					i = i + 1
				end
			elseif a:match("^%-p") or a:match("^[-]+prefix") then
				_O.prefix = true
				local var, val = a:match("([a-z_%-]*)=(.*)")
				if val then
					_O.prefix_string = val
				else
					_O.prefix_string = arg[i+1]
					i = i + 1
				end
			elseif a:match("^%-r") or a:match("^[-]+remove") then
				_O.remove = true
				local var, val = a:match("([a-z_%-]*)=(.*)")
				if val then
					_O.remove_string = val
				else
					_O.remove_string = arg[i+1]
					i = i + 1
				end
			elseif a:match("^%-t") or a:match("^[-]+translate") then
				_O.translate = true
				local var, val_f, val_t = a:match("([a-z_%-]*)=(.*),(.*)")
				if val_f and val_t then
					_O.translate_from, _O.translate_to = val_f, val_t
				else
					_O.translate_from, _O.translate_to = arg[i+1], arg[i+2]
					i = i + 2
				end
			elseif a:match("^%-n") or a:match("^[-]+numbering") then
				_O.numbering = true
				local var, idx, name = a:match("([a-z_%-]*)=(.*),(.*)")
				if idx and name then
					-- check which between idx and name is the number 
					-- and which is the string. The user may bave 
					-- inverted them
					if type(idx) == "number" or type(tonumber(idx)) == "number" then
						_O.numbering_idx = idx
						_O.numbering_name = name
					elseif type(idx) == "string" and type(tonumber(name)) == "number" then
						_O.numbering_idx = name
						_O.numbering_name = idx
					else
						if tonumber(idx) == nil then
							-- impossible to have a number and a string, 
							-- bailing out
							print_help()
							os.exit(1)
						end
						-- just try to have a number and a string
						_O.numbering_idx = tonumber(idx)
						_O.numbering_name = tostring(name)
					end
				else
					-- if -t string string pattern, try which string can 
					-- be the index
					if tonumber(arg[i+1]) then
						_O.numbering_idx = arg[i+1]
						_O.numbering_name = tostring(arg[i+2])
						i = i + 2
					elseif tonumber(arg[i+2]) then
						_O.numbering_idx = arg[i+2]
						_O.numbering_name = tostring(arg[i+1])
						i = i + 2
					else
						-- if all else fails, first string is the index 
						-- and the second the name.
						-- Blame on you user for not reading the help
						_O.numbering_idx = arg[i+1]
						_O.numbering_name = tostring(arg[i+2])
						i = i + 2
					end
				end
			elseif a:match("^%-d") or a:match("^[-]+date") then
				_O.date = true
				local var, val = a:match("([a-z_%-]*)=(.*)")
				if val then
					_O.date_input = val
				else
					_O.date_input = arg[i+1]
					i = i + 1
				end
			elseif a:match("^%-D") or a:match("^[-]+no[-]dashes") then
				_O.dashes = false
			else
				print_help()
				os.exit(1)
			end
		elseif a:match("^([^-][%w_%p]*)") then
			table.insert(files, a)
		else
			print_help()
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
--			goto continue
			
		end
		::continue::
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
--@param start the integer from which to start the numbering
--@param name the string for the new filename
function idx_numbering(filenames, start, name)
	local idx = tonumber(start)
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
	-- let's see what to do
	if _O.substitute then
		sub_spaces(fil)
	elseif _O.minimize then
		minimize_ext(fil)
	elseif _O.append then
		append_str(fil, _O.append_string)
	elseif _O.prefix then
		prefix_str(fil, _O.prefix_string)
	elseif _O.remove then
		remove_str(fil, _O.remove_string)
	elseif _O.translate then
		translate_chars(fil, _O.translate_from, _O.translate_to)
	elseif _O.numbering then
		idx_numbering(fil, _O.numbering_idx, _O.numbering_name)
	elseif _O.date then
		prepend_date(fil, _O.date_input)
	else
		print_help()
		os.exit(1)
	end
end

main()
