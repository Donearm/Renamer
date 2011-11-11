#!/usr/bin/env python2
# -*- coding: utf-8 -*-
#
###############################################################################
# Copyright (c) 2010-2011, Gianluca Fiore <forod.g@gmail.com>
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
import argparse




def argument_parser():
    argparser = argparse.ArgumentParser()
    argparser.add_argument("-s", "--no-spaces",
            help="substitute spaces",
            action="store_true",
            dest="substitute_spaces")
    argparser.add_argument("-a", "--append",
            help="Append string to the end of filenames",
            action="store",
            type=str,
            dest="append_string")
    argparser.add_argument("-p", "--prefix",
            help="Prefix string to filenames",
            action="store",
            type=str,
            dest="prefix_string")
    argparser.add_argument("-r", "--remove",
            help="Remove a string",
            action="store",
            type=str,
            dest="remove_string")
    argparser.add_argument("-m", "--minimize",
            help="Minimize the extension",
            action="store_true",
            dest="minimize_extension")
    argparser.add_argument("-t", "--translate",
            help="Substitute (translate) a series of characters with another",
            action="store",
            dest="translate",
            type=str,
            nargs=2)
    argparser.add_argument("-n", "--numbering",
            help="Rename files adding a numeration",
            action="store",
            type=str,
            dest="numbering",
            nargs=2)
    argparser.add_argument("-d", "--date",
            help="Prepend date to files",
            action="store",
            type=str,
            dest="date_fmt")
    argparser.add_argument("-g", "--gui",
            help="Start the GUI",
            action="store_true",
            dest="gui_enable")
    argparser.add_argument(action="store",
            help="Files",
            dest="files",
            nargs="+")
    options = argparser.parse_args()
    return options


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

def check_length(typ, length):
    """Check that the length for the given type is exactly as it should 
    (length)"""
    if len(typ) != length:
        raise argparse.ArgumentError("You need to give exactly %d arguments" % length)
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
        newname = re.sub(' ', '_', files)
        os.rename(files, newname)

def append_str(filenames, s):
    """Append given string to the end of all filenames"""
    for files in filenames:
        root = os.path.dirname(files)
        oldname = os.path.basename(files)
        newname = root + '/' + oldname + s
        os.rename(files, newname)

def prefix_str(filenames, s):
    """Prefix all filenames with the given string"""
    for files in filenames:
        root = os.path.dirname(files)
        oldname = os.path.basename(files)
        newname = root + '/' + s + oldname
        os.rename(files, newname)

def remove_str(filenames, s):
    """Remove a given string from all filenames"""
    for files in filenames:
        root = os.path.dirname(files)
        oldname = os.path.basename(files)
        if re.search(s, oldname):
            # it's a regexp
            newname = root + '/' + re.sub(s, '', oldname)
        else:
            # not a regexp, simple replace
            newname = root + '/' + oldname.replace(s, '')
        try:
            os.rename(files, newname)
        except OSError:
            # it's possible that the regexp might trying to cancel all the
            # characters in filename. Skip that file
            continue

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
    """Rename every files with the given name and adding a numerations starting 
    at the given number"""
    try:
        n = int(int_start)
    except ValueError:
        # perhaps we forgot to give the int to start numbering, defaulting to 1
        n = 1
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


#class RenamerWindow(QtGui.QMainWindow):
#    def __init__(self, parent=None):
#        QtGui.QWidget.__init__(self, parent)
#
#
#        self.setGeometry(300, 300, 450, 350)
#        self.setWindowTitle('Renamer')
#
#
#        exit_icon = QtGui.QAction(QtGui.QIcon('/usr/share/icons/gnome/24x24/actions/exit.png'), 'Exit', self)
#        exit_icon.setShortcut('Ctrl+Q')
#
#        preferences = QtGui.QAction(QtGui.QIcon('/usr/share/icons/gnome/24x24/categories/preferences-other.png'), 'Preferences', self)
#        preferences.setShortcut('Ctrl+P')
#
#        filedialog = QtGui.QAction(QtGui.QIcon('/usr/share/icons/gnome/24x24/actions/fileopen.png'), 'Open File', self)
#        filedialog.setText('Open File')
#        self.connect(filedialog, QtCore.SIGNAL('activated()'), QtCore.SLOT(QtGui.QFileDialog.getOpenFileName("", "*.py", self, "FileDialog")))
#
#        self.connect(exit_icon, QtCore.SIGNAL('triggered()'), QtCore.SLOT('close()'))
#
#        menubar = self.menuBar()
#        options_menu = menubar.addMenu('&Options')
#        options_menu.addAction(preferences)
#        options_menu.addAction(exit_icon)







def main():
    options = argument_parser()

    # do we want a gui?
    if options.gui_enable:
        try:
            from PyQt4 import QtGui, QtCore
        except:
            sys.exit(1)

            app = QtGui.QApplication(sys.argv)

            w = RenamerWindow()
            w.show()
            app.exec_()
            return

    # get all the filenames
    filenames = filelist(options.files)
    if options.substitute_spaces:
        sub_spaces(filenames)
    elif options.append_string:
        append_str(filenames, options.append_string)
    elif options.prefix_string:
        prefix_str(filenames, options.prefix_string)
    elif options.remove_string:
        remove_str(filenames, options.remove_string)
    elif options.minimize_extension:
        minimize_ext(filenames)
    elif options.translate:
        check_length(options.translate, 2)
        translate_chars(filenames, options.translate[0], options.translate[1])
    elif options.numbering:
        check_length(options.numbering, 2)
        idx_numbering(filenames, options.numbering[0], options.numbering[1])
    elif options.date_fmt:
        prepend_date(filenames, options.date_fmt)
    else:
        print("What do you exactly want to do?")

        

if __name__ == '__main__':
    status = main()
    sys.exit(status)
