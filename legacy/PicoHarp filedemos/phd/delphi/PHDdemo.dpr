{

  PicoHarp 300    File Access Demo in Delphi or Lazarus

  Demo access to binary PicoHarp 300 Data Files (*.phd)
  for file format version 2.0 only!
  Read a PicoHarp 300 data file and dump the contents in ASCII
  Andreas Podubrin, Michael Wahl, PicoQuant GmbH, September  2006
  Updated May 2007


  Tested with the following compilers:

  - Delphi 6.0
  - Delphi 2006
  - Lazarus 0.9.22

  It should work with most others.
  Observe the 4-byte structure alignment!

  This is demo code. Use at your own risk. No warranties.

}

program PHDdemo;
{$apptype console}

uses
  SysUtils;

type

  TCurveMapping = record
    MapTo : longint;
    Show  : boolean;
  end;

  TParamStruct = record
    Start : single;
    Step  : single;
    Stop  : single;
  end;

var
  inf                    :     file;
  outf                   :     text;
  i,j                    :     integer;
  result                 :     integer;
  DateTimeConverter      :     extended;

  {The following structures are used to hold the file data.
    They directly reflect the file structure.
    The data types used here match the file structure.
    They may have to be changed for other compilers and/or platforms.}

  {The following represents the readable ASCII file header portion}

  TxtHdr : record
    Ident                :     array [1.. 16] of char;
    FormatVersion        :     array [1..  6] of char;
    CreatorName          :     array [1.. 18] of char;
    CreatorVersion       :     array [1.. 12] of char;
    FileTime             :     array [1.. 18] of char;
    CRLF                 :     array [1..  2] of char;
    CommentField         :     array [1..256] of char;
  end;

  {The following is binary header information }

  BinHdr : record
    Curves               :     longint;
    BitsPerHistoBin      :     longint;
    RoutingChannels      :     longint;
    NumberOfBoards       :     longint;
    ActiveCurve          :     longint;
    MeasMode             :     longint;
    SubMode              :     longint;
    RangeNo              :     longint;
    Offset               :     longint;
    Tacq                 :     longint;
    StopAt               :     longint;
    StopOnOvfl           :     longint;
    Restart              :     longint;
    DispLinLog           :     longint;
    DispTimeFrom         :     longint;
    DispTimeTo           :     longint;
    DispCountFrom        :     longint;
    DispCountTo          :     longint;
    DispCurves           :     array [1.. 8] of TCurveMapping;
    Params               :     array [1.. 3] of TParamStruct;
    RepeatMode           :     longint;
    RepeatsPerCurve      :     longint;
    RepeatTime           :     longint;
    RepeatWaitTime       :     longint;
    ScriptName           :     array [1..20] of char;
  end;

  {The following is board specific information}

  BoardHdr : record
    HardwareIdent        :     array [1..16] of char;
    HardwareVersion      :     array [1.. 8] of char;
    HardwareSerial       :     longint;
    SyncDivider          :     longint;
    CFDZeroCross0        :     longint;
    CFDLevel0            :     longint;
    CFDZeroCross1        :     longint;
    CFDLevel1            :     longint;
    Resolution           :     single;
    // below is new in format version 2.0
    RouterModelCode      :     longint;
    RouterEnabled        :     longint;
    RtChan1_InputType    :     longint;
    RtChan1_InputLevel   :     longint;
    RtChan1_InputEdge    :     longint;
    RtChan1_CFDPresent   :     longint;
    RtChan1_CFDLevel     :     longint;
    RtChan1_CFDZeroCross :     longint;
    RtChan2_InputType    :     longint;
    RtChan2_InputLevel   :     longint;
    RtChan2_InputEdge    :     longint;
    RtChan2_CFDPresent   :     longint;
    RtChan2_CFDLevel     :     longint;
    RtChan2_CFDZeroCross :     longint;
    RtChan3_InputType    :     longint;
    RtChan3_InputLevel   :     longint;
    RtChan3_InputEdge    :     longint;
    RtChan3_CFDPresent   :     longint;
    RtChan3_CFDLevel     :     longint;
    RtChan3_CFDZeroCross :     longint;
    RtChan4_InputType    :     longint;
    RtChan4_InputLevel   :     longint;
    RtChan4_InputEdge    :     longint;
    RtChan4_CFDPresent   :     longint;
    RtChan4_CFDLevel     :     longint;
    RtChan4_CFDZeroCross :     longint;
  end;

  {The following is for curve storage}

  Curve : array [1..512] of packed record
    CurveIndex           :     longint;
    TimeOfRecording      :     cardinal;
    HardwareIdent        :     array [1..16] of char;
    HardwareVersion      :     array [1.. 8] of char;
    HardwareSerial       :     longint;
    SyncDivider          :     longint;
    CFDZeroCross0        :     longint;
    CFDLevel0            :     longint;
    CFDZeroCross1        :     longint;
    CFDLevel1            :     longint;
    Offset               :     longint;
    RoutingChannel       :     longint;
    ExtDevices           :     longint; //bitweise codiert: externe Geräte (PRT, NRT, ..
    MeasMode             :     longint;
    SubMode              :     longint;
    P1                   :     single;
    P2                   :     single;
    P3                   :     single;
    RangeNo              :     longint;
    Resolution           :     single;
    Channels             :     longint;
    Tacq                 :     longint;
    StopAfter            :     longint;
    StopReason           :     longint;
    InpRate0             :     longint;
    InpRate1             :     longint;
    HistCountRate        :     longint;
    IntegralCount        :     int64;
    reserved             :     longint;
    DataOffset           :     longint;
    // below is new in format version 2.0
    RouterModelCode      :     longint;
    RouterEnabled        :     longint;
    RtChan_InputType     :     longint;
    RtChan_InputLevel    :     longint;
    RtChan_InputEdge     :     longint;
    RtChan_CFDPresent    :     longint;
    RtChan_CFDLevel      :     longint;
    RtChan_CFDZeroCross  :     longint;
  end;

  {Note: Counts (in the file) is of type 32 bit unsigned integer
        The Delphi type CARDINAL is correct for this purpose on 32 bit
        platforms (i.e. x86 with Windows 9x/NT/2K) but this may change on
        different platforms!}

  Counts                 :     array of cardinal;



  {The following function is needed to convert arrays of characters into
  Pascal Strings. We cannot use strings directly when blockreading the data
  because the length count must be stored in the first byte of the string
  variable in memory}

  function ArrToStr (CharArr : pointer; Len : integer) : string;
  type
    CharArrT   = array [1..256] of char;
    CharArrPtr = ^CharArrT;
  var
    i   : integer;
    str : string;
    lgt : integer;
  begin
    str := '';
    lgt := 0;
    for i := 1 to Len
    do begin
      if (  (lgt = (i-1))
        and (CharArrPtr(CharArr)^[i] <> #0))
      then begin
        str := str + CharArrPtr(CharArr)^[i];
        inc (lgt);
      end;
    end;
    ArrToStr := str;
  end;



begin

  if ParamCount <> 2
  then begin
    writeln('Usage: PHDdemo infile outfile');
    writeln('       infile is a binary PicoHarp data file (*.phd)');
    writeln('       outfile will be ASCII');
    writeln('press RETURN');
    readln;
    exit;
  end;

  AssignFile(inf,paramstr(1));
  {$I-}
    reset(inf,1);
  {$I+}
  if IOResult <> 0
  then begin
    writeln('cannot open input file');
    writeln('press RETURN');
    readln;
    exit;
  end;

  AssignFile(outf,paramstr(2));
  {$I-}
  rewrite(outf);
  {$I+}
  if IOResult <> 0
  then begin
    writeln('cannot open output file');
    writeln('press RETURN');
    readln;
    exit;
  end;

  blockread (inf, TxtHdr, SizeOf(TxtHdr), result);
  if result <> SizeOf(TxtHdr)
  then begin
    writeln('error reading text header, aborted.');
    writeln('press RETURN');
    readln;
    exit;
  end;

  with TxtHdr
  do begin
    writeln(outf,'Ident            : ', ArrToStr(@Ident,SizeOf(Ident)));
    writeln(outf,'Format Version   : ', ArrToStr(@FormatVersion,SizeOf(FormatVersion)));
    writeln(outf,'Creator Name     : ', ArrToStr(@CreatorName,SizeOf(CreatorName)));
    writeln(outf,'Creator Version  : ', ArrToStr(@CreatorVersion,SizeOf(CreatorVersion)));
    writeln(outf,'Time of Creation : ', ArrToStr(@FileTime,SizeOf(FileTime)));
    writeln(outf,'File Comment     : ', ArrToStr(@CommentField,SizeOf(CommentField)));

    if (TrimRight (FormatVersion) <> '2.0')
    then  begin
      writeln('Error: File format version is ',FormatVersion,'. This program is for v. 2.0 only.');
      writeln('press RETURN');
      readln;
      exit;
    end;
  end;

  blockread (inf, BinHdr, SizeOf(BinHdr), result);
  if (result <> SizeOf(BinHdr))
  then begin
    writeln('error reading binary header, aborted.');
    writeln('press RETURN');
    readln;
    exit;
  end;

  with BinHdr
  do begin
    writeln(outf,'No of Curves     : ',Curves);
    writeln(outf,'Bits per HistoBin: ',BitsPerHistoBin);
    writeln(outf,'RoutingChannels  : ',RoutingChannels);
    writeln(outf,'No of Boards     : ',NumberOfBoards);
    writeln(outf,'Active Curve     : ',ActiveCurve);
    writeln(outf,'Measurement Mode : ',MeasMode);
    writeln(outf,'Sub-Mode         : ',SubMode);
    writeln(outf,'Range No         : ',RangeNo);
    writeln(outf,'Offset           : ',Offset);
    writeln(outf,'AcquisitionTime  : ',Tacq);
    writeln(outf,'Stop at          : ',StopAt);
    writeln(outf,'Stop on Ovfl.    : ',StopOnOvfl);
    writeln(outf,'Restart          : ',Restart);
    writeln(outf,'DispLinLog       : ',DispLinLog);
    writeln(outf,'DispTimeAxisFrom : ',DispTimeFrom);
    writeln(outf,'DispTimeAxisTo   : ',DispTimeTo);
    writeln(outf,'DispCountAxisFrom: ',DispCountFrom);
    writeln(outf,'DispCountAxisTo  : ',DispCountTo);

    for i:=1 to 8
    do begin
      with DispCurves[i]
      do begin
        writeln(outf,'---------------------');
        writeln(outf,'Curve No ', inttostr(i-1));
        writeln(outf,' MapTo           : ', MapTo);
        if (Show)
        then writeln(outf,' Show            : true')
        else writeln(outf,' Show            : false');
        writeln(outf,'---------------------');
      end;
    end;

    for i:=1 to 3
    do begin
      writeln(outf,'---------------------');
      writeln(outf,'Parameter No ',i-1);
      writeln(outf,' Start           : ',Params[i].Start:8:6);
      writeln(outf,' Step            : ',Params[i].Step:8:6);
      writeln(outf,' End             : ',Params[i].Stop:8:6);
      writeln(outf,'---------------------');
    end;


    writeln(outf,'Repeat Mode      : ',RepeatMode);
    writeln(outf,'Repeats per Curve: ',RepeatsPerCurve);
    writeln(outf,'Repeat Time      : ',RepeatTime);
    writeln(outf,'Repeat wait Time : ',RepeatWaitTime);
    writeln(outf,'Script Name      : ',ArrToStr(@ScriptName,SizeOf(ScriptName)));
  end;

  for i:=1 to BinHdr.NumberOfBoards
  do begin
    writeln(outf,'---------------------');
    blockread (inf, BoardHdr, SizeOf(BoardHdr), result);
    if result <> SizeOf(BoardHdr)
    then begin
      writeln('error reading board header, aborted.');
      exit;
    end;
    with BoardHdr
    do begin
      writeln(outf,'Board No ',inttostr(i-1));
      writeln(outf,' HardwareIdent   : ',ArrToStr(@HardwareIdent,SizeOf(HardwareIdent)));
      writeln(outf,' HardwareVersion : ',ArrToStr(@HardwareVersion,SizeOf(HardwareVersion)));
      writeln(outf,' HardwareSerial  : ',HardwareSerial);
      writeln(outf,' SyncDivider     : ',SyncDivider);
      writeln(outf,' CFDZeroCross0   : ',CFDZeroCross0);
      writeln(outf,' CFDLevel0       : ',CFDLevel0);
      writeln(outf,' CFDZeroCross1   : ',CFDZeroCross1);
      writeln(outf,' CFDLevel1       : ',CFDLevel1);
      writeln(outf,' Resolution      : ',Resolution:8:6);
      if (RouterModelCode > 0)   //otherwise this information is meaningless
      then begin
        writeln(outf,' RouterModelCode       : ',RouterModelCode);
        writeln(outf,' RouterEnabled         : ',RouterEnabled);

        writeln(outf,' RtChan1_InputType     : ',RtChan1_InputType);
        writeln(outf,' RtChan1_InputLevel    : ',RtChan1_InputLevel);
        writeln(outf,' RtChan1_InputEdge     : ',RtChan1_InputEdge);
        writeln(outf,' RtChan1_CFDPresent    : ',RtChan1_CFDPresent);
        writeln(outf,' RtChan1_CFDLevel      : ',RtChan1_CFDLevel);
        writeln(outf,' RtChan1_CFDZeroCross  : ',RtChan1_CFDZeroCross);

        writeln(outf,' RtChan2_InputType     : ',RtChan2_InputType);
        writeln(outf,' RtChan2_InputLevel    : ',RtChan2_InputLevel);
        writeln(outf,' RtChan2_InputEdge     : ',RtChan2_InputEdge);
        writeln(outf,' RtChan2_CFDPresent    : ',RtChan2_CFDPresent);
        writeln(outf,' RtChan2_CFDLevel      : ',RtChan2_CFDLevel);
        writeln(outf,' RtChan2_CFDZeroCross  : ',RtChan2_CFDZeroCross);

        writeln(outf,' RtChan3_InputType     : ',RtChan3_InputType);
        writeln(outf,' RtChan3_InputLevel    : ',RtChan3_InputLevel);
        writeln(outf,' RtChan3_InputEdge     : ',RtChan3_InputEdge);
        writeln(outf,' RtChan3_CFDPresent    : ',RtChan3_CFDPresent);
        writeln(outf,' RtChan3_CFDLevel      : ',RtChan3_CFDLevel);
        writeln(outf,' RtChan3_CFDZeroCross  : ',RtChan3_CFDZeroCross);

        writeln(outf,' RtChan4_InputType     : ',RtChan4_InputType);
        writeln(outf,' RtChan4_InputLevel    : ',RtChan4_InputLevel);
        writeln(outf,' RtChan4_InputEdge     : ',RtChan4_InputEdge);
        writeln(outf,' RtChan4_CFDPresent    : ',RtChan4_CFDPresent);
        writeln(outf,' RtChan4_CFDLevel      : ',RtChan4_CFDLevel);
        writeln(outf,' RtChan4_CFDZeroCross  : ',RtChan4_CFDZeroCross);
      end;
    end;
    writeln(outf,'---------------------');
  end;

 {The following is repeated here for all <NoOfCurves> curves.}

  for i:=1 to BinHdr.Curves
  do begin
    blockread(inf,Curve[i],SizeOf(Curve[i]),result);
    if result <> SizeOf(Curve[i])
    then begin
      writeln('error reading curve header, aborted.');
      writeln('press RETURN');
      readln;
      exit;
    end;

    with Curve[i]
    do begin
      writeln(outf,'---------------------');
      writeln(outf,'Curve Index       : ',CurveIndex);
      DateTimeConverter:=TimeOfRecording/24/60/60+25569;
        // conversion from ctime to TDateTime format
      writeln(outf,'Time of Recording : ',DateTimeToStr(DateTimeConverter));
      writeln(outf);
      writeln(outf,'HardwareIdent     : ',ArrToStr(@HardwareIdent,SizeOf(HardwareIdent)));
      writeln(outf,'HardwareVersion   : ',ArrToStr(@HardwareVersion,SizeOf(HardwareVersion)));
      writeln(outf,'HardwareSerial    : ',HardwareSerial);
      writeln(outf,'SyncDivider       : ',SyncDivider);
      writeln(outf,'CFDZeroCross0     : ',CFDZeroCross0);
      writeln(outf,'CFDLevel0         : ',CFDLevel0);
      writeln(outf,'CFDZeroCross1     : ',CFDZeroCross1);
      writeln(outf,'CFDLevel1         : ',CFDLevel1);
      writeln(outf,'Offset            : ',Offset);
      writeln(outf,'RoutingChannel    : ',RoutingChannel);
      writeln(outf,'ExtDevices        : ',ExtDevices);
      writeln(outf,'Meas. Mode        : ',MeasMode);
      writeln(outf,'Sub-Mode          : ',SubMode);
      writeln(outf,'Par. 1            : ',P1:8:6);
      writeln(outf,'Par. 2            : ',P2:8:6);
      writeln(outf,'Par. 3            : ',P3:8:6);
      writeln(outf,'Range No          : ',RangeNo);
      writeln(outf,'Resolution        : ',Resolution:8:6);
      writeln(outf,'Channels          : ',Channels);
      writeln(outf,'Acq. Time         : ',Tacq);
      writeln(outf,'Stop after        : ',StopAfter);
      writeln(outf,'Stop Reason       : ',StopReason);
      writeln(outf,'InpRate0          : ',InpRate0);
      writeln(outf,'InpRate1          : ',InpRate1);
      writeln(outf,'HistCountRate     : ',HistCountRate);
      writeln(outf,'IntegralCount     : ',IntegralCount);
      writeln(outf,'reserved          : ',reserved);
      writeln(outf,'dataoffset        : ',DataOffset);
      if (RouterModelCode > 0)
      then begin
        writeln(outf,'RouterModelCode      : ',RouterModelCode);
        writeln(outf,'RouterEnabled        : ',RouterEnabled);
        writeln(outf,'RtChan_InputType     : ',RtChan_InputType);
        writeln(outf,'RtChan_InputLevel    : ',RtChan_InputLevel);
        writeln(outf,'RtChan_InputEdge     : ',RtChan_InputEdge);
        writeln(outf,'RtChan_CFDPresent    : ',RtChan_CFDPresent);
        writeln(outf,'RtChan_CFDLevel      : ',RtChan_CFDLevel);
        writeln(outf,'RtChan_CFDZeroCross  : ',RtChan_CFDZeroCross);
      end;
    end;
  end;

  for i:=1 to BinHdr.Curves
  do begin
    seek(inf,Curve[i].DataOffset);
    setlength(Counts,Curve[i].Channels);
    blockread(inf,Counts[0],Curve[i].Channels*SizeOf(Counts[0]),result);
    if result <> Curve[i].Channels*SizeOf(Counts[0])
    then begin
      writeln('error reading count data, aborted.');
      writeln('press RETURN');
      readln;
      exit;
    end;
    writeln(outf,'Counts of curve ',i,' :');
    for j:=0 to length(counts)-1
    do begin
      writeln(outf,Counts[j]);
    end;
    writeln(outf,'---------------------');
  end;

  close(inf);
  close(outf);
  writeln('press RETURN to exit');
  readln;
end.
