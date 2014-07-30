% PicoHarp 300    File Access Demo in Matlab
% This script reads a PicoHarp T2 Mode data file (*.pt2)
% Works with file format version 2.0 only!

% Tested with Matlab 6
% Peter Kapusta, Michael Wahl, PicoQuant GmbH 2006, updated May 2007

% This is a demo code. Use at your own risk. No warranties.

% T2 Mode data are written to an output file [filename].out 
% We do not keep it in memory because of the huge amout of memory
% this would take in case of large files. Of course you can change this, 
% e.g. if your files are not too big. 
% Otherwise it is best process the data on the fly and keep only the results.

% Note that marker events have a lower time resolution and may therefore appear 
% in the file slightly out of order with respect to regular (photon) event records.
% This is by design. Markers are designed only for relatively coarse 
% synchronization requirements such as image scanning. 


clear all;
clc;
fprintf(1,'\n');

[filename, pathname]=uigetfile('*.pt2', 'T2 Mode data:', 0, 0);
fid=fopen([pathname filename]);

%
% The following reads the ASCII file header 
%

Ident = char(fread(fid, 16, 'char')');
fprintf(1,'      Identifier: %s\n', Ident);

FormatVersion = deblank(char(fread(fid, 6, 'char')'));
fprintf(1,'  Format Version: %s\n', FormatVersion);

if not(strcmp(FormatVersion,'2.0'))
   fprintf(1,'\n\n      Warning: This program is for version 2.0 only. Aborted.');
   STOP;
end;

CreatorName = char(fread(fid, 18, 'char')');
fprintf(1,'    Creator Name: %s\n', CreatorName);

CreatorVersion = char(fread(fid, 12, 'char')');
fprintf(1,' Creator Version: %s\n', CreatorVersion);

FileTime = char(fread(fid, 18, 'char')');
fprintf(1,'       File Time: %s\n', FileTime);

CRLF = char(fread(fid, 2, 'char')');

CommentField = char(fread(fid, 256, 'char')');
fprintf(1,'         Comment: %s\n', CommentField);


%
% The following is binary file header information
%


Curves = fread(fid, 1, 'int32');
fprintf(1,'Number of Curves: %d\n', Curves);

BitsPerRecord = fread(fid, 1, 'int32');
fprintf(1,'   Bits / Record: %d\n', BitsPerRecord);

RoutingChannels = fread(fid, 1, 'int32');
fprintf(1,'Routing Channels: %d\n', RoutingChannels);

NumberOfBoards = fread(fid, 1, 'int32');
fprintf(1,'Number of Boards: %d\n', NumberOfBoards);

ActiveCurve = fread(fid, 1, 'int32');
fprintf(1,'    Active Curve: %d\n', ActiveCurve);

MeasurementMode = fread(fid, 1, 'int32');
fprintf(1,'Measurement Mode: %d\n', MeasurementMode);

SubMode = fread(fid, 1, 'int32');
fprintf(1,'        Sub-Mode: %d\n', SubMode);

RangeNo = fread(fid, 1, 'int32');
fprintf(1,'       Range No.: %d\n', RangeNo);

Offset = fread(fid, 1, 'int32');
fprintf(1,'          Offset: %d ns \n', Offset);

AcquisitionTime = fread(fid, 1, 'int32');
fprintf(1,'Acquisition Time: %d ms \n', AcquisitionTime);

StopAt = fread(fid, 1, 'int32');
fprintf(1,'         Stop At: %d counts \n', StopAt);

StopOnOvfl = fread(fid, 1, 'int32');
fprintf(1,'Stop on Overflow: %d\n', StopOnOvfl);

Restart = fread(fid, 1, 'int32');
fprintf(1,'         Restart: %d\n', Restart);

DispLinLog = fread(fid, 1, 'int32');
fprintf(1,' Display Lin/Log: %d\n', DispLinLog);

DispTimeFrom = fread(fid, 1, 'int32');
fprintf(1,' Display Time Axis From: %d ns \n', DispTimeFrom);

DispTimeTo = fread(fid, 1, 'int32');
fprintf(1,'   Display Time Axis To: %d ns \n', DispTimeTo);

DispCountFrom = fread(fid, 1, 'int32');
fprintf(1,'Display Count Axis From: %d\n', DispCountFrom); 

DispCountTo = fread(fid, 1, 'int32');
fprintf(1,'  Display Count Axis To: %d\n', DispCountTo);

for i = 1:8
DispCurveMapTo(i) = fread(fid, 1, 'int32');
DispCurveShow(i) = fread(fid, 1, 'int32');
end;

for i = 1:3
ParamStart(i) = fread(fid, 1, 'float');
ParamStep(i) = fread(fid, 1, 'float');
ParamEnd(i) = fread(fid, 1, 'float');
end;

RepeatMode = fread(fid, 1, 'int32');
fprintf(1,'         Repeat Mode: %d\n', RepeatMode);

RepeatsPerCurve = fread(fid, 1, 'int32');
fprintf(1,'      Repeat / Curve: %d\n', RepeatsPerCurve);

RepeatTime = fread(fid, 1, 'int32');
fprintf(1,'         Repeat Time: %d\n', RepeatTime);

RepeatWait = fread(fid, 1, 'int32');
fprintf(1,'    Repeat Wait Time: %d\n', RepeatWait);

ScriptName = char(fread(fid, 20, 'char'));
fprintf(1,'         Script Name: %s\n', ScriptName);


%
% The next is a board specific header
%


HardwareIdent = char(fread(fid, 16, 'char')');
fprintf(1,' Hardware Identifier: %s\n', HardwareIdent);

HardwareVersion = char(fread(fid, 8, 'char')');
fprintf(1,'    Hardware Version: %s\n', HardwareVersion);

HardwareSerial = fread(fid, 1, 'int32');
fprintf(1,'    HW Serial Number: %d\n', HardwareSerial);

SyncDivider = fread(fid, 1, 'int32');
fprintf(1,'        Sync Divider: %d\n', SyncDivider);

CFDZeroCross0 = fread(fid, 1, 'int32');
fprintf(1,' CFD ZeroCross (Ch0): %4i mV\n', CFDZeroCross0);

CFDLevel0 = fread(fid, 1, 'int32');
fprintf(1,' CFD Discr.    (Ch0): %4i mV\n', CFDLevel0);

CFDZeroCross1 = fread(fid, 1, 'int32');
fprintf(1,' CFD ZeroCross (Ch1): %4i mV\n', CFDZeroCross1);

CFDLevel1 = fread(fid, 1, 'int32');
fprintf(1,' CFD Discr.    (Ch1): %4i mV\n', CFDLevel1);

Resolution = fread(fid, 1, 'float');
fprintf(1,'          Resolution: %5.6f ns\n', Resolution);

% below is new in format version 2.0

RouterModelCode      = fread(fid, 1, 'int32');
RouterEnabled        = fread(fid, 1, 'int32');

% Router Ch1
RtChan1_InputType    = fread(fid, 1, 'int32');
RtChan1_InputLevel   = fread(fid, 1, 'int32');
RtChan1_InputEdge    = fread(fid, 1, 'int32');
RtChan1_CFDPresent   = fread(fid, 1, 'int32');
RtChan1_CFDLevel     = fread(fid, 1, 'int32');
RtChan1_CFDZeroCross = fread(fid, 1, 'int32');
% Router Ch2
RtChan2_InputType    = fread(fid, 1, 'int32');
RtChan2_InputLevel   = fread(fid, 1, 'int32');
RtChan2_InputEdge    = fread(fid, 1, 'int32');
RtChan2_CFDPresent   = fread(fid, 1, 'int32');
RtChan2_CFDLevel     = fread(fid, 1, 'int32');
RtChan2_CFDZeroCross = fread(fid, 1, 'int32');
% Router Ch3
RtChan3_InputType    = fread(fid, 1, 'int32');
RtChan3_InputLevel   = fread(fid, 1, 'int32');
RtChan3_InputEdge    = fread(fid, 1, 'int32');
RtChan3_CFDPresent   = fread(fid, 1, 'int32');
RtChan3_CFDLevel     = fread(fid, 1, 'int32');
RtChan3_CFDZeroCross = fread(fid, 1, 'int32');
% Router Ch4
RtChan4_InputType    = fread(fid, 1, 'int32');
RtChan4_InputLevel   = fread(fid, 1, 'int32');
RtChan4_InputEdge    = fread(fid, 1, 'int32');
RtChan4_CFDPresent   = fread(fid, 1, 'int32');
RtChan4_CFDLevel     = fread(fid, 1, 'int32');
RtChan4_CFDZeroCross = fread(fid, 1, 'int32');

% Router settings are meaningful only for an existing router:

if RouterModelCode>0

    fprintf(1,'-------------------------------------\n'); 
    fprintf(1,'   Router Model Code: %d \n', RouterModelCode);
    fprintf(1,'      Router Enabled: %d \n', RouterEnabled);
    fprintf(1,'-------------------------------------\n'); 
    
    
    % Router Ch1 
    fprintf(1,'RtChan1 InputType   : %d \n', RtChan1_InputType);
    fprintf(1,'RtChan1 InputLevel  : %4i mV\n', RtChan1_InputLevel);
    fprintf(1,'RtChan1 InputEdge   : %d \n', RtChan1_InputEdge);
    fprintf(1,'RtChan1 CFDPresent  : %d \n', RtChan1_CFDPresent);
    fprintf(1,'RtChan1 CFDLevel    : %4i mV\n', RtChan1_CFDLevel);
    fprintf(1,'RtChan1 CFDZeroCross: %4i mV\n', RtChan1_CFDZeroCross);
    fprintf(1,'-------------------------------------\n'); 

    % Router Ch2
    fprintf(1,'RtChan2 InputType   : %d \n', RtChan2_InputType);
    fprintf(1,'RtChan2 InputLevel  : %4i mV\n', RtChan2_InputLevel);
    fprintf(1,'RtChan2 InputEdge   : %d \n', RtChan2_InputEdge);
    fprintf(1,'RtChan2 CFDPresent  : %d \n', RtChan2_CFDPresent);
    fprintf(1,'RtChan2 CFDLevel    : %4i mV\n', RtChan2_CFDLevel);
    fprintf(1,'RtChan2 CFDZeroCross: %4i mV\n', RtChan2_CFDZeroCross);
    fprintf(1,'-------------------------------------\n'); 

    % Router Ch3
    fprintf(1,'RtChan3 InputType   : %d \n', RtChan3_InputType);
    fprintf(1,'RtChan3 InputLevel  : %4i mV\n', RtChan3_InputLevel);
    fprintf(1,'RtChan3 InputEdge   : %d \n', RtChan3_InputEdge);
    fprintf(1,'RtChan3 CFDPresent  : %d \n', RtChan3_CFDPresent);
    fprintf(1,'RtChan3 CFDLevel    : %4i mV\n', RtChan3_CFDLevel);
    fprintf(1,'RtChan3 CFDZeroCross: %4i mV\n', RtChan3_CFDZeroCross);
    fprintf(1,'-------------------------------------\n'); 

    % Router Ch4
    fprintf(1,'RtChan4 InputType   : %d \n', RtChan4_InputType);
    fprintf(1,'RtChan4 InputLevel  : %4i mV\n', RtChan4_InputLevel);
    fprintf(1,'RtChan4 InputEdge   : %d \n', RtChan4_InputEdge);
    fprintf(1,'RtChan4 CFDPresent  : %d \n', RtChan4_CFDPresent);
    fprintf(1,'RtChan4 CFDLevel    : %4i mV\n', RtChan4_CFDLevel);
    fprintf(1,'RtChan4 CFDZeroCross: %4i mV\n', RtChan4_CFDZeroCross);
    fprintf(1,'-------------------------------------\n'); 
 
end;
 

%
% The next is a T2 mode specific header
%

ExtDevices = fread(fid, 1, 'int32');
fprintf(1,'    External Devices: %d\n', ExtDevices);

Reserved1 = fread(fid, 1, 'int32');
fprintf(1,'           Reserved1: %d\n', Reserved1);

Reserved2 = fread(fid, 1, 'int32');
fprintf(1,'           Reserved2: %d\n', Reserved2);

CntRate0 = fread(fid, 1, 'int32');
fprintf(1,'    Count Rate (Ch0): %d Hz\n', CntRate0);

CntRate1 = fread(fid, 1, 'int32');
fprintf(1,'    Count Rate (Ch1): %d Hz\n', CntRate1);

StopAfter = fread(fid, 1, 'int32');
fprintf(1,'          Stop After: %d ms \n', StopAfter);

StopReason = fread(fid, 1, 'int32');
fprintf(1,'         Stop Reason: %d\n', StopReason);

Records = fread(fid, 1, 'uint32');
fprintf(1,'   Number Of Records: %d\n', Records);

ImgHdrSize = fread(fid, 1, 'int32');
fprintf(1,' Imaging Header Size: %d bytes\n', ImgHdrSize);

%Special header for imaging 
ImgHdr = fread(fid, ImgHdrSize, 'int32');


%
%  This reads the T2 mode event records
%

ofltime = 0;
cnt_0=0; cnt_1=0; cnt_2=0; cnt_3=0; cnt_4=0; cnt_Ofl=0; cnt_M=0; cnt_Err=0; % just counters
RESOL=4E-12;   % 4ps
WRAPAROUND=210698240; 

outfile = [pathname filename(1:length(filename)-4) '.out'];
fpout = fopen(outfile,'W');
fprintf(1,'\nWriting data to %s', outfile);
fprintf(1,'\nThis may take a while...');

fprintf(fpout,'\n----------------------------------------------------------------------');
fprintf(fpout,'\n      # T2record         T2time  Channel    time/4ps      time/sec');
fprintf(fpout,'\n----------------------------------------------------------------------\n');
          
for i=1:Records

    T2Record = fread(fid, 1, 'ubit32');
    T2time = bitand(T2Record,268435455);             %the lowest 28 bits
    chan = bitand(bitshift(T2Record,-28),15);      %the next 4 bits
    fprintf(fpout,'\n%7u %08x %14.0f %2u ',i,T2Record,T2time,chan);
  
    switch chan;
    
    case 0, cnt_0=cnt_0+1; fprintf(fpout,'   ');   % regular count at Ch0
    case 1, cnt_1=cnt_1+1; fprintf(fpout,'   ');   % regular count at Ch1, Rt_Ch1 when the router is enabled
    case 2, cnt_2=cnt_2+1; fprintf(fpout,'   ');   % regular count at Ch1, Rt_Ch2 when the router is enabled
    case 3, cnt_3=cnt_3+1; fprintf(fpout,'   ');   % regular count at Ch1, Rt_Ch3 when the router is enabled
    case 4, cnt_4=cnt_4+1; fprintf(fpout,'   ');   % regular count at Ch1, Rt_Ch4 when the router is enabled
    case 15,                             % this means a special record
         markers = bitand(T2Record,15);  % where the lowest 4 bits are marker bits
         if markers==0                   % then this is an overflow record
         ofltime = ofltime + WRAPAROUND; % and we unwrap the time tag overflow
         fprintf(fpout,'Ofl'); cnt_Ofl=cnt_Ofl+1;
         else                            % otherwise it is a true marker  
         fprintf(fpout,'MA%1u', markers); cnt_M=cnt_M+1;
         end;
    
    otherwise    fprintf(fpout,'Err'); cnt_Err=cnt_Err+1;  % such events should not occur
    end;
    time = T2time + ofltime;
    % Strictly, in case of a marker, the lower 4 bits of time are invalid
	% because they carry the marker bits. So one could zero them out. 
	% However, the marker resolution is only a few tens of nanoseconds anyway,
	% so we can just ignore the few picoseconds of error.
    
    fprintf(fpout,'%14.0f   %14.12f', time, time*RESOL);
end;

fclose(fid);
fclose(fpout);

fprintf(1,'  Ready!  \n\n');
fprintf(1,'\nStatistics obtained from the data:\n');
fprintf(1,'\nLast time tag = %-14.0f, Last t = %4.2f s,',time,time*RESOL);
fprintf(1,'\nCh0: %i counts, RtCh1: %i counts, RtCh2: %i counts, RtCh3: %i counts, RtCh4: %i counts',cnt_0,cnt_1,cnt_2,cnt_3,cnt_4);
fprintf(1,'\n%i overflows, %i markers, %i illegal events. Total: %i records.',cnt_Ofl,cnt_M,cnt_Err,cnt_0+cnt_1+cnt_2+cnt_3+cnt_4+cnt_Ofl+cnt_M+cnt_Err);
fprintf(1,'\n');
