# Read_PHU.py    Read PicoQuant Unified TTTR Files
# This is demo code. Use at your own risk. No warranties.
# Keno Goertz, PicoQUant GmbH, February 2018

# Note that marker events have a lower time resolution and may therefore appear 
# in the file slightly out of order with respect to regular (photon) event records.
# This is by design. Markers are designed only for relatively coarse 
# synchronization requirements such as image scanning. 

# T Mode data are written to an output file [filename]
# We do not keep it in memory because of the huge amout of memory
# this would take in case of large files. Of course you can change this, 
# e.g. if your files are not too big. 
# Otherwise it is best process the data on the fly and keep only the results.

import time
import sys
import struct

# Tag Types
tyEmpty8      = struct.unpack(">i", bytes.fromhex("FFFF0008"))[0]
tyBool8       = struct.unpack(">i", bytes.fromhex("00000008"))[0]
tyInt8        = struct.unpack(">i", bytes.fromhex("10000008"))[0]
tyBitSet64    = struct.unpack(">i", bytes.fromhex("11000008"))[0]
tyColor8      = struct.unpack(">i", bytes.fromhex("12000008"))[0]
tyFloat8      = struct.unpack(">i", bytes.fromhex("20000008"))[0]
tyTDateTime   = struct.unpack(">i", bytes.fromhex("21000008"))[0]
tyFloat8Array = struct.unpack(">i", bytes.fromhex("2001FFFF"))[0]
tyAnsiString  = struct.unpack(">i", bytes.fromhex("4001FFFF"))[0]
tyWideString  = struct.unpack(">i", bytes.fromhex("4002FFFF"))[0]
tyBinaryBlob  = struct.unpack(">i", bytes.fromhex("FFFFFFFF"))[0]

if len(sys.argv) != 3:
    print("USAGE: Read_PHU.py inputfile.PHU outputfile.txt")
    exit(0)

inputfile = open(sys.argv[1], "rb")
outputfile = open(sys.argv[2], "w+")

# Check if inputfile is a valid PHU file
# Python strings don't have terminating NULL characters, so they're stripped
magic = inputfile.read(8).decode("ascii").strip('\0')
if magic != "PQHISTO":
    print("ERROR: Magic invalid, this is not a PHU file.")
    exit(0)

version = inputfile.read(8).decode("ascii").strip('\0')
outputfile.write("Tag version: %s\n" % version)

# Write the header data to outputfile and also save it in memory.
# There's no do ... while in Python, so an if statement inside the while loop
# breaks out of it
tagDataList = []    # Contains tuples of (tagName, tagValue)
while True:
    tagIdent = inputfile.read(32).decode("ascii").strip('\0')
    tagIdx = struct.unpack("<i", inputfile.read(4))[0]
    tagTyp = struct.unpack("<i", inputfile.read(4))[0]
    if tagIdx > -1:
        evalName = tagIdent + '(' + str(tagIdx) + ')'
    else:
        evalName = tagIdent
    outputfile.write("\n%-40s" % evalName)
    if tagTyp == tyEmpty8:
        inputfile.read(8)
        outputfile.write("<empty Tag>")
        tagDataList.append((evalName, "<empty Tag>"))
    elif tagTyp == tyBool8:
        tagInt = struct.unpack("<q", inputfile.read(8))[0]
        if tagInt == 0:
            outputfile.write("False")
            tagDataList.append((evalName, "False"))
        else:
            outputfile.write("True")
            tagDataList.append((evalName, "True"))
    elif tagTyp == tyInt8:
        tagInt = struct.unpack("<q", inputfile.read(8))[0]
        outputfile.write("%d" % tagInt)
        tagDataList.append((evalName, tagInt))
    elif tagTyp == tyBitSet64:
        tagInt = struct.unpack("<q", inputfile.read(8))[0]
        outputfile.write("{0:#0{1}x}".format(tagInt,18)) # hex with trailing 0s
        tagDataList.append((evalName, tagInt))
    elif tagTyp == tyColor8:
        tagInt = struct.unpack("<q", inputfile.read(8))[0]
        outputfile.write("{0:#0{1}x}".format(tagInt,18)) # hex with trailing 0s
        tagDataList.append((evalName, tagInt))
    elif tagTyp == tyFloat8:
        tagFloat = struct.unpack("<d", inputfile.read(8))[0]
        outputfile.write("%-3E" % tagFloat)
        tagDataList.append((evalName, tagFloat))
    elif tagTyp == tyFloat8Array:
        tagInt = struct.unpack("<q", inputfile.read(8))[0]
        outputfile.write("<Float array with %d entries>" % tagInt/8)
        tagDataList.append((evalName, tagInt))
    elif tagTyp == tyTDateTime:
        tagFloat = struct.unpack("<d", inputfile.read(8))[0]
        tagTime = int((tagFloat - 25569) * 86400)
        tagTime = time.gmtime(tagTime)
        outputfile.write(time.strftime("%a %b %d %H:%M:%S %Y", tagTime))
        tagDataList.append((evalName, tagTime))
    elif tagTyp == tyAnsiString:
        tagInt = struct.unpack("<q", inputfile.read(8))[0]
        tagString = inputfile.read(tagInt).decode("ascii").strip("\0")
        outputfile.write("%s" % tagString)
        tagDataList.append((evalName, tagString))
    elif tagTyp == tyWideString:
        tagInt = struct.unpack("<q", inputfile.read(8))[0]
        tagString = inputfile.read(tagInt).decode("ascii").strip("\0")
        outputfile.write("%s" % tagString)
        tagDataList.append((evalName, tagString))
    elif tagTyp == tyBinaryBlob:
        tagInt = struct.unpack("<q", inputfile.read(8))[0]
        outputfile.write("<Binary blob with %d bytes>" % tagInt)
        tagDataList.append((evalName, tagInt))
    else:
        print("ERROR: Unknown tag type")
        exit(0)
    if tagIdent == "Header_End":
        break

# Reformat the saved data for easier access
tagNames = [tagDataList[i][0] for i in range(0, len(tagDataList))]
tagValues = [tagDataList[i][1] for i in range(0, len(tagDataList))]

# Write histogram data to file
curveIndices = [tagValues[i] for i in range(0, len(tagNames))\
                if tagNames[i][0:-3] == "HistResDscr_CurveIndex"]
for i in curveIndices:
    outputfile.write("\n-----------------------")
    histogramBins = tagValues[tagNames.index("HistResDscr_HistogramBins(%d)" % i)]
    resolution = tagValues[tagNames.index("HistResDscr_MDescResolution(%d)" % i)]
    outputfile.write("\nCurve#  %d" % i)
    outputfile.write("\nnBins:  %d" % histogramBins)
    outputfile.write("\nResol:  %3E" % resolution)
    outputfile.write("\nCounts:")
    for j in range(0, histogramBins):
        try:
            histogramData = struct.unpack("<i", inputfile.read(4))[0]
        except:
            print("The file ended earlier than expected, at bin %d/%d."\
                  % (j, histogramBins))
        outputfile.write("\n%d" % histogramData)

inputfile.close()
outputfile.close()