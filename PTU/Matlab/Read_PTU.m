function Read_PTU % Read PicoQuant Unified TTTR Files
% This is demo code. Use at your own risk. No warranties.
% Marcus Sackrow, PicoQUant GmbH, December 2013

% Note that marker events have a lower time resolution and may therefore appear 
% in the file slightly out of order with respect to regular (photon) event records.
% This is by design. Markers are designed only for relatively coarse 
% synchronization requirements such as image scanning. 

% T Mode data are written to an output file [filename].out 
% We do not keep it in memory because of the huge amout of memory
% this would take in case of large files. Of course you can change this, 
% e.g. if your files are not too big. 
% Otherwise it is best process the data on the fly and keep only the results.

% All HeaderData are introduced as Variable to Matlab and can directly be
% used for further analysis

    clear all;
    clc;
    % some constants
    tyEmpty8      = hex2dec('FFFF0008');
    tyBool8       = hex2dec('00000008');
    tyInt8        = hex2dec('10000008');
    tyBitSet64    = hex2dec('11000008');
    tyColor8      = hex2dec('12000008');
    tyFloat8      = hex2dec('20000008');
    tyTDateTime   = hex2dec('21000008');
    tyFloat8Array = hex2dec('2001FFFF');
    tyAnsiString  = hex2dec('4001FFFF');
    tyWideString  = hex2dec('4002FFFF');
    tyBinaryBlob  = hex2dec('FFFFFFFF');
    % RecordTypes
    rtPicoHarpT3     = hex2dec('00010303');% (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $03 (T3), HW: $03 (PicoHarp)
    rtPicoHarpT2     = hex2dec('00010203');% (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $02 (T2), HW: $03 (PicoHarp)
    rtHydraHarpT3    = hex2dec('00010304');% (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $03 (T3), HW: $04 (HydraHarp)
    rtHydraHarpT2    = hex2dec('00010204');% (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $02 (T2), HW: $04 (HydraHarp)
    rtHydraHarp2T3   = hex2dec('01010304');% (SubID = $01 ,RecFmt: $01) (V2), T-Mode: $03 (T3), HW: $04 (HydraHarp)
    rtHydraHarp2T2   = hex2dec('01010204');% (SubID = $01 ,RecFmt: $01) (V2), T-Mode: $02 (T2), HW: $04 (HydraHarp)
    rtTimeHarp260NT3 = hex2dec('00010305');% (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $03 (T3), HW: $05 (TimeHarp260N)
    rtTimeHarp260NT2 = hex2dec('00010205');% (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $02 (T2), HW: $05 (TimeHarp260N)
    rtTimeHarp260PT3 = hex2dec('00010306');% (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $03 (T3), HW: $06 (TimeHarp260P)
    rtTimeHarp260PT2 = hex2dec('00010206');% (SubID = $00 ,RecFmt: $01) (V1), T-Mode: $02 (T2), HW: $06 (TimeHarp260P)

    % Globals for subroutines
    global fid
    global TTResultFormat_TTTRRecType;
    global TTResult_NumberOfRecords; % Number of TTTR Records in the File;
    global MeasDesc_Resolution;      % Resolution for the Dtime (T3 Only)
    global MeasDesc_GlobalResolution;
    
    TTResultFormat_TTTRRecType = 0;
    TTResult_NumberOfRecords = 0;
    MeasDesc_Resolution = 0;
    MeasDesc_GlobalResolution = 0;

    % start Main program
    [filename, pathname]=uigetfile('*.ptu', 'T-Mode data:');
    fid=fopen([pathname filename]);
    
    fprintf(1,'\n');
    Magic = fread(fid, 8, '*char');
    if not(strcmp(Magic(Magic~=0)','PQTTTR'))
        error('Magic invalid, this is not an PTU file.');
    end;
    Version = fread(fid, 8, '*char');
    fprintf(1,'Tag Version: %s\n', Version);

    % there is no repeat.. until (or do..while) construct in matlab so we use
    % while 1 ... if (expr) break; end; end;
    while 1
        % read Tag Head
        TagIdent = fread(fid, 32, '*char'); % TagHead.Ident
        TagIdent = (TagIdent(TagIdent ~= 0))'; % remove #0 and more more readable
        TagIdx = fread(fid, 1, 'int32');    % TagHead.Idx
        TagTyp = fread(fid, 1, 'uint32');   % TagHead.Typ
                                            % TagHead.Value will be read in the
                                            % right type function  
        if TagIdx > -1
          EvalName = [TagIdent '(' int2str(TagIdx + 1) ')'];
        else
          EvalName = TagIdent;
        end
        fprintf(1,'\n   %-40s', EvalName);  
        % check Typ of Header
        switch TagTyp
            case tyEmpty8
                fread(fid, 1, 'int64');   
                fprintf(1,'<Empty>');
            case tyBool8
                TagInt = fread(fid, 1, 'int64');
                if TagInt==0
                    fprintf(1,'FALSE');
                    eval([EvalName '=false;']);
                else
                    fprintf(1,'TRUE');
                    eval([EvalName '=true;']);
                end            
            case tyInt8
                TagInt = fread(fid, 1, 'int64');
                fprintf(1,'%d', TagInt);
                eval([EvalName '=TagInt;']);
            case tyBitSet64
                TagInt = fread(fid, 1, 'int64');
                fprintf(1,'%X', TagInt);
                eval([EvalName '=TagInt;']);
            case tyColor8    
                TagInt = fread(fid, 1, 'int64');
                fprintf(1,'%X', TagInt);
                eval([EvalName '=TagInt;']);
            case tyFloat8
                TagFloat = fread(fid, 1, 'double');
                fprintf(1, '%e', TagFloat);
                eval([EvalName '=TagFloat;']);
            case tyFloat8Array
                TagInt = fread(fid, 1, 'int64');
                fprintf(1,'<Float array with %d Entries>', TagInt / 8);
                fseek(fid, TagInt, 'cof');
            case tyTDateTime
                TagFloat = fread(fid, 1, 'double');
                fprintf(1, '%s', datestr(datenum(1899,12,30)+TagFloat)); % display as Matlab Date String
                eval([EvalName '=datenum(1899,12,30)+TagFloat;']); % but keep in memory as Matlab Date Number
            case tyAnsiString
                TagInt = fread(fid, 1, 'int64');
                TagString = fread(fid, TagInt, '*char');
                TagString = (TagString(TagString ~= 0))';
                fprintf(1, '%s', TagString);
                if TagIdx > -1
                   EvalName = [TagIdent '(' int2str(TagIdx + 1) ',:)'];
                end;   
                eval([EvalName '=TagString;']);
            case tyWideString 
                % Matlab does not support Widestrings at all, just read and
                % remove the 0's (up to current (2012))
                TagInt = fread(fid, 1, 'int64');
                TagString = fread(fid, TagInt, '*char');
                TagString = (TagString(TagString ~= 0))';
                fprintf(1, '%s', TagString);
                if TagIdx > -1
                   EvalName = [TagIdent '(' int2str(TagIdx + 1) ',:)'];
                end;
                eval([EvalName '=TagString;']);
            case tyBinaryBlob
                TagInt = fread(fid, 1, 'int64');
                fprintf(1,'<Binary Blob with %d Bytes>', TagInt);
                fseek(fid, TagInt, 'cof');    
            otherwise
                error('Illegal Type identifier found! Broken file?');
        end;
        if strcmp(TagIdent, 'Header_End')
            break
        end
    end
    fprintf(1, '\n----------------------\n');
    outfile = [pathname filename(1:length(filename)-4) '.out'];
    global fpout;
    fpout = fopen(outfile,'W');
    % Check recordtype
    global isT2;
    switch TTResultFormat_TTTRRecType;
        case rtPicoHarpT3
            isT2 = false;
            fprintf(1,'PicoHarp T3 data\n');
        case rtPicoHarpT2
            isT2 = true; 
            fprintf(1,'PicoHarp T2 data\n');
        case rtHydraHarpT3
            isT2 = false;
            fprintf(1,'HydraHarp V1 T3 data\n');
        case rtHydraHarpT2
            isT2 = true;
            fprintf(1,'HydraHarp V1 T2 data\n');
        case rtHydraHarp2T3
            isT2 = false;
            fprintf(1,'HydraHarp V2 T3 data\n');
        case rtHydraHarp2T2
            isT2 = true;
            fprintf(1,'HydraHarp V2 T2 data\n');
        case rtTimeHarp260NT3
            isT2 = false;
            fprintf(1,'TimeHarp260N T3 data\n');
        case rtTimeHarp260NT2
            isT2 = true;
            fprintf(1,'TimeHarp260N T2 data\n');
        case rtTimeHarp260PT3
            isT2 = false;
            fprintf(1,'TimeHarp260P T3 data\n');
        case rtTimeHarp260PT2
            isT2 = true;
            fprintf(1,'TimeHarp260P T2 data\n');
        otherwise
            error('Illegal RecordType!');
    end;
    fprintf(1,'\nWriting data to %s', outfile);
    fprintf(1,'\nThis may take a while...');
    % write Header
    if (isT2)
      fprintf(fpout, 'record# Type Ch TimeTag TrueTime/ps\n');
    else
      fprintf(fpout, 'record# Type Ch TimeTag TrueTime/ns DTime\n');
    end;
    global cnt_ph;
    global cnt_ov;
    global cnt_ma;
    cnt_ph = 0;
    cnt_ov = 0;
    cnt_ma = 0;
    % choose right decode function
    switch TTResultFormat_TTTRRecType;
        case rtPicoHarpT3
            ReadPT3;
        case rtPicoHarpT2
            isT2 = true; 
            ReadPT2;
        case rtHydraHarpT3
            ReadHT3(1);
        case rtHydraHarpT2
            isT2 = true;
            ReadHT2(1);
        case {rtHydraHarp2T3, rtTimeHarp260NT3, rtTimeHarp260PT3}
            isT2 = false;
            ReadHT3(2);
        case {rtHydraHarp2T2, rtTimeHarp260NT2, rtTimeHarp260PT2}
            isT2 = true;
            ReadHT2(2);
        otherwise
            error('Illegal RecordType!');
    end;
    fclose(fid);
    fclose(fpout);
    fprintf(1,'Ready!  \n\n');
    fprintf(1,'\nStatistics obtained from the data:\n');
    fprintf(1,'\n%i photons, %i overflows, %i markers.',cnt_ph, cnt_ov, cnt_ma);
    fprintf(1,'\n');
end

%% Got Photon
%    TimeTag: Raw TimeTag from Record * Globalresolution = Real Time arrival of Photon
%    DTime: Arrival time of Photon after last Sync event (T3 only) DTime * Resolution = Real time arrival of Photon after last Sync event
%    Channel: Channel the Photon arrived (0 = Sync channel for T2 measurements)
function GotPhoton(TimeTag, Channel, DTime)
  global isT2;
  global fpout;
  global RecNum;
  global MeasDesc_GlobalResolution;
  global cnt_ph;
  cnt_ph = cnt_ph + 1;
  if(isT2)
      fprintf(fpout,'%i CHN %1x %i %8.0lf\n', RecNum, Channel, TimeTag, (TimeTag * MeasDesc_GlobalResolution * 1e12));
  else
      fprintf(fpout,'%i CHN %1x %i %8.0lf %i\n', RecNum, Channel, TimeTag, (TimeTag * MeasDesc_GlobalResolution * 1e9), DTime);
  end;
end

%% Got Marker
%    TimeTag: Raw TimeTag from Record * Globalresolution = Real Time arrival of Photon
%    Markers: Bitfield of arrived Markers, different markers can arrive at same time (same record)
function GotMarker(TimeTag, Markers)
  global fpout;
  global RecNum;
  global cnt_ma;
  cnt_ma = cnt_ma + 1;
  fprintf(fpout,'%i MAR %x %i\n', RecNum, Markers, TimeTag);
end

%% Got Overflow
%  Count: Some TCSPC provide Overflow compression = if no Photons between overflow you get one record for multiple Overflows
function GotOverflow(Count)
  global fpout;
  global RecNum;
  global cnt_ov;
  cnt_ov = cnt_ov + Count;
  fprintf(fpout,'%i OFL * %x\n', RecNum, Count);
end

%% Decoder functions

%% Read PicoHarp T3
function ReadPT3
    global fid;
    global fpout;
    global TTResult_NumberOfRecords; % Number of TTTR Records in the File;
    ofltime = 0;
    WRAPAROUND=65536;  

    for i=1:TTResult_NumberOfRecords
        T3Record = fread(fid, 1, 'ubit32');     % all 32 bits:
    %   +-------------------------------+  +-------------------------------+ 
    %   |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|  |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|
    %   +-------------------------------+  +-------------------------------+    
        nsync = bitand(T3Record,65535);       % the lowest 16 bits:  
    %   +-------------------------------+  +-------------------------------+ 
    %   | | | | | | | | | | | | | | | | |  |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|
    %   +-------------------------------+  +-------------------------------+    
        chan = bitand(bitshift(T3Record,-28),15);   % the upper 4 bits:
    %   +-------------------------------+  +-------------------------------+ 
    %   |x|x|x|x| | | | | | | | | | | | |  | | | | | | | | | | | | | | | | |
    %   +-------------------------------+  +-------------------------------+       
        truensync = ofltime + nsync;
        if (chan >= 1) && (chan <=4)
            dtime = bitand(bitshift(T3Record,-16),4095);
            GotPhoton(truensync, chan, dtime);  % regular count at Ch1, Rt_Ch1 - Rt_Ch4 when the router is enabled
        else
            if chan == 15 % special record
                markers = bitand(bitshift(T3Record,-16),15); % where these four bits are markers:     
    %   +-------------------------------+  +-------------------------------+ 
    %   | | | | | | | | | | | | |x|x|x|x|  | | | | | | | | | | | | | | | | |
    %   +-------------------------------+  +-------------------------------+
                if markers == 0                           % then this is an overflow record
                    ofltime = ofltime + WRAPAROUND;         % and we unwrap the numsync (=time tag) overflow
                    GotOverflow(1);
                else                                    % if nonzero, then this is a true marker event
                    GotMarker(truensync, markers);
                end;
            else
                fprintf(fpout,'Err ');
            end;
        end;    
    end;    
end

%% Read PicoHarp T2
function ReadPT2
    global fid;
    global fpout;
    global RecNum;
    global TTResult_NumberOfRecords; % Number of TTTR Records in the File;   
    ofltime = 0;
    WRAPAROUND=210698240;

    for i=1:TTResult_NumberOfRecords
        RecNum = i;
        T2Record = fread(fid, 1, 'ubit32');
        T2time = bitand(T2Record,268435455);             %the lowest 28 bits
        chan = bitand(bitshift(T2Record,-28),15);      %the next 4 bits
        timetag = T2time + ofltime;
        if (chan >= 0) && (chan <= 4)
            GotPhoton(timetag, chan, 0);
        else
            if chan == 15
                markers = bitand(T2Record,15);  % where the lowest 4 bits are marker bits
                if markers==0                   % then this is an overflow record
                    ofltime = ofltime + WRAPAROUND; % and we unwrap the time tag overflow
                    GotOverflow(1);
                else                            % otherwise it is a true marker  
                    GotMarker(timetag, markers);
                end;
            else
                fprintf(fpout,'Err');
            end;
        end;                    
        % Strictly, in case of a marker, the lower 4 bits of time are invalid
        % because they carry the marker bits. So one could zero them out. 
        % However, the marker resolution is only a few tens of nanoseconds anyway,
        % so we can just ignore the few picoseconds of error.
    end;
end

%% Read HydraHarp/TimeHarp260 T3
function ReadHT3(Version)
    global fid;
    global RecNum;
    global TTResult_NumberOfRecords; % Number of TTTR Records in the File
    OverflowCorrection = 0;
    T3WRAPAROUND = 1024;

    for i = 1:TTResult_NumberOfRecords
        RecNum = i;
        T3Record = fread(fid, 1, 'ubit32');     % all 32 bits:
        %   +-------------------------------+  +-------------------------------+ 
        %   |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|  |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|
        %   +-------------------------------+  +-------------------------------+  
        nsync = bitand(T3Record,1023);       % the lowest 10 bits:
        %   +-------------------------------+  +-------------------------------+ 
        %   | | | | | | | | | | | | | | | | |  | | | | | | |x|x|x|x|x|x|x|x|x|x|
        %   +-------------------------------+  +-------------------------------+  
        dtime = bitand(bitshift(T3Record,-10),32767);   % the next 15 bits:
        %   the dtime unit depends on "Resolution" that can be obtained from header
        %   +-------------------------------+  +-------------------------------+ 
        %   | | | | | | | |x|x|x|x|x|x|x|x|x|  |x|x|x|x|x|x| | | | | | | | | | |
        %   +-------------------------------+  +-------------------------------+
        channel = bitand(bitshift(T3Record,-25),63);   % the next 6 bits:
        %   +-------------------------------+  +-------------------------------+ 
        %   | |x|x|x|x|x|x| | | | | | | | | |  | | | | | | | | | | | | | | | | |
        %   +-------------------------------+  +-------------------------------+
        special = bitand(bitshift(T3Record,-31),1);   % the last bit:
        %   +-------------------------------+  +-------------------------------+ 
        %   |x| | | | | | | | | | | | | | | |  | | | | | | | | | | | | | | | | |
        %   +-------------------------------+  +-------------------------------+ 
        if special == 0   % this means a regular input channel
           true_nSync = OverflowCorrection + nsync;
           %  one nsync time unit equals to "syncperiod" which can be
           %  calculated from "SyncRate"
           GotPhoton(true_nSync, channel, dtime);
        else    % this means we have a special record
            if channel == 63  % overflow of nsync occured
              if (nsync == 0) || (Version == 1) % if nsync is zero it is an old style single oferflow or old Version
                OverflowCorrection = OverflowCorrection + T3WRAPAROUND;
                GotOverflow(1);
              else         % otherwise nsync indicates the number of overflows - THIS IS NEW IN FORMAT V2.0
                OverflowCorrection = OverflowCorrection + T3WRAPAROUND * nsync;
                GotOverflow(nsync);
              end;    
            end;
            if (channel >= 1) && (channel <= 15)  % these are markers
              true_nSync = OverflowCorrection + nsync;
              GotMarker(true_nSync, channel);
            end;    
        end;
    end;
end

%% Read HydraHarp/TimeHarp260 T2
function ReadHT2(Version)
    global fid;
    global TTResult_NumberOfRecords; % Number of TTTR Records in the File;
    global RecNum;

    OverflowCorrection = 0;
    T2WRAPAROUND_V1=33552000;
    T2WRAPAROUND_V2=33554432; % = 2^25  IMPORTANT! THIS IS NEW IN FORMAT V2.0

    for i=1:TTResult_NumberOfRecords
        RecNum = i;
        T2Record = fread(fid, 1, 'ubit32');     % all 32 bits:
        %   +-------------------------------+  +-------------------------------+ 
        %   |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|  |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|
        %   +-------------------------------+  +-------------------------------+  
        dtime = bitand(T2Record,33554431);   % the last 25 bits:
        %   +-------------------------------+  +-------------------------------+ 
        %   | | | | | | | |x|x|x|x|x|x|x|x|x|  |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|
        %   +-------------------------------+  +-------------------------------+
        channel = bitand(bitshift(T2Record,-25),63);   % the next 6 bits:
        %   +-------------------------------+  +-------------------------------+ 
        %   | |x|x|x|x|x|x| | | | | | | | | |  | | | | | | | | | | | | | | | | |
        %   +-------------------------------+  +-------------------------------+
        special = bitand(bitshift(T2Record,-31),1);   % the last bit:
        %   +-------------------------------+  +-------------------------------+ 
        %   |x| | | | | | | | | | | | | | | |  | | | | | | | | | | | | | | | | |
        %   +-------------------------------+  +-------------------------------+
        % the resolution in T2 mode is 1 ps  - IMPORTANT! THIS IS NEW IN FORMAT V2.0
        timetag = OverflowCorrection + dtime;
        if special == 0   % this means a regular photon record
           GotPhoton(timetag, channel + 1, 0)
        else    % this means we have a special record
            if channel == 63  % overflow of dtime occured
              if Version == 1
                  OverflowCorrection = OverflowCorrection + T2WRAPAROUND_V1;
                  GotOverflow(1);
              else              
                  if(dtime == 0) % if dtime is zero it is an old style single oferflow
                    OverflowCorrection = OverflowCorrection + T2WRAPAROUND_V2;
                    GotOverflow(1);
                  else         % otherwise dtime indicates the number of overflows - THIS IS NEW IN FORMAT V2.0
                    OverflowCorrection = OverflowCorrection + T2WRAPAROUND_V2 * dtime;
                    GotOverflow(dtime);
                  end;
              end;
            end;
            if channel == 0  % Sync event
                GotPhoton(timetag, channel, 0);
            end;
            if (channel >= 1) && (channel <= 15)  % these are markers
                GotMarker(timetag, channel);
            end;    
        end;
    end;
end
