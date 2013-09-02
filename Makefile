all: pdf2png

pdf2png: pdf2png.m
	gcc --std=c99 -Wall -g -o pdf2png pdf2png.m -framework Cocoa
