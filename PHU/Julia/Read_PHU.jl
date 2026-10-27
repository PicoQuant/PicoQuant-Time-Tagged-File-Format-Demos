# Read_PHU.jl    Read PicoQuant Unified Histogram Files
# This is demo code. Use at your own risk. No warranties.
# Lance (Weiqing) Xu, Arizona State University, May 2025

# Usage: julia --project Read_PHU.jl [inputfile.phu]
# If no input file is given, a file dialog is shown.

# All header data are stored in the dictionary `tagdict` and all histograms
# in the vector `counts`, so they can directly be used for further analysis

using Printf
using Gtk4
using Dates

include("tag.jl")

# start Main program
fullpath = isempty(ARGS) ? open_dialog("PQ histogram data:", nothing, ["*.phu"]) : ARGS[1]
isempty(fullpath) && error("No file selected.")
fid = open(fullpath, "r")

println("")
# Check if inputfile is a valid PHU file
Magic = strip(String(read(fid, 8)), '\0')
if Magic != "PQHISTO"
    close(fid)
    error("Magic invalid, this is not a PHU file.")
end

Version = strip(String(read(fid, 8)), '\0')
@printf("Tag Version: %s\n", Version)

tagdict = get_tagdict(fid)

## Read all histograms
ncurves = tagdict["HistoResult_NumberOfCurves"]
counts = map(1:ncurves) do i
    seek(fid, tagdict["HistResDscr_DataOffset{$i}"])
    read!(fid, Vector{UInt32}(undef, tagdict["HistResDscr_HistogramBins{$i}"]))
end
close(fid)
peak = maximum.(counts)

## Summary
println("\n")
println("=======================================================")
println("                HISTOGRAM DATA SUMMARY                 ")
println("=======================================================")
println("  Curve    Time bin    Number of     Peak     Integral ")
println("  index   resolution   time bins     count     count   ")
println("=======================================================")
for i = 1:ncurves
    @printf(
        "  %3i       %2.6g  %10i  %10i  %10i\n",
        tagdict["HistResDscr_CurveIndex{$i}"],
        tagdict["HistResDscr_MDescResolution{$i}"],
        tagdict["HistResDscr_HistogramBins{$i}"],
        peak[i],
        tagdict["HistResDscr_IntegralCount{$i}"]
    )
end
