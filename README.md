pdf2png
===========

[pdf2png](http://www.evanjones.ca/pdf2png.html) is command line program for Mac originally written by Evan Jones, 
which convert PDF pages to PNG image files via Cocoa/Quartz rendering engine.

## Build

    $ make

or open `pdf2png.xcodeproj` with XCode.

## Extra features since original implementation

- Added --output option. issue #2
- Added --transparent switch. Now it generates an image with white background by default, and one with transparent background with --transparent switch.
- Now supports PDF files contains various sizes per page.
- [bugfix] out of bounds exception on removeObjectAtIndex, if it is compiled as 64bit binary
- Use stringWithUTF8String for UTF-8 command-line arguments.

## Usage

    pdf2png [options] file
        --dpi dpi       Specifies the resolution at which to export the pages
        --page page     Single page to export
        --transparent   Do not fill background white color, keep transparency from PDF.
        --output path   Specify output file path. This implies --page 1 if not specified. ( Without this option, PDFNAME-p1.png (example) is created on same directory )
        --help  Print this help message
