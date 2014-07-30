{
  ************************************************************************

  PicoHarp 300          File Access Demo in Delphi or Lazarus

  Demo access to binary PicoHarp 300 T2 Mode Files (*.pt2)
  for file format version 2.0 only
  Reads a PicoHarp data file and dump the contents in ASCII
  Michael Wahl, Andreas Podubrin, PicoQuant GmbH, September 2006
  Updated May 2007

  Tested with the following compilers:

  - Delphi 6.0  (Win 32 bit)
  - Delphi 2006 (Win 32 bit)
  - Lazarus 0.9.22

  It should work with most others.
  Observe the 4-byte structure alignment!

  This is demo code. Use at your own risk. No warranties.


  Note that markers have a lower time resolution and may therefore appear
  in the file slightly out of order with respect to regular event records.
  This is by design. Markers are designed only for relatively coarse
  synchronization requirements such as image scanning.


  ************************************************************************
}

program PT2Demo;
{$apptype console}

uses
  SysUtils,
  Math;

const
  NO_ERROR                =         0;
  ERROR_NO_INFILE         =        -1;
  ERROR_NO_OUTFILE        =        -2;
  ERROR_READING_INFILE    =         1;
  ERROR_FALSE_IDENTITY    =         2;
  ERROR_ILLEGAL_BOARD_NO  =         3;
  ERROR_ILLEGAL_MEASMODE  =         4;
  ERROR_EOF_INFILE        =         5;
  ERROR_FALSE_FILEFORMAT  =         6;

  DISPCURVES              =         8;
  T2WRAPAROUND            = 210698240;
  MEASMODE_T2             =         2;
  MEASMODE_T3             =         3;

  RESOL                   =   4.0E-12;   // 4 ps

{
  The following records are used to hold the T2 file data
  They directly reflect the file structure.
  The data types used here match the file structure.
  They may have to be changed for other compilers and/or platforms.
}

type

  { These are subrecords used below }

  TCurveMapping = record
    MapTo,
    Show  : integer;
  end;

  TParamStruct = record
    Start,
    Step,
    Stop  : single;
  end;


  { Readable ASCII file header portion }

  TTxtHdr = record
    Ident           : array [1 ..  16] of char;  // "PicoHarp 300"
    FormatVersion   : array [1 ..   6] of char;  // file format version
    CreatorName     : array [1 ..  18] of char;  // name of creating software
    CreatorVersion  : array [1 ..  12] of char;  // version of creating software
    FileTime        : array [1 ..  18] of char;
    CRLF            : array [1 ..   2] of char;
    CommentField    : array [1 .. 256] of char;
  end;


  { Binary file header information }

  TBinHdr = record
    Curves,
    BitsPerRecord,
    RoutingChannels,
    NumberOfBoards,
    ActiveCurve,
    MeasMode,
    SubMode,
    RangeNo,
    Offset,
    Tacq,                        // in ms
    StopAt,
    StopOnOvfl,
    Restart,
    DispLinLog,
    DispTimeFrom,                // allows only 1ns steps
    DispTimeTo,
    DispCountsFrom,
    DispCountsTo     : longint;
    DispCurves       : array [1 .. DISPCURVES] of TCurveMapping ;
    Params           : array [1 ..  3] of TParamStruct ;
    RepeatMode,
    RepeatsPerCurve,
    RepeatTime,
    RepeatWaitTime   : longint;
    ScriptName       : array [1 .. 20] of char;
  end;


  { Board specific header }

  TBoardHdr = record
    HardwareIdent    : array [1 .. 16] of char ;
    HardwareVersion  : array [1 ..  8] of char ;
    HardwareSerial,
    SyncDivider,
    CFDZeroCross0,
    CFDLevel0,
    CFDZeroCross1,
    CFDLevel1        : longint;
    Resolution       : single;
    // below is new in format version 2.0
    RouterModelCode,
    RouterEnabled,
    RtChan1_InputType,
    RtChan1_InputLevel,
    RtChan1_InputEdge,
    RtChan1_CFDPresent,
    RtChan1_CFDLevel,
    RtChan1_CFDZeroCross,
    RtChan2_InputType,
    RtChan2_InputLevel,
    RtChan2_InputEdge,
    RtChan2_CFDPresent,
    RtChan2_CFDLevel,
    RtChan2_CFDZeroCross,
    RtChan3_InputType,
    RtChan3_InputLevel,
    RtChan3_InputEdge,
    RtChan3_CFDPresent,
    RtChan3_CFDLevel,
    RtChan3_CFDZeroCross,
    RtChan4_InputType,
    RtChan4_InputLevel,
    RtChan4_InputEdge,
    RtChan4_CFDPresent,
    RtChan4_CFDLevel,
    RtChan4_CFDZeroCross : longint;
  end;


  { TTTR mode specific header }

  T_TTTRHdr = record
    ExtDevices,
    Reserved1,
    Reserved2,
    CntRate0,
    CntRate1,
    StopAfter,
    StopReason       : integer;
    Records          : cardinal;
    ImgHdrSize       : integer;
  end;


  { Just to help with data interpretation }

  TDataRecords = record
    channel          : byte;
    dtime            : cardinal;
  end;





var
  inpf         : file;
  outf         : text;

  inpf_opened  : boolean;
  outf_opened  : boolean;

  i,
  result       : integer;

  markers,
  cnt_0,
  cnt_1        : cardinal;

  dbl_0,
  dbl_1        : double;

  ofltime,
  time         : Int64;

  TxtHdr       : TTxtHdr;
  BinHdr       : TBinHdr;
  BoardHdr     : TBoardHdr;
  TTTRHdr      : T_TTTRHdr;

  TTTR_RawData : cardinal;
  TTTR_Data    : TDataRecords;


{
  The following function is needed to convert arrays of characters into
  Pascal Strings. We cannot use strings directly when blockreading the data
  because the length count must be stored in the first byte of the string
  variable in memory
}

function ArrToStr (CharArr : pointer; Len : integer) : string;

  type
    TCharArr   = array [1 .. 256] of char;
    CharArrPtr = ^TCharArr;

  var
    i   : integer;
    str : string;
    lgt : integer;
begin
  str := '';
  lgt := 0;
  for i := 1 to Len
  do begin
    if ((lgt = (i-1)) and (CharArrPtr(CharArr)^[i] <> #0))
    then begin
      str := str + CharArrPtr(CharArr)^[i];
      inc (lgt);
    end;
  end;
  ArrToStr := str;
end;


{
  Just to slightly shorten the program
}

procedure abort_prg (exitcode : integer);
begin
  if inpf_opened then close (inpf);
  if outf_opened then close (outf);
  writeln;
  writeln;
  writeln ('press RETURN');
  {$R-}
    readln;
    halt (exitcode);
  {$R+}
end;



begin

  inpf_opened := false;
  outf_opened := false;
  time        := 0;
  ofltime     := 0;
  cnt_0       := 0;
  cnt_1       := 0;

  writeln ('PicoHarp T2 Mode File Demo');
  writeln ('~~~~~~~~~~~~~~~~~~~~~~~~~~');

  if (ParamCount <> 2)
  then begin
    writeln ('  Usage: pt2demo infile outfile');
    writeln ('  infile is a binary PicoHarp 300 T2 mode file (*.pt2)');
    writeln ('  outfile will be ASCII');
    writeln;
    writeln ('  Note that this is only a demo. Routinely converting T2 data');
    writeln ('  to ASCII is inefficient and therefore discouraged.');
    abort_prg (NO_ERROR);
  end;

  assign (inpf, paramstr(1));
  {$I-}
    reset (inpf, 1);
  {$I+}
  if (IOResult <> 0)
  then begin
    writeln ('cannot open input file');
    abort_prg (ERROR_NO_INFILE);
  end;
  inpf_opened := true;

  assign (outf, paramstr(2));
  {$I-}
    rewrite (outf);
  {$I+}
  if (IOResult <> 0)
  then begin
    writeln ('cannot open output file');
    abort_prg (ERROR_NO_OUTFILE);
  end;
  outf_opened := true;

  blockread (inpf, TxtHdr, SizeOf(TxtHdr), result);
  if (result <> SizeOf(TxtHdr))
  then begin
    writeln ('error reading input file, aborted.');
    abort_prg (ERROR_READING_INFILE);
  end;

  with TxtHdr
  do begin
    writeln (outf, 'Ident            : ', ArrToStr(@Ident,          SizeOf(Ident)));
    writeln (outf, 'Format Version   : ', ArrToStr(@FormatVersion,  SizeOf(FormatVersion)));
    writeln (outf, 'Creator Name     : ', ArrToStr(@CreatorName,    SizeOf(CreatorName)));
    writeln (outf, 'Creator Version  : ', ArrToStr(@CreatorVersion, SizeOf(CreatorVersion)));
    writeln (outf, 'Time of Creation : ', ArrToStr(@FileTime,       SizeOf(FileTime)));
    writeln (outf, 'File Comment     : ', ArrToStr(@CommentField,   SizeOf(CommentField)));

    if (Trim(Ident) <> 'PicoHarp 300')
    then begin
      writeln ('file identifier not found, aborted.');
      abort_prg (ERROR_FALSE_IDENTITY);
    end;

    if (TrimRight(FormatVersion) <> '2.0')
    then begin
      writeln('Error: File format version is ',FormatVersion,'. This program is for v. 2.0 only.');
      abort_prg (ERROR_FALSE_FILEFORMAT);
    end;

  end;

  blockread (inpf, BinHdr, SizeOf(BinHdr), result);
  if (result <> SizeOf (BinHdr))
  then begin
    writeln ('error reading bin header, aborted.');
    abort_prg (ERROR_READING_INFILE);
  end;

  with BinHdr
  do begin
    writeln (outf, 'No of Curves     : ', Curves);
    writeln (outf, 'Bits per Record  : ', BitsPerRecord);
    writeln (outf, 'RoutingChannels  : ', RoutingChannels);
    writeln (outf, 'No of Boards     : ', NumberOfBoards);
    writeln (outf, 'Active Curve     : ', ActiveCurve);
    writeln (outf, 'Measurement Mode : ', MeasMode);
    writeln (outf, 'Sub-Mode         : ', SubMode);
    writeln (outf, 'Range No         : ', RangeNo);
    writeln (outf, 'Offset           : ', Offset);
    writeln (outf, 'AcquisitionTime  : ', Tacq);
    writeln (outf, 'Stop at          : ', StopAt);
    writeln (outf, 'Stop on Ovfl.    : ', StopOnOvfl);
    writeln (outf, 'Restart          : ', Restart);
    writeln (outf, 'DispLinLog       : ', DispLinLog);
    writeln (outf, 'DispTimeAxisFrom : ', DispTimeFrom);
    writeln (outf, 'DispTimeAxisTo   : ', DispTimeTo);
    writeln (outf, 'DispCountAxisFrom: ', DispCountsFrom);
    writeln (outf, 'DispCountAxisTo  : ', DispCountsTo);
    writeln (outf, '---------------------');

    if (MeasMode <> MEASMODE_T2)
    then begin
      writeln ('wrong measurement mode, aborted.');
      abort_prg (ERROR_ILLEGAL_MEASMODE);
    end;

  end;

  blockread (inpf, BoardHdr, SizeOf(BoardHdr), result);
  if (result <> SizeOf(BoardHdr))
  then begin
    writeln ('error reading board header, aborted.');
    abort_prg (ERROR_READING_INFILE);
  end;

  with BoardHdr
  do begin
    writeln (outf, ' HardwareIdent   : ', ArrToStr (@HardwareIdent,   SizeOf(HardwareIdent)));
    writeln (outf, ' HardwareVersion : ', ArrToStr (@HardwareVersion, SizeOf(HardwareVersion)));
    writeln (outf, ' HardwareSerial  : ', HardwareSerial :1);
    writeln (outf, ' SyncDivider     : ', SyncDivider    :1);
    writeln (outf, ' CFDZeroCross0   : ', CFDZeroCross0  :1);
    writeln (outf, ' CFDLevel0       : ', CFDLevel0      :1);
    writeln (outf, ' CFDZeroCross1   : ', CFDZeroCross1  :1);
    writeln (outf, ' CFDLevel1       : ', CFDLevel1      :1);
    writeln (outf, ' Resolution      : ', Resolution     :8:6);

    if (RouterModelCode > 0) //otherwise this information is meaningless
    then begin
      writeln (outf, ' RouterModelCode       : ',RouterModelCode);
      writeln (outf, ' RouterEnabled         : ',RouterEnabled);

      writeln (outf, ' RtChan1_InputType     : ',RtChan1_InputType);
      writeln (outf, ' RtChan1_InputLevel    : ',RtChan1_InputLevel);
      writeln (outf, ' RtChan1_InputEdge     : ',RtChan1_InputEdge);
      writeln (outf, ' RtChan1_CFDPresent    : ',RtChan1_CFDPresent);
      writeln (outf, ' RtChan1_CFDLevel      : ',RtChan1_CFDLevel);
      writeln (outf, ' RtChan1_CFDZeroCross  : ',RtChan1_CFDZeroCross);

      writeln (outf, ' RtChan2_InputType     : ',RtChan2_InputType);
      writeln (outf, ' RtChan2_InputLevel    : ',RtChan2_InputLevel);
      writeln (outf, ' RtChan2_InputEdge     : ',RtChan2_InputEdge);
      writeln (outf, ' RtChan2_CFDPresent    : ',RtChan2_CFDPresent);
      writeln (outf, ' RtChan2_CFDLevel      : ',RtChan2_CFDLevel);
      writeln (outf, ' RtChan2_CFDZeroCross  : ',RtChan2_CFDZeroCross);

      writeln (outf, ' RtChan3_InputType     : ',RtChan3_InputType);
      writeln (outf, ' RtChan3_InputLevel    : ',RtChan3_InputLevel);
      writeln (outf, ' RtChan3_InputEdge     : ',RtChan3_InputEdge);
      writeln (outf, ' RtChan3_CFDPresent    : ',RtChan3_CFDPresent);
      writeln (outf, ' RtChan3_CFDLevel      : ',RtChan3_CFDLevel);
      writeln (outf, ' RtChan3_CFDZeroCross  : ',RtChan3_CFDZeroCross);

      writeln (outf, ' RtChan4_InputType     : ',RtChan4_InputType);
      writeln (outf, ' RtChan4_InputLevel    : ',RtChan4_InputLevel);
      writeln (outf, ' RtChan4_InputEdge     : ',RtChan4_InputEdge);
      writeln (outf, ' RtChan4_CFDPresent    : ',RtChan4_CFDPresent);
      writeln (outf, ' RtChan4_CFDLevel      : ',RtChan4_CFDLevel);
      writeln (outf, ' RtChan4_CFDZeroCross  : ',RtChan4_CFDZeroCross);
    end;

    writeln (outf, '---------------------');
  end;

  blockread(inpf, TTTRHdr, SizeOf(TTTRHdr), result);
  if (result <> SizeOf(TTTRHdr))
  then begin
    writeln ('error reading TTTR header, aborted.');
    abort_prg (ERROR_READING_INFILE);
  end;

  with TTTRHdr
  do begin
    writeln (outf, 'ExtDevices      : ', ExtDevices     :1);
    writeln (outf, 'CntRate0        : ', CntRate0       :1);
    writeln (outf, 'CntRate1        : ', CntRate1       :1);
    writeln (outf, 'StopAfter       : ', StopAfter      :1);
    writeln (outf, 'StopReason      : ', StopReason     :1);
    writeln (outf, 'Records         : ', Records        :1);
    writeln (outf, 'ImgHdrSize      : ', ImgHdrSize     :1);
    writeln (outf, '---------------------');
  end;

  { Skip the special header used for imaging }
  Seek(inpf,FilePos(inpf)+4*TTTRHdr.ImgHdrSize);

  writeln (outf);
  writeln (outf, 'record#  rawdata chan     rawtime     time/4ps       time/sec');
  writeln (outf);

  { Now read and interpret the TTTR records }
  writeln;
  writeln ('processing...');
  writeln;

  for i := 1 to TTTRHdr.Records
  do begin

    if (i mod 1000 = 0) then write('.');

    blockread (inpf, TTTR_RawData , SizeOf(TTTR_RawData ), result);

    if (result <> SizeOf(TTTR_RawData))
    then begin
      writeln ('unexpected end of input file!');
      abort_prg(ERROR_EOF_INFILE);
    end;

    with TTTR_Data
    do begin

      {split "RawData" into its parts}
      dtime   := cardinal ( TTTR_RawData         and $0FFFFFFF);
      channel := byte     ((TTTR_RawData shr 28) and $0000000F);

      if (channel = $0F)                  // this means we have a special record
      then begin
        //in a special record the lower 4 bits of dtime are marker bits
        markers := dtime and $0F;
        if (markers = 0) //this means we have an overflow record
        then begin
          ofltime := ofltime + T2WRAPAROUND;  // unwrap the time tag overflow
          writeln (outf, i-1 : 7,
                    ' f', LowerCase (IntToHex(dtime, 7)):7,
                    '  ofl');
        end
        else begin //it is a marker record
          time := ofltime + dtime;
          writeln (outf, i-1          :7,
                    ' ', LowerCase (IntToHex (channel, 1)):1, LowerCase (IntToHex (dtime, 7)):7,
                    ' MA', markers    :1, ' ',
                    ' ', dtime        :12,
                    ' ', time         :12,
                    ' ', RESOL * time :14:12)
          // Strictly, in case of a marker, the lower 4 bits of dtime are invalid
          // because they carry the marker bits. So one could zero them out.
          // However, the marker resolution is only a few tens of nanoseconds anyway,
          // so we can just ignore the few picoseconds of error.
          // Due to the lower time resolution markers may therefore appear
          // in the file slightly out of order with respect to regular event records.
          // This is by design. Markers are designed only for relatively coarse
          // synchronization requirements such as image scanning.
        end;
      end
      else begin // it is a photon record
        if (channel > BinHdr.RoutingChannels) //Should not occur
        then begin
          writeln (' Illegal Chan: #',i,' ',channel);
          writeln (outf, ' illegal chan.');
          continue;
        end;

        if (channel =0) then inc(cnt_0);
        if (channel>=1) then inc(cnt_1);

        time := ofltime + dtime;

        writeln (outf, i-1          :7,
                  ' ', LowerCase (IntToHex(channel, 1)):1, LowerCase (IntToHex(dtime, 7)):7,
                  ' ', channel      :3,
                  ' ', dtime        :12,
                  ' ', time         :12,
                  ' ', RESOL * time :14:12);

      end;
    end;
  end;

  writeln;
  writeln ('Statistics obtained from the data:');
  writeln ('last tag = ', time  :1, ', ',
           'datalen = ',  TTTRHdr.Records  :1, ', ',
           'cnt_0 = ',    cnt_0 :1, ', ',
           'cnt_1 = ',    cnt_1 :1);

  dbl_0 := cnt_0 / (RESOL*time*1E3);
  dbl_1 := cnt_1 / (RESOL*time*1E3);

  writeln ('measurement time = ', RESOL*time :6:4, ', ',
           'countrate_a = ',      dbl_0      :1:0, ' kHz, ',
           'countrate_b = ',      dbl_1      :1:0, ' kHz');

  abort_prg (NO_ERROR);

end.
