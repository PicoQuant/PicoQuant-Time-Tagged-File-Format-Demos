# Tag Types
const tyEmpty8 = 0xFFFF0008
const tyBool8 = 0x00000008
const tyInt8 = 0x10000008
const tyBitSet64 = 0x11000008
const tyColor8 = 0x12000008
const tyFloat8 = 0x20000008
const tyTDateTime = 0x21000008
const tyFloat8Array = 0x2001FFFF
const tyAnsiString = 0x4001FFFF
const tyWideString = 0x4002FFFF
const tyBinaryBlob = 0xFFFFFFFF

"""
    get_tagdict(fid)

Reads all tags up to and including `Header_End`, prints them, and returns them as a dictionary.
Indexed tags are stored as `TagIdent{index}`, with `index` starting from 1.
"""
function get_tagdict(fid)
    tagdict = Dict{String,Any}()
    while true
        tagident = strip(String(read(fid, 32)), '\0')
        tagindex = read(fid, Int32)
        tagtype = read(fid, UInt32)
        evalname = tagident * (tagindex > -1 ? "{" * string(tagindex + 1) * "}" : "")
        @printf("\n   %-40s", evalname)
        add_entry!(tagdict, fid, tagtype, evalname)
        tagident == "Header_End" && break
    end
    return tagdict
end

function add_entry!(tagdict, fid, tagtype, evalname)
    if tagtype == tyEmpty8
        read(fid, Int64)
        print("<Empty>")
        tagdict[evalname] = nothing
    elseif tagtype == tyBool8
        tagbool = read(fid, Int64) != 0
        print(tagbool ? "TRUE" : "FALSE")
        tagdict[evalname] = tagbool
    elseif tagtype == tyInt8
        tagint = read(fid, Int64)
        @printf("%d", tagint)
        tagdict[evalname] = tagint
    elseif tagtype == tyBitSet64
        tagint = read(fid, Int64)
        @printf("%X", tagint)
        tagdict[evalname] = tagint
    elseif tagtype == tyColor8
        tagint = read(fid, Int64)
        @printf("%X", tagint)
        tagdict[evalname] = tagint
    elseif tagtype == tyFloat8
        tagfloat = read(fid, Float64)
        @printf("%e", tagfloat)
        tagdict[evalname] = tagfloat
    elseif tagtype == tyFloat8Array
        tagint = read(fid, Int64)
        @printf("<Float array with %d Entries>", tagint ÷ 8)
        tagdict[evalname] = read!(fid, Vector{Float64}(undef, tagint ÷ 8))
    elseif tagtype == tyTDateTime
        tagfloat = read(fid, Float64) # days since 1899-12-30
        tagtime = Dates.unix2datetime((tagfloat - 25569) * 86400)
        print(tagtime)
        tagdict[evalname] = tagtime
    elseif tagtype == tyAnsiString
        tagint = read(fid, Int64)
        tagstring = String(read(fid, tagint))
        isvalid(tagstring) || (tagstring = String(Char.(codeunits(tagstring)))) # fall back to Latin-1
        tagstring = strip(tagstring, '\0')
        print(tagstring)
        tagdict[evalname] = tagstring
    elseif tagtype == tyWideString
        tagint = read(fid, Int64)
        tagstring = strip(transcode(String, ltoh.(read!(fid, Vector{UInt16}(undef, tagint ÷ 2)))), '\0')
        print(tagstring)
        tagdict[evalname] = tagstring
    elseif tagtype == tyBinaryBlob
        tagint = read(fid, Int64)
        @printf("<Binary Blob with %d Bytes>", tagint)
        skip(fid, tagint)
        tagdict[evalname] = tagint
    else
        error("Illegal Type identifier found! Broken file?")
    end
    return tagdict
end
