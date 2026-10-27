# Read_PTU.jl    Read PicoQuant Unified TTTR Data Files
# This is demo code. Use at your own risk. No warranties.
# Lance (Weiqing) Xu, Arizona State University, May 2025

# Note that marker events have a lower time resolution and may therefore appear
# in the file slightly out of order with respect to regular (photon) event records.
# This is by design. Markers are designed only for relatively coarse
# synchronization requirements such as image scanning.

# T Mode data are written to an output file [filename].out
# We do not keep it in memory because of the huge amout of memory
# this would take in case of large files. Of course you can change this,
# e.g. if your files are not too big.
# Otherwise it is best process the data on the fly and keep only the results.

# Usage: julia --project Read_PTU.jl [inputfile.ptu]
# If no input file is given, a file dialog is shown.

# All header data are stored in the dictionary `tagdict` and can directly be
# used for further analysis

using Printf
using Gtk4
using Dates

include("tag.jl")
include("record.jl")

# start Main program
fullpath = isempty(ARGS) ? open_dialog("T-Mode data:", nothing, ["*.ptu"]) : ARGS[1]
isempty(fullpath) && error("No file selected.")
fid = open(fullpath, "r")

println("")
# Check if inputfile is a valid PTU file
Magic = strip(String(read(fid, 8)), '\0')
if Magic != "PQTTTR"
    close(fid)
    error("Magic invalid, this is not a PTU file.")
end

Version = strip(String(read(fid, 8)), '\0')
@printf("Tag Version: %s\n", Version)

tagdict = get_tagdict(fid)

println("\n----------------------")
# Check recordtype
rectype = tagdict["TTResultFormat_TTTRRecType"]
nrecords = tagdict["TTResult_NumberOfRecords"]
globres = tagdict["MeasDesc_GlobalResolution"]
if !(rectype in T2Set || rectype in T3Set)
    close(fid)
    error("Illegal RecordType!")
end
isT2 = rectype in T2Set
println(RecTypeNames[rectype])

outfile = splitext(fullpath)[1] * ".out"
fpout = open(outfile, "w")
@printf("\nWriting data to %s", outfile)
println("\nThis may take a while...")
# write Header
if isT2
    print(fpout, "  record# Type Ch        TimeTag             TrueTime/ps")
else
    print(
        fpout,
        "  record# Type Ch        TimeTag             TrueTime/ns            DTime",
    )
end

# choose right decode function
if rectype == rtPicoHarpT3
    ReadPT3(fid, fpout, nrecords, globres)
elseif rectype == rtPicoHarpT2
    ReadPT2(fid, fpout, nrecords, globres)
elseif rectype == rtHydraHarpT3
    ReadHT3(fid, fpout, nrecords, globres, 1)
elseif rectype == rtHydraHarpT2
    ReadHT2(fid, fpout, nrecords, globres, 1)
elseif isT2 # rtMultiHarpT2, rtHydraHarp2T2, rtTimeHarp260NT2, rtTimeHarp260PT2
    ReadHT2(fid, fpout, nrecords, globres, 2)
else # rtMultiHarpT3, rtHydraHarp2T3, rtTimeHarp260NT3, rtTimeHarp260PT3
    ReadHT3(fid, fpout, nrecords, globres, 2)
end
close(fid)
close(fpout)
println("Ready!\n")
println("\nStatistics obtained from the data:")
@printf("\n%i photons, %i overflows, %i markers.\n", cnt_ph, cnt_ov, cnt_ma)
