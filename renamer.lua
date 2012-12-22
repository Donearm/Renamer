#!/usr/bin/env lua

---
-- @author Gianluca Fiore
-- @copyright 2012, Gianluca Fiore <forod.g@gmail.com>
--

function print_help()
	print("Wrong number of arguments\n")
	print("USAGE:\n")
	print("\trename.lua [-h][-s][-a APPEND_STRING][-p PREFIX_STRING]\n")
	print("\t           [-r REMOVE_STRING][-m][-t TRANSLATE_FROM TRANSLATE_TO]\n")
	print("\t           [-n NAME NUMBERING][-d DATE_FMT] files [files ...]")
end

function argparse()
end


---Check that the length for the given type is exactly as it should
--@param typ the type
--@param length the desired minimum length
function check_length(typ, length)

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
