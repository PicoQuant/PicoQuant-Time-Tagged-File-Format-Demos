 {
  PicoQuant Unified TTTR (PTU)    File Access Demo in Pascal

  This is demo code. Use at your own risk. No warranties.

  Tested with Delphi XE5 and Lazarus 1.1 (Freepascal 2.7.1)

  Marcus Sackrow, PicoQuant GmbH, December 2013
}

program PTUDemo;
{$apptype console}
uses
  Classes,
  SysUtils,
  StrUtils,
  Math;

const
  MAX_TAGIDENT_LENGTH      = 31;
  // TagTypes  (TTagHead.Typ)
  tyEmpty8                 = $FFFF0008;
  tyBool8                  = $00000008;
  tyInt8                   = $10000008;
  tyBitSet64               = $11000008;
  tyColor8                 = $12000008;
  tyFloat8                 = $20000008;
  tyTDateTime              = $21000008;
  tyFloat8Array            = $2001FFFF;
  tyAnsiString             = $4001FFFF;
  tyWideString             = $4002FFFF;
  tyBinaryBlob             = $FFFFFFFF;

  // selected Tag Idents (TTagHead.Name) we will need to interpret the subsequent record data
  // check the output of this program and consult the tag dictionary if you need more
  TTTRTagTTTRRecType       = 'TTResultFormat_TTTRRecType';
  TTTRTagNumRecords        = 'TTResult_NumberOfRecords'; // Number of TTTR Records in the File;
  TTTRTagRes               = 'MeasDesc_Resolution';      // Resolution for the Dtime (T3 Only)
  TTTRTagGlobRes           = 'MeasDesc_GlobalResolution';// Global Resolution of TimeTag(T2) /NSync (T3)
  FileTagEnd               = 'Header_End';               // has always to be appended as last tag (BLOCKEND)
  // RecordTypes
  rtPicoHarpT3     = $00010303;    // (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $03 (T3), HW: $03 (PicoHarp)
  rtPicoHarpT2     = $00010203;    // (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $02 (T2), HW: $03 (PicoHarp)
  rtHydraHarpT3    = $00010304;    // (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $03 (T3), HW: $04 (HydraHarp)
  rtHydraHarpT2    = $00010204;    // (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $02 (T2), HW: $04 (HydraHarp)
  rtHydraHarp2T3   = $01010304;    // (SubID = $01 ,RecFmt: $01) (V2), T-Mode: $03 (T3), HW: $04 (HydraHarp)
  rtHydraHarp2T2   = $01010204;    // (SubID = $01 ,RecFmt: $01) (V2), T-Mode: $02 (T2), HW: $04 (HydraHarp)
  rtTimeHarp260NT3 = $00010305;    // (SubID = $01 ,RecFmt: $01) (V2), T-Mode: $03 (T3), HW: $05 (TimeHarp260N)
  rtTimeHarp260NT2 = $00010205;    // (SubID = $01 ,RecFmt: $01) (V2), T-Mode: $02 (T2), HW: $05 (TimeHarp260N)
  rtTimeHarp260PT3 = $00010306;    // (SubID = $01 ,RecFmt: $01) (V2), T-Mode: $03 (T3), HW: $06 (TimeHarp260P)
  rtTimeHarp260PT2 = $00010206;    // (SubID = $01 ,RecFmt: $01) (V2), T-Mode: $02 (T2), HW: $06 (TimeHarp260P)
    // for proper columns choose this
  //{
  COLWIDTH_I64            =        21;
  COLWIDTH_WORD           =         6;
  //}
  // for lesser amount of data choose this
  {
  COLWIDTH_I64            =         0;
  COLWIDTH_WORD           =         0;
  //}
type
  // Tag Entry
  TTagHead = packed record
    Name: array[0..MAX_TAGIDENT_LENGTH] of AnsiChar;  // Identifier of the tag
    Idx: LongInt;                                     // Index for multiple tags or -1
    Typ: Cardinal;                                    // Type of tag ty..... see const section
    TagValue: Int64;                                  // Value of tag.
  end;
var
  InpFile: file;
  OutFile: TextFile;
  Magic: array[0..19] of AnsiChar;
  Version: array[0..19] of AnsiChar;

  TagHead: TTagHead;
  Res: Integer;
  AnsiTemp: PAnsiChar;
  WideTemp: PWideChar;
  StrTemp: string;

  NumRecords: Int64;
  RecordType: Int64;
  n: Int64;
  TTTRRecord: Cardinal;
  OflCorrection: Int64 = 0;

  GlobRes: Double;
  Resolution: Double;
  isT2: Boolean;


// procedures for Photon, overflow, marker


//Got Photon
//  TimeTag: Raw TimeTag from Record * Globalresolution = Real Time arrival of Photon
//  DTime: Arrival time of Photon after last Sync event (T3 only) DTime * Resolution = Real time arrival of Photon after last Sync event
//  Channel: Channel the Photon arrived (0 = Sync channel for T2 measurements)
procedure GotPhoton(TimeTag: Int64; DTime: Integer; Channel: Integer);
begin
  if IsT2 then
    WriteLn(OutFile, n:COLWIDTH_I64, ' CHN ', IntToHex(Channel, 2), ' ', TimeTag:COLWIDTH_I64,' ', Round(TimeTag * GlobRes * 1e12):COLWIDTH_I64)
  else
    WriteLn(OutFile, n:COLWIDTH_I64, ' CHN ', IntToHex(Channel, 2), ' ', TimeTag:COLWIDTH_I64,' ', Round(TimeTag * GlobRes * 1e9):COLWIDTH_I64,' ', DTime:COLWIDTH_WORD)
end;

//Got Marker
//  TimeTag: Raw TimeTag from Record * Globalresolution = Real Time arrival of Photon
//  Markers: Bitfield of arrived Markers, different markers can arrive at same time (same record)
procedure GotMarker(TimeTag: Int64; Markers: Integer);
begin
  WriteLn(OutFile, n:COLWIDTH_I64, ' MAR ', IntToHex(Markers, 2), ' ', TimeTag:COLWIDTH_I64);
end;

//Got Overflow
//  Count: Some TCSPC provide Overflow compression = if no Photons between overflow you get one record for multiple Overflows
procedure GotOverflow(Count: Integer);
begin
  WriteLn(OutFile, n:COLWIDTH_I64, ' OFL *' + IntToStr(Count));
end;


//******************** TTTR-Record inspection **********************************
//

  // HydraHarp T3 Input
procedure ProcessHHT3(TTTR_RawData: Cardinal; Version: Integer);
  const
    T3WRAPAROUND = 1024;
  type
     T_TTTRData = record
       Special: Boolean;
       Channel: Byte;
       DTime,
       NSync: Word;
    end;
  var
    TTTR_Data: T_TTTRData;
    TrueNSync: Int64;
  begin
    with TTTR_Data do
    begin
      {split "RawData" into its parts}
      NSync   := Word   ( TTTR_RawData         and $000003FF);
      DTime   := Word   ((TTTR_RawData shr 10) and $00007FFF);
      Channel := Byte   ((TTTR_RawData shr 25) and $0000003F);
      Special := Boolean((TTTR_RawData shr 31) and $00000001);
      if Special then                                       // this means we have a Special record
      begin
        if (Channel = $3F) then                               // overflow
        begin
          case Version of
            1: begin
              GotOverflow(1);
              OflCorrection := OflCorrection + T3WRAPAROUND;
            end;
            2: begin
              // number of overflows is stored in nsync
              // if it is zero, it is an old style single overflow {should never happen with new Firmware}
              GotOverflow(ifthen(NSync = 0, 1, NSync));
              OflCorrection := OflCorrection + Int64(T3WRAPAROUND) * ifthen(NSync = 0, 1, NSync);
            end;
          end;
        end else
        if ((Channel > 0) and (Channel <= 15)) then          //markers
        begin
          TrueNSync := OflCorrection + NSync;
          GotMarker(TrueNSync, Channel);
        end
      end else
      begin                                                 //regular input Channel
        TrueNSync := OflCorrection + NSync;
        GotPhoton(TrueNSync, DTime, Channel + 1);
      end;
    end;
  end;

// HydraHarp T2 input
procedure ProcessHHT2(TTTR_RawData: Cardinal; Version: Integer);
const
  T2WRAPAROUND_V1 = 33552000;
  T2WRAPAROUND_V2 = 33554432;
type
  TDataRecords = record
    Special: Boolean;
    Channel: Byte;
    DTime: Cardinal;
  end;
var
  TTTR_Data: TDataRecords;
begin
  with TTTR_Data do
  begin
    {split "RawData" into its parts}
    DTime   := Cardinal ( TTTR_RawData         and $01FFFFFF);
    Channel := Byte     ((TTTR_RawData shr 25) and $0000003F);
    Special := Boolean  ((TTTR_RawData shr 31) and $00000001);
    if (Special)then                  // this means we have a Special record
    begin
      if (Channel = $3F) then        // overflow
      begin
        case Version of
          1: begin
            GotOverflow(1);
            OflCorrection := OflCorrection + T2WRAPAROUND_V1;
          end;
          2: begin
            // number of overflows is stored in timetag
            // if it is zero, it is an old style single oferflow {should never happen with new Firmware}
            GotOverflow(ifthen(DTime = 0, 1, DTime));
            OflCorrection := OflCorrection + Int64(T2WRAPAROUND_V2) * ifthen(DTime = 0, 1, DTime);
          end;
        end;
      end else
        if (Channel = 0) then        // sync
        begin
          GotPhoton(OflCorrection + DTime, 0, 0);
        end else
          if (Channel <= 15) then   // markers
          begin
            // Note that actual marker tagging accuracy is only some ns.
            GotMarker(OflCorrection + DTime, Channel);
          end else
            WriteLn(OutFile, n:COLWIDTH_I64, ' ERR');
    end else
    begin // it is a regular photon record
      GotPhoton(OflCorrection + DTime, 0, Channel + 1);
    end;
  end;
end;

// PicoHarp T3 input
procedure ProcessPHT3(Value: Cardinal);
const
  T3WRAPAROUND = 65536;
type
  T_TTTRData = record
    NumSync,
    Data: Word;
  end;
  TDataRecords = record
    Channel: Byte;
    case Boolean of
      True:  (DTime: Word);
      False: (Markers: Word);
  end;
var
  TTTR_RawData: T_TTTRData;
  TTTR_Data: TDataRecords;
  TrueNSync: Int64;
begin
  TTTR_RawData := T_TTTRData(Value);
  with TTTR_Data, TTTR_RawData do
  begin
      {split joined parts of "RawData"}
      Markers := word ( TTTR_RawData.Data         and $00000FFF);   // resp. DTime
      Channel := byte ((TTTR_RawData.Data shr 12) and $0000000F);
      if (Channel = $0F) then                                // this means we have a special record
      begin
        if (Markers = 0) then                                // missing marker means overflow
        begin
          GotOverflow(1);
          OflCorrection := OflCorrection + T3WRAPAROUND;     // unwrap the time tag overflow
        end else
        begin // a marker
          TrueNSync := OflCorrection + NumSync;
          GotMarker(TrueNSync, Markers);
        end
      end
      else begin // a photon record
        if ((Channel = 0)             // Should never occur in T3 Mode
          or (Channel > 4) ) then     // Should not occur with current routers
        begin
          WriteLn('illegal Channel: ', Channel);
          WriteLn(OutFile, 'illegal Channel');
        end;
        TrueNSync := OflCorrection + NumSync;
        GotPhoton(TrueNSync, DTime, Channel);
      end;
    end;
end;

// PicoHarp T2 input
procedure ProcessPHT2(TTTR_RawData: Cardinal);
const
  T2WRAPAROUND = 210698240;
type
  TDataRecords = record
    Channel: Byte;
    DTime: Cardinal;
  end;
var
  TTTR_Data: TDataRecords;
  Time: Int64;
  Markers: Cardinal;
begin
  with TTTR_Data
    do begin
      {split "RawData" into its parts}
      DTime   := Cardinal ( TTTR_RawData         and $0FFFFFFF);
      Channel := Byte     ((TTTR_RawData shr 28) and $0000000F);

      if (Channel = $0F) then             // this means we have a special record
      begin
        //in a special record the lower 4 bits of DTime are marker bits
        Markers := DTime and $0F;
        if (Markers = 0) then             //this means we have an overflow record
        begin
          GotOverflow(1);
          OflCorrection := OflCorrection + T2WRAPAROUND;  // unwrap the Time tag overflow
        end else
        begin                             //it is a marker record
          Time := OflCorrection + DTime;
          GotMarker(Time, Markers);
          // Strictly, in case of a marker, the lower 4 bits of DTime are invalid
          // because they carry the marker bits. So one could zero them out.
          // However, the marker resolution is only a few tens of nanoseconds anyway,
          // so we can just ignore the few picoseconds of error.
          // Due to the lower Time resolution markers may therefore appear
          // in the file slightly out of order with respect to regular event records.
          // This is by design. markers are designed only for relatively coarse
          // synchronization requirements such as image scanning.
        end;
      end else
      begin                               // it is a photon record
        if (Channel > 4) //Should not occur
        then begin
          WriteLn(' Illegal Chan: ', Channel);
          WriteLn(OutFile, ' Illegal chan.');
        end;
        Time := OflCorrection + DTime;
        GotPhoton(Time, 0, Channel);
      end;
    end;
end;

//
//******************************************************************************



//*********************** Main Program *****************************************
begin
try
  NumRecords := -1;
  RecordType := 0;
  GlobRes := 0.0;
  Resolution:= 0.0;

  Res := 0;
  Magic[0] := #0;
  Version[0] := #0;
  TagHead.Name[0] := #0;
  TTTRRecord := 0;

  WriteLn('PicoQuant Unified TTTR (PTU) Mode File Demo');
  WriteLn('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');

  if (ParamCount <> 2) then
  begin
    WriteLn('  Usage: ptudemo infile outfile');
    WriteLn;
    WriteLn('  infile  is a binary mode file (*.ptu)');
    WriteLn('  outfile will be ASCII');
    WriteLn;
    WriteLn('  Note that this is only a demo. Routinely converting T3/T2 data');
    WriteLn('  to ASCII is inefficient and therefore discouraged.');
    Exit;
  end;

  // Open Input File
  AssignFile(InpFile, ParamStr(1));
  {$I-}
    Reset(InpFile, 1);
  {$I+}
  if (IOResult <> 0) then
  begin
    WriteLn('Cannot open input file '+ ParamStr(1) + ' error code: ' + IntToStr(IOResult));
    Exit;
  end;
  WriteLn('Loading data from ', ParamStr(1));

  // Open Output file
  AssignFile(OutFile, ParamStr(2));
  {$I-}
    ReWrite(OutFile);
  {$I+}
  if (IOResult <> 0)
  then begin
    WriteLn ('Cannot open output file ' + ParamStr(2) + ' error code: ' + IntToStr(IOResult));
    CloseFile(InpFile);
    Exit;
  end;
  WriteLn ('Writing output to ', ParamStr(2));

// Start Header loading
  try
    // get Magic and TagFile Version
    FillChar(Magic[0], Length(Magic), #0);
    FillChar(Version[0], Length(Version), #0);
    BlockRead(InpFile, Magic[0], 8, Res);
    BlockRead(InpFile, Version[0], 8, Res);
    // Check Magic for TTTR File
    if StrComp(Magic, 'PQTTTR') <> 0 then
    begin
      Writeln('Wrong Magic, this is not a PTU file.');
      Exit;
    end;
    Writeln(OutFile, 'Tag Version: ' + Version);
    repeat
      // Read tagged Header
      BlockRead(InpFile, TagHead, SizeOf(TagHead), Res);
      if Res < SizeOf(TagHead) then
      begin
        WriteLn('Incomplete File.');
        Exit;
      end;
      StrTemp := TagHead.Name;
      if TagHead.Idx > - 1 then
        StrTemp := StrTemp + '(' + IntToStr(TagHead.Idx) + ')';
      Write(OutFile, Format('%-40s', [StrTemp]));
      // Inspect Value by Type
      case TagHead.typ of
        tyEmpty8: begin                    // Empty8
          write(OutFile, '<Empty>');
        end;
        tyBool8: begin                     // Bool8
          if LongBool(TagHead.TagValue) then
            Write(OutFile, 'True')
          else
            Write(OutFile, 'False');
        end;
        tyInt8: begin                      // Int8
          Write(OutFile, IntToStr(TagHead.TagValue));
          // get some Values we need to analyse records
          if TagHead.Name = TTTRTagNumRecords then // Number of records
            NumRecords := TagHead.TagValue;
          if TagHead.Name = TTTRTagTTTRRecType then // TTTR RecordType
            RecordType := TagHead.TagValue;
        end;
        tyBitSet64: begin                  // BitSet64
          Write(OutFile, '$' + IntToHex(TagHead.TagValue, 16));
        end;
        tyColor8: begin                    // Color8
          Write(OutFile, '$' + IntToHex(TagHead.TagValue, 16));
        end;
        tyFloat8: begin                    // Float8
          Write(OutFile, FloatToStr(Double((@TagHead.TagValue)^)));
          if TagHead.Name = TTTRTagRes then      // Resolution for TCSPC-Decay
            Resolution := Double((@TagHead.TagValue)^); // in s
          if TagHead.Name = TTTRTagGlobRes then  // Global resolution for timetag
            GlobRes := Double((@TagHead.TagValue)^);    // in s
        end;
        tyFloat8Array: begin               // FloatArray
          Write(OutFile, '<Float array with ' + IntToStr(TagHead.TagValue div SizeOf(Double)) + ' Entries>');
          // only seek the Data, if one needs the data, it can be loaded here or remember the position
          // and length for later reading
          Seek(InpFile, FilePos(InpFile) + TagHead.TagValue);
        end;
        tyTDateTime: begin                 //TDateTime
          Write(OutFile, DateTimeToStr(Double((@TagHead.TagValue)^)));
        end;
        tyAnsiString: begin                // AnsiString
          GetMem(AnsiTemp, TagHead.TagValue);
          try
            BlockRead(InpFile, AnsiTemp^, TagHead.TagValue, Res);
            Write(OutFile, string(AnsiTemp));
          finally
            Freemem(AnsiTemp);
          end;
        end;
        tyWideString:begin                 // WideString
          GetMem(WideTemp, TagHead.TagValue);
          try
            BlockRead(InpFile, WideTemp^, TagHead.TagValue, Res);
            Write(OutFile, string(WideTemp));
          finally
            Freemem(WideTemp);
          end;
        end;
        tyBinaryBlob: begin               // BinaryBlob
          Write(OutFile, '<Binary Blob contains ' + IntToStr(TagHead.TagValue) + ' Bytes>');
          // only seek the Data, if one needs the data, it can be loaded here or remember the position
          // and length for later reading
          Seek(InpFile, FilePos(InpFile) + TagHead.TagValue);
        end;
        else begin                         // Unknown Type
          Writeln('Illegal Type identifier found! Broken file?');
          Exit;
        end;
      end; //Case
      WriteLn(OutFile, '');
      // FileTagEnd marks the end of Headerarea -> after this tags the TTTR record begin
    until (Trim(string(TagHead.Name)) = FileTagEnd);
    WriteLn(OutFile, '-----------------------');
// End Header loading

// Start TTTR Record section
    // print TTTR Record type
    case RecordType of
      rtPicoHarpT3: WriteLn(OutFile, 'PicoHarp T3 data');
      rtPicoHarpT2: WriteLn(OutFile, 'PicoHarp T2 data');
      rtHydraHarpT2: WriteLn(OutFile, 'HyraHarp V1 T3 data');
      rtHydraHarpT3: WriteLn(OutFile, 'HydraHarp V1 T2 data');
      rtHydraHarp2T2: WriteLn(OutFile, 'HyraHarp V2 T3 data');
      rtHydraHarp2T3: WriteLn(OutFile, 'HydraHarp V2 T2 data');
      rtTimeHarp260NT2: WriteLn(OutFile, 'TimeHarp260N T3 data');
      rtTimeHarp260NT3: WriteLn(OutFile, 'TimeHarp260N T2 data');
      rtTimeHarp260PT2: WriteLn(OutFile, 'TimeHarp260P T3 data');
      rtTimeHarp260PT3: WriteLn(OutFile, 'TimeHarp260P T2 data');
      else
        begin
          WriteLn('unknown Record type: $' + IntToHex(RecordType, 8));
          Exit;
        end;
    end;
    isT2 := (RecordType = rtPicoHarpT2) or (RecordType = rtHydraHarpT2) or
      (RecordType = rtHydraHarp2T2);
    if isT2 then
      WriteLn(OutFile, 'record#':COLWIDTH_I64, ' Typ Ch ', 'TimeTag':COLWIDTH_I64, ' ', 'TrueTime/ps':COLWIDTH_I64)
    else
      WriteLn(OutFile, 'record#':COLWIDTH_I64, ' Typ Ch ', 'TimeTag':COLWIDTH_I64, ' ', 'TrueTime/ns':COLWIDTH_I64, ' ', 'DTime':COLWIDTH_WORD);
// read the tttr Records
    n := -1;
    while (n+1 < NumRecords) do
    begin
      inc(n);
      if (n mod 1000 = 0) then
        if (n mod 100000 = 0) then
          write('+')
        else
          write('-');
      // Read Record
      BlockRead (InpFile, TTTRRecord , SizeOf(TTTRRecord), Res);
      if (Res <> SizeOf(TTTRRecord)) then
      begin
        writeln('Unexpected end of input file!');
        Exit;
      end;
      // Analyse record
      case RecordType of
          // PicoHarp
        rtPicoHarpT3: ProcessPHT3(TTTRRecord);
        rtPicoHarpT2: ProcessPHT2(TTTRRecord);
          // HydraHarp V1
        rtHydraHarpT2: ProcessHHT2(TTTRRecord, 1);
        rtHydraHarpT3: ProcessHHT3(TTTRRecord, 1);
          // HydraHarp V2 + TimeHarp260N+P
        rtHydraHarp2T2,
        rtTimeHarp260NT2,
        rtTimeHarp260PT2: ProcessHHT2(TTTRRecord, 2);
        rtHydraHarp2T3,
        rtTimeHarp260NT3,
        rtTimeHarp260PT3: ProcessHHT3(TTTRRecord, 2);
      end;
    end;
  finally
    CloseFile(InpFile);
    CloseFile(OutFile);
  end;
finally
  writeln;
  writeln;
  writeln ('press RETURN');
  {$R-}
    readln;
  {$R+}
end;
end.

