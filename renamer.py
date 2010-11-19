#!/usr/bin/env python2
# -*- coding: utf-8 -*-
#
###############################################################################
# Copyright (c) 2010, Gianluca Fiore
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
###############################################################################

__author__ = "Gianluca Fiore"
__license__ = "GPL"
__version__ = "0.2"
__date__ = "18/11/2010"
__email__ = "forod.g@gmail.com"

import os
import re
import sys
import datetime
from optparse import OptionParser, OptionValueError
from PyQt4 import QtGui, QtCore



def argument_parser():
    usage = "Usage: %prog [options] paths"
    arguments = OptionParser(usage=usage, version="%prog 0.1")
    arguments.add_option("-s", "--no-spaces",
            help="substitute spaces",
            action="store_true",
            dest="substitute_spaces")
    arguments.add_option("-a", "--append",
            help="Append string to filenames",
            action="store",
            type="string",
            dest="append_string")
    arguments.add_option("-r", "--remove",
            help="Remove a string",
            action="store",
            type="string",
            dest="remove_string")
    arguments.add_option("-m", "--minimize",
            help="Minimize the extension",
            action="store_true",
            dest="minimize_extension")
    arguments.add_option("-t", "--translate",
            help="Substitute (translate) a series of characters with another",
            action="store",
            dest="translate",
            type="string",
            nargs=2)
    arguments.add_option("-n", "--numbering",
            help="Rename files adding a numeration",
            action="store",
            type="string",
            dest="numbering",
            nargs=2)
    arguments.add_option("-d", "--date",
            help="Prepend date to files",
            action="store",
            type="string",
            dest="date_fmt")
    arguments.add_option("-g", "--gui",
            help="Start the GUI",
            action="store_true",
            dest="gui_enable")
    (options, args) = arguments.parse_args()
    #print(options)
    #print(args)

    return options.substitute_spaces, options.append_string, options.remove_string, \
            options.minimize_extension, options.translate, options.numbering, \
            options.date_fmt, options.gui_enable, args

def cbk_translate(option, opt_str, value, parser):
    """Callback function for translate"""
    value = [] 

    for arg in parser.rargs:
        if arg[:2] == "--" and len(arg) > 2:
            break
        if arg[:1] == "-" and len(arg) > 1:
            break
        value.append(arg)

        del parser.rargs[:len(value)]
        setattr(parser.values, option.dest, value)

def check_length(type, length):
    """Check that the length for the given type is exactly as it should (length)"""
    if len(type) != length:
        raise OptionValueError("You need to give exactly %d arguments" % length)
    else:
        return True

def ispath(path):
    """Exit if path is not a correct path"""
    if os.path.isdir(path):
        return True
    else:
        sys.stderr.write("You must give a valid path")
        sys.exit(1)

def filelist(*args):
    """Given or a valid path or a number of files (or both), return a list
    of filenames in the given directory or comprising the files as arguments"""
    filenames = []
    for a in args:
        for i in a:
            # set some variables about the file
            bname = os.path.basename(i)
            dname = os.path.dirname(i)
            root = os.path.abspath(dname)
            completename = root + '/' + bname
            if os.path.isfile(completename):
                filenames.append(completename)
            elif ispath(i):
                for files in os.listdir(i):
                    fl = os.path.join(root, files)
                    if os.path.isfile(fl):
                        filenames.append(fl)
            else:
                print("Not a path and not a file, check the list of arguments")

        #fll = [fille for fille in os.listdir(path) if os.path.isfile(os.path.join(root, files))]
    return filenames

def sub_spaces(filenames):
    """Substitute all spaces in filenames with underscores"""
    for files in filenames:
        newname = files.translate(bytes.maketrans(b' ', b'_'))
        os.rename(files, newname)

def append_str(filenames, s):
    """Append given string to all filenames"""
    for files in filenames:
        root = os.path.dirname(files)
        oldname = os.path.basename(files)
        newname = root + '/' + s + oldname
        os.rename(files, newname)

def remove_str(filenames, s):
    """Remove a given string from all filenames"""
    for files in filenames:
        root = os.path.dirname(files)
        newname = root + '/' + os.path.basename(files).replace(s, '')
        os.rename(files, newname)

def minimize_ext(filenames):
    """Minimize all file extensions of given files"""
    for files in filenames:
        name, ext = os.path.splitext(files)
        os.rename(files, name + ext.lower())

def translate_chars(filenames, char_f, char_t):
    """Translate every given characters in filenames to another character"""
    for files in filenames:
        root = os.path.dirname(files)
        oldname = os.path.basename(files)
        newname = root + '/' + re.sub(char_f, char_t, oldname)
        os.rename(files, newname)

def idx_numbering(filenames, name, int_start):
    """Rename every files with the given name and adding a numerations starting at the given number"""
    n = int(int_start)
    # filenames must be sorted beforehand
    for files in sorted(filenames):
        root = os.path.dirname(files)
        oldname, ext = os.path.splitext(files)
        # prefix enough 0 if the number is not already at least 3 digits long
        if n < 10:
            idx = '00' + str(n)
        elif n >= 10 and n < 100:
            idx = '0' + str(n)
        else:
            idx = str(n)
        newname = root + '/' + name + idx + ext
        n += 1
        os.rename(files, newname)

def prepend_date(filenames, date_fmt):
    """Prepend each files with the current date"""
    today = datetime.date.today()
    print("If you want to use a date different from today's, append it directly as a string")
    for files in filenames:
        root = os.path.dirname(files)
        oldname = os.path.basename(files)
        newname = root + '/' + today.strftime(date_fmt) + '-' + oldname
        os.rename(files, newname)


class RenamerWindow(QtGui.QWidget):
    def __init__(self, parent=None):
        QtGui.QWidget.__init__(self, parent)


        self.setGeometry(300, 300, 450, 350)
        self.setWindowTitle('Renamer')

        listwidg = QtGui.QListWidget()
        listwidg.move(1, 1)
        listwidg.insertItem(1, 'aaa')
        listwidg.insertItem(2, 'bbb')




def main():
    substitute_spaces, append_string, remove_string, minimize_extension, translate, numbering, date_fmt, gui_enable, args = argument_parser()

    # do we want a gui?
    if gui_enable:
        app = QtGui.QApplication(sys.argv)

        w = RenamerWindow()
        w.show()
        app.exec_()
        return

    # get all the filenames
    filenames = filelist(args)
    if substitute_spaces:
        sub_spaces(filenames)
    elif append_string:
        append_str(filenames, append_string)
    elif remove_string:
        remove_str(filenames, remove_string)
    elif minimize_extension:
        minimize_ext(filenames)
    elif translate:
        check_length(translate, 2)
        translate_chars(filenames, translate[0], translate[1])
    elif numbering:
        check_length(numbering, 2)
        idx_numbering(filenames, numbering[0], numbering[1])
    elif date_fmt:
        prepend_date(filenames, date_fmt)
    else:
        print("What do you want exactly do?")

        

if __name__ == '__main__':
    status = main()
    sys.exit(status)
