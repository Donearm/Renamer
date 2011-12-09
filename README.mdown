Purpose of the program
======================

Renamer.py is a script to rename files on the command-line, inspired by 
bulk-rename from Thunar but being cli doesn't require any DE/WM.
Adding a gui it's planned though.
Renamer.py it's also python3 ready.

Use
===

Renamer.py tries to follow bulk-rename options as much as possible. 
Thus, many of its operations are similar or equal to the Xfce program.
They are:

* **-s/--no-spaces**	substitute spaces in files with underscores.
* **-a/--append**		append a string to the end of filenames. Particularly useful for files lacking an extenxion.
* **-p/--prefix**		prefix a string to filenames.
* **-r/--remove**		completely remove a string in filenames.
* **-m/--minimize**		make the extension all lowercase.
* **-t/--translate**	translate a serie of characters with another.
* **-n/--numbering**	rename the totality of the filenames adding an incrementing numeration.
* **-d/--date**			add a date to filenames.

License
======

see COPYING
