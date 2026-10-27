# RecordTypes
const rtPicoHarpT3 = 0x00010303 # (SubID = $00, RecFmt: $01) (V1), T-Mode: $03 (T3), HW: $03 (PicoHarp)
const rtPicoHarpT2 = 0x00010203 # (SubID = $00, RecFmt: $01) (V1), T-Mode: $02 (T2), HW: $03 (PicoHarp)
const rtHydraHarpT3 = 0x00010304 # (SubID = $00, RecFmt: $01) (V1), T-Mode: $03 (T3), HW: $04 (HydraHarp)
const rtHydraHarpT2 = 0x00010204 # (SubID = $00, RecFmt: $01) (V1), T-Mode: $02 (T2), HW: $04 (HydraHarp)
const rtHydraHarp2T3 = 0x01010304 # (SubID = $01, RecFmt: $01) (V2), T-Mode: $03 (T3), HW: $04 (HydraHarp)
const rtHydraHarp2T2 = 0x01010204 # (SubID = $01, RecFmt: $01) (V2), T-Mode: $02 (T2), HW: $04 (HydraHarp)
const rtTimeHarp260NT3 = 0x00010305 # (SubID = $00, RecFmt: $01) (V1), T-Mode: $03 (T3), HW: $05 (TimeHarp260N)
const rtTimeHarp260NT2 = 0x00010205 # (SubID = $00, RecFmt: $01) (V1), T-Mode: $02 (T2), HW: $05 (TimeHarp260N)
const rtTimeHarp260PT3 = 0x00010306 # (SubID = $00, RecFmt: $01) (V1), T-Mode: $03 (T3), HW: $06 (TimeHarp260P)
const rtTimeHarp260PT2 = 0x00010206 # (SubID = $00, RecFmt: $01) (V1), T-Mode: $02 (T2), HW: $06 (TimeHarp260P)
const rtMultiHarpT3 = 0x00010307 # (SubID = $00, RecFmt: $01) (V1), T-Mode: $03 (T3), HW: $07 (MultiHarp, PicoHarp330)
const rtMultiHarpT2 = 0x00010207 # (SubID = $00, RecFmt: $01) (V1), T-Mode: $02 (T2), HW: $07 (MultiHarp, PicoHarp330)

const RecTypeNames = Dict(
    rtPicoHarpT3 => "PicoHarp T3 data",
    rtPicoHarpT2 => "PicoHarp T2 data",
    rtHydraHarpT3 => "HydraHarp V1 T3 data",
    rtHydraHarpT2 => "HydraHarp V1 T2 data",
    rtHydraHarp2T3 => "HydraHarp V2 T3 data",
    rtHydraHarp2T2 => "HydraHarp V2 T2 data",
    rtTimeHarp260NT3 => "TimeHarp260N T3 data",
    rtTimeHarp260NT2 => "TimeHarp260N T2 data",
    rtTimeHarp260PT3 => "TimeHarp260P T3 data",
    rtTimeHarp260PT2 => "TimeHarp260P T2 data",
    rtMultiHarpT3 => "MultiHarp/PicoHarp330 T3 data",
    rtMultiHarpT2 => "MultiHarp/PicoHarp330 T2 data",
)

const T2Set = Set([rtPicoHarpT2, rtHydraHarpT2, rtHydraHarp2T2, rtTimeHarp260NT2, rtTimeHarp260PT2, rtMultiHarpT2])

const T3Set = Set([rtPicoHarpT3, rtHydraHarpT3, rtHydraHarp2T3, rtTimeHarp260NT3, rtTimeHarp260PT3, rtMultiHarpT3])

recnum::Int = 0
cnt_ph::Int = 0
cnt_ov::Int = 0
cnt_ma::Int = 0

"""
    extract(x, skip, length)

Extracts `length` bits from `x`, after skipping `skip` bits from the right.
"""
extract(x::UInt32; skip::Integer=0, length::Integer) = (x >> skip) & ((1 << length) - 1)

"""
    gotphoton(fpout, timetag, channel, globres)          # T2
    gotphoton(fpout, timetag, channel, dtime, globres)   # T3

timetag: Raw timetag from Record * Globalresolution = Real Time arrival of Photon
dtime: Arrival time of Photon after last Sync event (T3 only) DTime * Resolution = Real time arrival of Photon after last Sync event
channel: Channel the Photon arrived (0 = Sync channel for T2 measurements)
"""
function gotphoton(fpout, timetag, channel, globres)
    global recnum, cnt_ph
    cnt_ph += 1
    @printf(
        fpout,
        "\n%10i CHN %i %18.0f (%0.1f ps)",
        recnum,
        channel,
        timetag,
        timetag * globres * 1e12
    )
end

function gotphoton(fpout, timetag, channel, dtime, globres)
    global recnum, cnt_ph
    cnt_ph += 1
    @printf(
        fpout,
        "\n%10i CHN %i %18.0f (%0.1f ns) %ich",
        recnum,
        channel,
        timetag,
        timetag * globres * 1e9,
        dtime
    )
end

"""
    gotmarker(fpout, timetag, markers, globres)

timetag: Raw timetag from Record * Globalresolution = Real Time arrival of Photon
markers: Bitfield of arrived markers, different markers can arrive at same time (same record)
"""
function gotmarker(fpout, timetag, markers, globres)
    global recnum, cnt_ma
    cnt_ma += 1
    @printf(
        fpout,
        "\n%10i MAR %i %18.0f (%0.1f ns)",
        recnum,
        markers,
        timetag,
        timetag * globres * 1e9
    )
end

"""
    gotoverflow(fpout, count)

count: Some TCSPC provide Overflow compression = if no Photons between overflow you get one record for multiple Overflows
"""
function gotoverflow(fpout, count)
    global recnum, cnt_ov
    cnt_ov += count
    @printf(fpout, "\n%10i OFL * %i", recnum, count)
end

## Decoder functions

## Read PicoHarp T3
function ReadPT3(fid, fpout, nrecords, globres)
    global recnum
    ofltime = 0
    WRAPAROUND = 65536

    for i = 1:nrecords
        recnum = i
        T3Record = read(fid, UInt32) # all 32 bits
        nsync = extract(T3Record, length=16) # the lowest 16 bits
        channel = extract(T3Record, skip=28, length=4) # the upper 4 bits
        truensync = ofltime + nsync
        if channel ∈ 1:4
            dtime = extract(T3Record, skip=16, length=12)
            gotphoton(fpout, truensync, channel, dtime, globres) # regular count at Ch1, Rt_Ch1 - Rt_Ch4 when the router is enabled
        elseif channel == 15 # special record
            markers = extract(T3Record, skip=16, length=4) # where these four bits are markers
            if markers == 0 # then this is an overflow record
                ofltime += WRAPAROUND # and we unwrap the numsync (=time tag) overflow
                gotoverflow(fpout, 1)
            else # if nonzero, then this is a true marker event
                gotmarker(fpout, truensync, markers, globres)
            end
        else
            @printf(fpout, "Err")
        end
    end
end

## Read PicoHarp T2
function ReadPT2(fid, fpout, nrecords, globres)
    global recnum
    ofltime = 0
    WRAPAROUND = 210698240

    for i = 1:nrecords
        recnum = i
        T2Record = read(fid, UInt32)
        T2time = extract(T2Record, length=28) # the lowest 28 bits
        channel = extract(T2Record, skip=28, length=4) #the next 4 bits
        timetag = T2time + ofltime
        if channel ∈ 0:4
            gotphoton(fpout, timetag, channel, globres)
        elseif channel == 15
            markers = extract(T2Record, length=4) # where the lowest 4 bits are marker bits
            if markers == 0 # then this is an overflow record
                ofltime += WRAPAROUND # and we unwrap the time tag overflow
                gotoverflow(fpout, 1)
            else # otherwise it is a true marker
                gotmarker(fpout, timetag, markers, globres)
            end
        else
            @printf(fpout, "Err")
        end
        # Strictly, in case of a marker, the lower 4 bits of time are invalid because they carry the marker bits. So one could zero them out. However, the marker resolution is only a few tens of nanoseconds anyway, so we can just ignore the few picoseconds of error.
    end
end

## Read HydraHarp/TimeHarp260/MultiHarp/PicoHarp330 T3
function ReadHT3(fid, fpout, nrecords, globres, version)
    global recnum
    OverflowCorrection = 0
    T3WRAPAROUND = 1024

    for i = 1:nrecords
        recnum = i
        T3Record = read(fid, UInt32) # all 32 bits
        nsync = extract(T3Record, length=10) # the lowest 10 bits
        dtime = extract(T3Record, skip=10, length=15) # the next 15 bits
        channel = extract(T3Record, skip=25, length=6) # the next 6 bits
        special = extract(T3Record, skip=31, length=1) # the last bit
        if special == 0   # this means a regular input channel
            # one nsync time unit equals to "syncperiod" which can be calculated from "SyncRate"
            gotphoton(fpout, OverflowCorrection + nsync, channel, dtime, globres)
        elseif channel == 63  # overflow of nsync occured
            if (nsync == 0) || (version == 1) # if nsync is zero it is an old style single oferflow or old Version
                OverflowCorrection += T3WRAPAROUND
                gotoverflow(fpout, 1)
            else # otherwise nsync indicates the number of overflows - THIS IS NEW IN FORMAT V2.0
                OverflowCorrection += T3WRAPAROUND * nsync
                gotoverflow(fpout, nsync)
            end
        elseif channel ∈ 1:15  # these are markers
            gotmarker(fpout, OverflowCorrection + nsync, channel, globres)
        end
    end
end

## Read HydraHarp/TimeHarp260/MultiHarp/PicoHarp330 T2
function ReadHT2(fid, fpout, nrecords, globres, version)
    global recnum
    OverflowCorrection = 0
    T2WRAPAROUND_V1 = 33552000
    T2WRAPAROUND_V2 = 33554432 # = 2^25  IMPORTANT! THIS IS NEW IN FORMAT V2.0

    for i = 1:nrecords
        recnum = i
        T2Record = read(fid, UInt32) # all 32 bits
        dtime = extract(T2Record, length=25) # the lowest 25 bits
        channel = extract(T2Record, skip=25, length=6) # the next 6 bits
        special = extract(T2Record, skip=31, length=1) # the last bit
        # the resolution in T2 mode is 1 ps  - IMPORTANT! THIS IS NEW IN FORMAT V2.0
        timetag = OverflowCorrection + dtime
        if special == 0 # this means a regular photon record
            gotphoton(fpout, timetag, channel + 1, globres)
        elseif channel == 63 # overflow of dtime occured
            if version == 1
                OverflowCorrection += T2WRAPAROUND_V1
                gotoverflow(fpout, 1)
            else
                if dtime == 0 # if dtime is zero it is an old style single oferflow
                    OverflowCorrection += T2WRAPAROUND_V2
                    gotoverflow(fpout, 1)
                else # otherwise dtime indicates the number of overflows - THIS IS NEW IN FORMAT V2.0
                    OverflowCorrection += T2WRAPAROUND_V2 * dtime
                    gotoverflow(fpout, dtime)
                end
            end
        elseif channel == 0 # Sync event
            gotphoton(fpout, timetag, channel, globres)
        elseif channel ∈ 1:15 # these are markers
            gotmarker(fpout, timetag, channel, globres)
        end
    end
end
