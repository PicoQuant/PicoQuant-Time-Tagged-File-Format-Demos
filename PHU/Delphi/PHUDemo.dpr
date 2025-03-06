 {
  PicoQuant Unified Histogram (PHU) File Access Demo in Pascal

  This is demo code. Use at your own risk. No warranties.

  Tested with Delphi XE5 and Lazarus 1.1 (Freepascal 2.7.1)

  Marcus Sackrow, Michael Wahl, PicoQuant GmbH, December 2013
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

  // selected Tag Idents (TTagHead.Name) we will need to interpret the histogram data
  // check the output of this program and consult the tag dictionary if you need more
  PHUTagNumCurves          = 'HistoResult_NumberOfCurves';  // Number of histograms (curves) in the file;
  PHUTagDataOffset         = 'HistResDscr_DataOffset';      // File offset of binary histogram data
  PHUTagHistogramBins      = 'HistResDscr_HistogramBins';   // Number of bins in histogram
  PHUTagHistResol          = 'HistResDscr_MDescResolution'; // Histogram bin width in seconds
  FileTagEnd               = 'Header_End';                  // Always appended as last tag (BLOCKEND)

  MAXCURVES               = 512;
  MAXHISTBINS             = 65536;

type
  // Tag Entry
  TTagHead = packed record
    Name: array[0..MAX_TAGIDENT_LENGTH] of AnsiChar;  // Identifier of the tag
    Idx: LongInt;                                     // Index for multiple tags or -1
    Typ: Cardinal;                                    // Type of tag ty..... see const section
    TagValue: Int64;                                  // Value of tag.
  end;
  // Curve header data (the minimum we need to keep in memory, there is actually more)
  TCurveHdr = packed record
    DataOffset: LongInt;
    HistogramBins: LongInt;
    Resolution: Double;
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

  NumCurves: Integer;
  n,j: Integer;

  CurveHdr: array[0..MAXCURVES] of TCurveHdr;
  Counts: array[0..MAXHISTBINS-1] of Cardinal;

//*********************** Main Program *****************************************
begin
try
  NumCurves := -1;

  Res := 0;
  Magic[0] := #0;
  Version[0] := #0;
  TagHead.Name[0] := #0;

  WriteLn('PicoQuant Unified Histogram (PHU) File Demo');
  WriteLn('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');

  if (ParamCount <> 2) then
  begin
    WriteLn('  Usage: phudemo infile outfile');
    WriteLn;
    WriteLn('  infile  is a binary phu file (*.phu)');
    WriteLn('  outfile will be ASCII');
    WriteLn;
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
    if StrComp(Magic, 'PQHISTO') <> 0 then
    begin
      Writeln('Wrong Magic, this is not a PHU file.');
      Exit;
    end;
    Writeln(OutFile, 'Tag Version: ' + Version);
    repeat
      // Read tagged Header
      // This loop is very generic. It reads all header items and displays the identifier and the
      // associated value, quite independent of what they mean in detail.
      // Only some selected items are kept in memory because they are needed to subsequently
      // interpret the histogram data. See "retrieve selected value.."
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
          // retrieve  selected value we need to process the histogram data
          if TagHead.Name = PHUTagNumCurves then // Number of curves (histograms)
            NumCurves := TagHead.TagValue;
          if(NumCurves > MAXCURVES) then
          begin
            WriteLn('Too many curves.');
            Exit;
          end;
           // retrieve  selected value we need to process the histogram data
          if TagHead.Name = PHUTagDataOffset then // number of bins
            CurveHdr[TagHead.Idx].DataOffset := TagHead.TagValue;
          // retrieve  selected value we need to process the histogram data
          if TagHead.Name = PHUTagHistogramBins then // number of bins
            CurveHdr[TagHead.Idx].HistogramBins := TagHead.TagValue;
        end;
        tyBitSet64: begin                  // BitSet64
          Write(OutFile, '$' + IntToHex(TagHead.TagValue, 16));
        end;
        tyColor8: begin                    // Color8
          Write(OutFile, '$' + IntToHex(TagHead.TagValue, 16));
        end;
        tyFloat8: begin                    // Float8
          Write(OutFile, FloatToStr(Double((@TagHead.TagValue)^)));
          // retrieve  selected value we need to process the histogram data
          if TagHead.Name = PHUTagHistResol then      // histogram bin width
            CurveHdr[TagHead.Idx].Resolution := Double((@TagHead.TagValue)^); // in s
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

// read the histogram data
    n := -1;
    while (n+1 < NumCurves) do
    begin
      inc(n);
      WriteLn(OutFile, 'Curve# ' , n);
      WriteLn(OutFile, 'nBins: ' , CurveHdr[n].HistogramBins);
      WriteLn(OutFile, 'Resol: ' , CurveHdr[n].Resolution);
      WriteLn(OutFile, 'Counts:');

      Seek(InpFile, CurveHdr[n].DataOffset);

     // Result = fread (&Counts, sizeof (unsigned int), CurveHdr[i].HistogramBins, fpin);
      BlockRead(InpFile, Counts, CurveHdr[n].HistogramBins * 4, Res);


      for j:=0 to CurveHdr[n].HistogramBins do
      	   WriteLn(OutFile, Counts[j]);

      WriteLn(OutFile, '-----------------------');

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

