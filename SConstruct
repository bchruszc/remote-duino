#!/usr/bin/python

# scons script for the Arduino sketch
# http://code.google.com/p/arscons/
#
# Copyright (C) 2010 by Homin Lee <ff4500@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.

# You'll need the serial module: http://pypi.python.org/pypi/pyserial

# Basic Usage:
# 1. make a folder which have same name of the sketch (ex. Blink/ for Blik.pde)
# 2. put the sketch and SConstruct(this file) under the folder.
# 3. to make the HEX. do following in the folder.
#     $ scons
# 4. to upload the binary, do following in the folder.
#     $ scons upload

# Thanks to:
# * Ovidiu Predescu <ovidiu@gmail.com> and Lee Pike <leepike@gmail.com>
#     for Mac port and bugfix.
#
# This script tries to determine the port to which you have an Arduino
# attached. If multiple USB serial devices are attached to your
# computer, you'll need to explicitly specify the port to use, like
# this:
#
# $ scons ARDUINO_PORT=/dev/ttyUSB0
#
# To add your own directory containing user libraries, pass EXTRA_LIB
# to scons, like this:
#
# $ scons EXTRA_LIB=<my-extra-library-dir>
#
from glob import glob
from path import path
import sys
import re
import os
from itertools import chain

from find_avrdude import get_arduino_paths
from git_util import GitUtil

#Import('SOFTWARE_VERSION')
SOFTWARE_VERSION = '0.Fobel'

pathJoin = os.path.join

ARDUINO_HOME, AVRDUDE_BIN, AVRDUDE_CONF = get_arduino_paths()
print 'found arduino path:', ARDUINO_HOME
print 'using newest avrdude:', AVRDUDE_BIN
print 'using avrdude config:', AVRDUDE_CONF

env = Environment()
platform = env['PLATFORM']

def getUsbTty(rx):
    usb_ttys = glob(rx)
    if len(usb_ttys) == 1: return usb_ttys[0]
    else: return None

AVR_BIN_PREFIX = None
AVRDUDE_PREFIX = None

if platform == 'darwin':
    # For MacOS X, pick up the AVR tools from within Arduino.app
    ARDUINO_HOME_DEFAULT = '/Applications/Arduino.app/Contents/Resources/Java'
    ARDUINO_HOME    = ARGUMENTS.get('ARDUINO_HOME', ARDUINO_HOME_DEFAULT)
    ARDUINO_PORT_DEFAULT = getUsbTty('/dev/tty.usbserial*')
elif platform == 'win32':
    # For Windows, use environment variables.
    #ARDUINO_PORT_DEFAULT = os.environ.get('ARDUINO_PORT')
    ARDUINO_PORT_DEFAULT = 'COM3'
else:
    # For Ubuntu Linux (9.10 or higher)
    ARDUINO_PORT_DEFAULT = getUsbTty('/dev/ttyUSB*')
    AVR_BIN_PREFIX = 'avr-'
    AVRDUDE_PREFIX = path(ARDUINO_HOME) / path('hardware/tools/')

ARDUINO_BOARD_DEFAULT = os.environ.get('ARDUINO_BOARD', 'atmega328')

ARDUINO_PORT    = ARGUMENTS.get('ARDUINO_PORT', ARDUINO_PORT_DEFAULT)
ARDUINO_BOARD   = ARGUMENTS.get('ARDUINO_BOARD', ARDUINO_BOARD_DEFAULT)
ARDUINO_VER     = ARGUMENTS.get('ARDUINO_VER', 22) # Arduino 0022
#RST_TRIGGER     = ARGUMENTS.get('RST_TRIGGER', 'stty hupcl -F ') # use built-in pulseDTR() by default
RST_TRIGGER     = ARGUMENTS.get('RST_TRIGGER', None) # use built-in pulseDTR() by default
EXTRA_LIB       = ARGUMENTS.get('EXTRA_LIB', None) # handy for adding another arduino-lib dir

print 'LIBS!!!', EXTRA_LIB
print 'ARDUINO_PORT:', ARDUINO_PORT

if not ARDUINO_HOME:
    print 'ARDUINO_HOME must be defined.'
    raise KeyError('ARDUINO_HOME')

ARDUINO_CORE = pathJoin(ARDUINO_HOME, 'hardware/arduino/cores/arduino')
ARDUINO_SKEL = pathJoin(ARDUINO_CORE, 'main.cpp')
ARDUINO_CONF = pathJoin(ARDUINO_HOME, 'hardware/arduino/boards.txt')

# Some OSs need bundle with IDE tool-chain
if platform == 'darwin' or platform == 'win32': 
    AVR_BIN_PREFIX = pathJoin(ARDUINO_HOME, 'hardware/tools/avr/bin', 'avr-')

ARDUINO_LIBS = []
if EXTRA_LIB != None:
    ARDUINO_LIBS += [EXTRA_LIB]
ARDUINO_LIBS += [pathJoin(ARDUINO_HOME, 'libraries'), '/home/christian/Documents/dev/arduino/libraries']

# check given board name, ARDUINO_BOARD is valid one
ptnBoard = re.compile(r'^(.*)\.name=(.*)')
boards = {}
#ARDUINO_CONFIG = list(chain(open(ARDUINO_CONF), open('/home/christian/local/opt/arduino-0022/optiboot/optiboot/boards.txt')))
ARDUINO_CONFIG = path(ARDUINO_CONF).lines()
for line in ARDUINO_CONFIG:
    result = ptnBoard.findall(line)
    if result:
        boards[result[0][0]] = result[0][1]

if not ARDUINO_BOARD in boards.keys():
    print ("ERROR! the given board name, %s is not in the supported board list:"%ARDUINO_BOARD)
    print ("all available board names are:")
    for name in sorted(boards.keys()):
        print ("\t%s for %s"%(name.ljust(14), boards[name]))
    print ("however, you may edit %s to add a new board."%ARDUINO_CONF)
    sys.exit(-1)

def getBoardConf(strPtn):
    ptn = re.compile(strPtn)
    for line in ARDUINO_CONFIG:
        result = ptn.findall(line)
        if result:
            return result[0]
    assert(False)

MCU = getBoardConf(r'^%s\.build\.mcu=(.*)'%ARDUINO_BOARD)
F_CPU = getBoardConf(r'^%s\.build\.f_cpu=(.*)'%ARDUINO_BOARD)

# There should be a file with the same name as the folder and with the extension .pde
TARGET = os.path.basename(os.path.realpath(os.curdir))
print os.getcwd()
try:
    assert(os.path.exists(TARGET+'.pde'))
except AssertionError:
    pde_files = path('.').files('*.pde')
    if not len(pde_files) == 1:
        # If there is not exactly one 'pde' file, fail.
        raise
    TARGET = pde_files[0].namebase

cFlags = ['-ffunction-sections', '-fdata-sections', '-fno-exceptions',
    '-funsigned-char', '-funsigned-bitfields', '-fpack-struct', '-fshort-enums',
    '-Os', '-mmcu=%s'%MCU]
envArduino = Environment(CC='"%s"' % (AVR_BIN_PREFIX + 'gcc'),
                        CXX='"%s"' % (AVR_BIN_PREFIX + 'g++'),
                        CPPPATH=['build/core'],
                        CPPDEFINES={'F_CPU': F_CPU, 'ARDUINO': ARDUINO_VER, 'AVR': None,
                                    '___SOFTWARE_VERSION___': '\\"%s\\"' % SOFTWARE_VERSION},
                        CFLAGS=cFlags+['-std=gnu99'], CCFLAGS=cFlags, TOOLS=['gcc','g++'])

def fnProcessing(target, source, env):
    wp = open ('%s'%target[0], 'wb')
    wp.write(open(ARDUINO_SKEL).read())
    # Add this preprocessor directive to localize the errors.
    sourcePath = str(source[0]).replace('\\', '\\\\');
    wp.write('#line 1 "%s"\r\n' % sourcePath)
    wp.write(open('%s'%source[0]).read())
    wp.close()
    return None

envArduino.Append(BUILDERS={'Processing':Builder(action=fnProcessing, suffix='.cpp', src_suffix='.pde')})
envArduino.Append(BUILDERS={'Elf':Builder(action='"%s"' % (AVR_BIN_PREFIX + 'gcc') + ' -mmcu=%s -Os -Wl,--gc-sections -o $TARGET $SOURCES -lm'%MCU)})
envArduino.Append(BUILDERS={'Hex':Builder(action='"%s"' % (AVR_BIN_PREFIX + 'objcopy') + ' -O ihex -R .eeprom $SOURCES $TARGET')})

# add arduino core sources
VariantDir('build/core', ARDUINO_CORE)
gatherSources = lambda x: glob(pathJoin(x, '*.c'))+\
        glob(pathJoin(x, '*.cpp'))+\
        glob(pathJoin(x, '*.S'))
core_sources = gatherSources(ARDUINO_CORE)
core_sources = filter(lambda x: not (os.path.basename(x) == 'main.cpp'), core_sources)
core_sources = map(lambda x: x.replace(ARDUINO_CORE, 'build/core/'), core_sources)

# add libraries
libCandidates = []
ptnLib = re.compile(r'^[ ]*#[ ]*include [<"](.*)\.h[>"]')
for line in open (TARGET+'.pde'):
    result = ptnLib.findall(line)
    if result:
        libCandidates += result

# Hack. In version 20 of the Arduino IDE, the Ethernet library depends
# implicitly on the SPI library.
if ARDUINO_VER >= 20 and 'Ethernet' in libCandidates:
    libCandidates += ['SPI']

all_libs_sources = []
all_lib_names = set()
index = 0
for orig_lib_dir in ARDUINO_LIBS:
    lib_sources = []
    lib_dir = 'build/lib_%02d'%index
    VariantDir(lib_dir, orig_lib_dir)
    for libPath in filter(os.path.isdir, glob(pathJoin(orig_lib_dir, '*'))):
        libName = os.path.basename(libPath)
        if not libName in libCandidates or libName in all_lib_names:
            continue
        all_lib_names.add(libName)
        envArduino.Append(CPPPATH = libPath.replace(orig_lib_dir, lib_dir))
        lib_sources = gatherSources(libPath)
        utilDir = pathJoin(libPath, 'utility')
        if os.path.exists(utilDir) and os.path.isdir(utilDir):
            lib_sources += gatherSources(utilDir)
            envArduino.Append(CPPPATH = utilDir.replace(orig_lib_dir, lib_dir))
        lib_sources = map(lambda x: x.replace(orig_lib_dir, lib_dir), lib_sources)
        all_libs_sources += lib_sources
    index += 1

# Convert sketch(.pde) to cpp
envArduino.Processing('build/'+TARGET+'.cpp', 'build/'+TARGET+'.pde')
VariantDir('build', '.')

sources = ['build/'+TARGET+'.cpp']
sources += all_libs_sources
sources += core_sources
#hybrid_sources = re.split(r'\s+', 'dmf_control_board.cpp  RemoteObject.cpp')
#print hybrid_sources
#sources += hybrid_sources
# Add raw sources which live in sketch dir.
# sources += gatherSources('.')

# Finally Build!!
objs = envArduino.Object(sources) #, LIBS=libs, LIBPATH='.')
envArduino.Elf(TARGET+'.elf', objs)
arduino_hex = envArduino.Hex(TARGET+'.hex', TARGET+'.elf')
Export('arduino_hex')

# Print Size
# TODO: check binary size
MAX_SIZE = getBoardConf(r'^%s\.upload.maximum_size=(.*)'%ARDUINO_BOARD)
print ("maximum size for hex file: %s bytes"%MAX_SIZE)
envArduino.Command(None, TARGET+'.hex', '"%s"' % (AVR_BIN_PREFIX + 'size') + ' --target=ihex $SOURCE')

# Reset
def pulseDTR(target, source, env):
    import serial
    import time
    print 'Resetting Arduino'
    ser = serial.Serial(ARDUINO_PORT)
    ser.setDTR(1)
    time.sleep(1.5)
    ser.setDTR(0)
    ser.close()

#if RST_TRIGGER:
    #reset_cmd = '%s %s' % (RST_TRIGGER, ARDUINO_PORT)
#else:
    #reset_cmd = pulseDTR

# Upload
UPLOAD_PROTOCOL = getBoardConf(r'^%s\.upload\.protocol=(.*)'%ARDUINO_BOARD)
UPLOAD_SPEED = getBoardConf(r'^%s\.upload\.speed=(.*)'%ARDUINO_BOARD)

avrdudeOpts = ['-V', '-F', '-c %s'%UPLOAD_PROTOCOL, '-b %s'%UPLOAD_SPEED,
    '-p %s'%MCU, '-P %s'%ARDUINO_PORT, '-U flash:w:$SOURCES']
if AVRDUDE_CONF:
    avrdudeOpts += ['-C "%s"'%AVRDUDE_CONF]

fuse_cmd = '"%s" %s'%(AVRDUDE_BIN, ' '.join(avrdudeOpts))

#upload = envArduino.Alias('upload', TARGET+'.hex', [reset_cmd, fuse_cmd]);
upload = envArduino.Alias('upload', TARGET+'.hex', [fuse_cmd]);
AlwaysBuild(upload)

# Clean build directory
envArduino.Clean('all', 'build/')

# vim: et sw=4 fenc=utf-8:
