#!/usr/bin/env lua

---
-- @author Gianluca Fiore
-- @copyright 2012, Gianluca Fiore <forod.g@gmail.com>
--

local lfs = require("lfs")

function print_help()
	print("Wrong arguments\n")
	print("USAGE:\n")
	print("\trename.lua [-h][-s|--substitute][-a|--append APPEND_STRING][-p|--prefix PREFIX_STRING]\n")
	print("\t           [-r|--remove REMOVE_STRING][-m|--minimize][-t|--translate TRANSLATE_FROM TRANSLATE_TO]\n")
	print("\t           [-n|--numbering NAME NUMBERING][-d|--date DATE_FMT] files [files ...]")
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
				print("Substituting spaces")
			elseif a:match("^%-m") or a:match("^[-]+minimize") then
				print("Minimize the extension")
			elseif a:match("^%-a") or a:match("^[-]+append") then
				print("Append string")
			elseif a:match("^%-p") or a:match("^[-]+prefix") then
				print("Prefix string")
			elseif a:match("^%-r") or a:match("^[-]+remove") then
				print("Remove string")
			elseif a:match("^%-t") or a:match("^[-]+translate") then
				print("Translate")
			elseif a:match("^%-n") or a:match("^[-]+numbering") then
				print("Numbering")
			elseif a:match("^%-d") or a:match("^[-]+date") then
				print("Add date")
			else
				print_help()
				os.exit(1)
			end
		elseif a:match("^([^-][%w_%p]+)") then
			print("Insert into table")
			table.insert(files, a)
		else
			print(a)
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
	if type(input) == "string" then
		if input == "today" then
			local date = os.date("%Y-%m-%d")
			return date
		elseif input == "yesterday" then
			local date = os.date("%Y-%m-%d", os.time()-24*60*60)
			return date
		elseif input == "tomorrow" then
			local date = os.date("%Y-%m-%d", os.time()+24*60*60)
			return date
		else
			print("This is not an accepted date string, please use only 'today' or 'yesterday' or 'tomorrow'")
			os.exit(1)
		end
	else
		-- nothing to do, yet
		print("This is not an accepted date string, please use only 'today' or 'yesterday' or 'tomorrow'")
		os.exit(1)
	end
end

---Substitute all spaces in filename(s) with underscores
--@param filenames a table with the file names
function sub_spaces(filenames)
	for _, f in pairs(filenames) do
		local newname = string.gsub(f, "\\?%s", '_')
		local t, err = os.rename(f, newname)
	end
	return t, err
end

---Append a string to the end of all filenames given
--@param filenames the files
--@param s the string to append
function append_str(filenames, s)
	for _, f in pairs(filenames) do
		local newname = f .. s
		local t, err = os.rename(f, newname)
	end
	return t, err
end

---Prefix all given filenames with a string
--@param filenames the files
--@param s the string to prefix
function prefix_str(filenames, s)
	for _, f in pairs(filenames) do
		local newname = dirname(f) .. s .. basename(f)
		local t, err = os.rename(f, newname)
	end
	return t, err
end

---Remove a string from all given filenames
--@param filenames the files
--@param s the string to remove
function remove_str(filenames, s)
	for _, f in pairs(filenames) do
		local newname = dirname(f) .. string.gsub(basename(f), s, '')
		local t, err = os.rename(f, newname)
	end
	return t, err
end

---Minimize the extension of given files
--@param filenames the files
function minimize_ext(filenames)
	for _, f in pairs(filenames) do
		local n, e = get_extension(f)
		local newname = n .. string.lower(e)
		local t, err = os.rename(f, newname)
	end
	return t, err
end

---Translate a list of characters to another in the given filenames
--@param filenames the files
--@param char_f the characters to translate
--@param char_t the characters to translate to
function translate_chars(filenames, char_f, char_t)
	-- have 2 tables to contain each characters in char_f and char_t
	local from_table = {}
	local to_table = {}
	for _, f in pairs(filenames) do
		local oldname = basename(f) -- save original name
		local newname = oldname -- newname is oldname at the beginning
		-- insert every char in char_f and char_t in corresponding 
		-- tables
		for c in string.gmatch(char_f, ".") do
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
		local t, err = os.rename(f, dirname(f) .. newname)
	end
	return t, err
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
		local t, err = os.rename(f, newname)
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
		local t, err = os.rename(f, newname)
	end
	return t, err
end


function main()
	local f = cli_parse(arg)
	local fil = filelist(f)
end

main()
