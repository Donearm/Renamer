#!/usr/bin/env lua

---
-- @author Gianluca Fiore
-- @copyright 2012, Gianluca Fiore <forod.g@gmail.com>
--

function print_help()
	print("Wrong arguments\n")
	print("USAGE:\n")
	print("\trename.lua [-h][-s][-a APPEND_STRING][-p PREFIX_STRING]\n")
	print("\t           [-r REMOVE_STRING][-m][-t TRANSLATE_FROM TRANSLATE_TO]\n")
	print("\t           [-n NAME NUMBERING][-d DATE_FMT] files [files ...]")
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
	for i = #args, 1, -1 do
		local a = arg[i]
		if a:match("^%-h") then
			print_help()
			os.exit(0)
		elseif a:match ("^%-(.*)") then
			if a:match("^%-s") then
				print("Substituting spaces")
			elseif a:match("^%-m") then
				print("Minimize the extension")
			elseif a:match("^%-a") then
				print("Append string")
			elseif a:match("^%-p") then
				print("Prefix string")
			elseif a:match("^%-r") then
				print("Remove string")
			elseif a:match("^%-t") then
				print("Translate")
			elseif a:match("^%-n") then
				print("Numbering")
			elseif a:match("^%-d") then
				print("Add date")
			else
				print_help()
				os.exit(1)
			end
		else
			print(a)
		end
	end
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

---Check if a string is a valid path
--@param path the string to check
function ispath(path)
end

---Given either a valid path or a number of files (or a mix of both), 
--return a list of filenames in the given directory or comprising the 
--files as arguments
--@param ... the path(s) and/or file(s)
function filelist(...)
end

---Substitute all spaces in filename(s) with underscores
--@param filenames the files
function sub_spaces(filenames)
end

---Append a string to the end of all filenames given
--@param filenames the files
--@param s the string to append
function append_str(filenames, s)
end

---Prefix all given filenames with a string
--@param filenames the files
--@param s the string to prefix
function prefix_str(filenames, s)
end

---Remove a string from all given filenames
--@param filenames the files
--@param s the string to remove
function remove_str(filenames, s)
end

---Minimize the extension of given files
--@param filenames the files
function minimize_ext(filenames)
end

---Translate a list of characters to another in the given filenames
--@param filenames the files
--@param char_f the characters to translate
--@param char_t the characters to translate to
function translate_chars(filenames, char_f, char_t)
end

---Rename files with a fixed name and a numbering starting at a given 
--integer
--@param filenames the files
--@param name the string for the new filename
--@param start the integer from which to start the numbering
function idx_numbering(filenames, name, start)
end

---Prepend each file with the current or an arbitrary date
--@param filenames the files
--@param date_fmt the format of the date
function prepend_date(filenames, date_fmt)
end

function main()
	cli_parse(arg)
	check_length(arg, 3)
end

main()
