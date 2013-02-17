from distutils.core import setup

setup(name='Renamer',
        version='0.2',
        author='Gianluca Fiore',
        author_email='forod.g@gmail.com',
        url='http://github.com/Donearm/Renamer',
        download_url='http://github.com/Donearm/Renamer',
        description='File renaming script',
        long_description=open('README.mdown').read(),
        provides=['renamer'],
        keywords='file renaming',
#        license='GNU General Public License',
        license='COPYING',
        classifiers=['Development Status :: 5 - Production/Stable',
            'Environment :: Console',
            'Intended Audience :: End Users/Desktop',
            'Intended Audience :: Developers',
            'License :: OSI Approved :: GNU General Public License (GPL)',
            'Operating System :: OS Independent',
            'Programming Language :: Python :: 3',
            'Topic :: System :: Filesystems',
            'Topic :: Utilities'
            ],
        )

