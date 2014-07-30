% PicoHarp 300    File Access Demo in Matlab

% This script reads a binary PicoHarp 300 data file (*.phd)
% and displays its contents. Works with file format version 2.0 only!

% Tested with Matlab 6.
% Peter Kapusta, PicoQuant GmbH, September 2006
% This is demo code. Use at your own risk. No warranties.
% Make sure you have enough memory when loading large files!

clear all;
clc;

[filename, pathname]=uigetfile('*.phd', 'Interactive mode data:', 0, 0);
fid=fopen([pathname filename]);

fprintf(1,'\n=========================================================================== \n');
fprintf(1,'  Content of %s : \n', strcat(pathname, filename));
fprintf(1,'=========================================================================== \n');
fprintf(1,'\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% ASCII file header
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Ident = char(fread(fid, 16, 'char'));
fprintf(1,'               Ident: %s\n', Ident);

FormatVersion = deblank(char(fread(fid, 6, 'char')'));
fprintf(1,'      Format version: %s\n', FormatVersion);

if not(strcmp(FormatVersion,'2.0'))
   fprintf(1,'\n\n      Warning: This program is for version 2.0 only. Aborted.');
   STOP;
end;

CreatorName = char(fread(fid, 18, 'char'));
fprintf(1,'        Creator name: %s\n', CreatorName);

CreatorVersion = char(fread(fid, 12, 'char'));
fprintf(1,'     Creator version: %s\n', CreatorVersion);

FileTime = char(fread(fid, 18, 'char'));
fprintf(1,'    Time of creation: %s\n', FileTime);

CRLF = char(fread(fid, 2, 'char'));

Comment = char(fread(fid, 256, 'char'));
fprintf(1,'             Comment: %s\n', Comment);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Binary file header
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


NumberOfCurves = fread(fid, 1, 'int32');
fprintf(1,'    Number of Curves: %d\n', NumberOfCurves);

BitsPerHistoBin = fread(fid, 1, 'int32');
fprintf(1,'     Bits / HistoBin: %d\n', BitsPerHistoBin);

RoutingChannels = fread(fid, 1, 'int32');
fprintf(1,'    Routing Channels: %d\n', RoutingChannels);

NumberOfBoards = fread(fid, 1, 'int32');
fprintf(1,'    Number of Boards: %d\n', NumberOfBoards);

ActiveCurve = fread(fid, 1, 'int32');
fprintf(1,'        Active Curve: %d\n', ActiveCurve);

MeasurementMode = fread(fid, 1, 'int32');
fprintf(1,'    Measurement Mode: %d\n', MeasurementMode);

SubMode = fread(fid, 1, 'int32');
fprintf(1,'            Sub-Mode: %d\n', SubMode);

RangeNo = fread(fid, 1, 'int32');
fprintf(1,'            Range No: %d\n', RangeNo);

Offset = fread(fid, 1, 'int32');
fprintf(1,'              Offset: %d\n', Offset);

Tacq = fread(fid, 1, 'int32');
fprintf(1,'    Acquisition Time: %d ms \n', Tacq);

StopAt = fread(fid, 1, 'int32');
fprintf(1,'             Stop At: %d counts \n', StopAt);

StopOnOvfl = fread(fid, 1, 'int32');
fprintf(1,'    Stop on Overflow: %d\n', StopOnOvfl);

Restart = fread(fid, 1, 'int32');
fprintf(1,'             Restart: %d\n', Restart);

DispLinLog = fread(fid, 1, 'int32');
fprintf(1,'     Display Lin/Log: %d\n', DispLinLog);

DispTimeAxisFrom = fread(fid, 1, 'int32');
fprintf(1,'      Time Axis From: %d ns \n', DispTimeAxisFrom);

DispTimeAxisTo = fread(fid, 1, 'int32');
fprintf(1,'        Time Axis To: %d ns \n', DispTimeAxisTo);

DispCountAxisFrom = fread(fid, 1, 'int32');
fprintf(1,'     Count Axis From: %d\n', DispCountAxisFrom); 

DispCountAxisTo = fread(fid, 1, 'int32');
fprintf(1,'       Count Axis To: %d\n', DispCountAxisTo);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i = 1:8
DispCurveMapTo(i) = fread(fid, 1, 'int32');
DispCurveShow(i) = fread(fid, 1, 'int32');
fprintf(1,'-------------------------------------\n');
fprintf(1,'            Curve No: %d\n', i-1);
fprintf(1,'               MapTo: %d\n', DispCurveMapTo(i));
fprintf(1,'                Show: %d\n', DispCurveShow(i));
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i = 1:3
ParamStart(i) = fread(fid, 1, 'float');
ParamStep(i) = fread(fid, 1, 'float');
ParamEnd(i) = fread(fid, 1, 'float');
fprintf(1,'-------------------------------------\n');
fprintf(1,'        Parameter No: %d\n', i-1);
fprintf(1,'               Start: %d\n', ParamStart(i));
fprintf(1,'                Step: %d\n', ParamStep(i));
fprintf(1,'                 End: %d\n', ParamEnd(i));
end;
fprintf(1,'-------------------------------------\n');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

RepeatMode = fread(fid, 1, 'int32');
fprintf(1,'         Repeat Mode: %d\n', RepeatMode);

RepeatsPerCurve = fread(fid, 1, 'int32');
fprintf(1,'      Repeat / Curve: %d\n', RepeatsPerCurve);

RepatTime = fread(fid, 1, 'int32');
fprintf(1,'         Repeat Time: %d\n', RepatTime);

RepeatWaitTime = fread(fid, 1, 'int32');
fprintf(1,'    Repeat Wait Time: %d\n', RepeatWaitTime);

ScriptName = char(fread(fid, 20, 'char'));
fprintf(1,'         Script Name: %s\n', ScriptName);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%          Header for each board
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



for i = 1:NumberOfBoards
fprintf(1,'-------------------------------------\n'); 
fprintf(1,'            Board No: %d\n', i-1);

HardwareIdent(:,i) = char(fread(fid, 16, 'char'));
fprintf(1,' Hardware Identifier: %s\n', HardwareIdent(:,i));

HardwareVersion(:,i) = char(fread(fid, 8, 'char'));
fprintf(1,'    Hardware Version: %s\n', HardwareVersion(:,i));    
    
HardwareSerial(i) = fread(fid, 1, 'int32');
fprintf(1,'    HW Serial Number: %d\n', HardwareSerial(i));

SyncDivider(i) = fread(fid, 1, 'int32');
fprintf(1,'        Sync divider: %d \n', SyncDivider(i));
 
CFDZeroCross0(i) = fread(fid, 1, 'int32');
fprintf(1,'     CFD 0 ZeroCross: %3i mV\n', CFDZeroCross0(i));

CFDLevel0(i) = fread(fid, 1, 'int32');
fprintf(1,'     CFD 0 Discr.   : %3i mV\n', CFDLevel0(i));

CFDZeroCross1(i) = fread(fid, 1, 'int32');
fprintf(1,'     CFD 1 ZeroCross: %3i mV\n', CFDZeroCross1(i));

CFDLevel1(i) = fread(fid, 1, 'int32');
fprintf(1,'     CFD 1 Discr.   : %3i mV\n', CFDLevel1(i));

Resolution(i) = fread(fid, 1, 'float');
fprintf(1,'          Resolution: %2.6g ns\n', Resolution(i));

% below is new in format version 2.0

RouterModelCode(i)      = fread(fid, 1, 'int32');
RouterEnabled(i)        = fread(fid, 1, 'int32');

% Router Ch1
RtChan1_InputType(i)    = fread(fid, 1, 'int32');
RtChan1_InputLevel(i)   = fread(fid, 1, 'int32');
RtChan1_InputEdge(i)    = fread(fid, 1, 'int32');
RtChan1_CFDPresent(i)   = fread(fid, 1, 'int32');
RtChan1_CFDLevel(i)     = fread(fid, 1, 'int32');
RtChan1_CFDZeroCross(i) = fread(fid, 1, 'int32');
% Router Ch2
RtChan2_InputType(i)    = fread(fid, 1, 'int32');
RtChan2_InputLevel(i)   = fread(fid, 1, 'int32');
RtChan2_InputEdge(i)    = fread(fid, 1, 'int32');
RtChan2_CFDPresent(i)   = fread(fid, 1, 'int32');
RtChan2_CFDLevel(i)     = fread(fid, 1, 'int32');
RtChan2_CFDZeroCross(i) = fread(fid, 1, 'int32');
% Router Ch3
RtChan3_InputType(i)    = fread(fid, 1, 'int32');
RtChan3_InputLevel(i)   = fread(fid, 1, 'int32');
RtChan3_InputEdge(i)    = fread(fid, 1, 'int32');
RtChan3_CFDPresent(i)   = fread(fid, 1, 'int32');
RtChan3_CFDLevel(i)     = fread(fid, 1, 'int32');
RtChan3_CFDZeroCross(i) = fread(fid, 1, 'int32');
% Router Ch4
RtChan4_InputType(i)    = fread(fid, 1, 'int32');
RtChan4_InputLevel(i)   = fread(fid, 1, 'int32');
RtChan4_InputEdge(i)    = fread(fid, 1, 'int32');
RtChan4_CFDPresent(i)   = fread(fid, 1, 'int32');
RtChan4_CFDLevel(i)     = fread(fid, 1, 'int32');
RtChan4_CFDZeroCross(i) = fread(fid, 1, 'int32');

% Router settings are meaningful only for an existing router:

if RouterModelCode(i)>0

    fprintf(1,'-------------------------------------\n'); 
    fprintf(1,'   Router Model Code: %d \n', RouterModelCode(i));
    fprintf(1,'      Router Enabled: %d \n', RouterEnabled(i));
    fprintf(1,'-------------------------------------\n'); 
    
    % Router Ch1 
    fprintf(1,'RtChan1 InputType   : %d \n', RtChan1_InputType(i));
    fprintf(1,'RtChan1 InputLevel  : %4i mV\n', RtChan1_InputLevel(i));
    fprintf(1,'RtChan1 InputEdge   : %d \n', RtChan1_InputEdge(i));
    fprintf(1,'RtChan1 CFDPresent  : %d \n', RtChan1_CFDPresent(i));
    fprintf(1,'RtChan1 CFDLevel    : %4i mV\n', RtChan1_CFDLevel(i));
    fprintf(1,'RtChan1 CFDZeroCross: %4i mV\n', RtChan1_CFDZeroCross(i));
    fprintf(1,'-------------------------------------\n'); 

    % Router Ch2
    fprintf(1,'RtChan2 InputType   : %d \n', RtChan2_InputType(i));
    fprintf(1,'RtChan2 InputLevel  : %4i mV\n', RtChan2_InputLevel(i));
    fprintf(1,'RtChan2 InputEdge   : %d \n', RtChan2_InputEdge(i));
    fprintf(1,'RtChan2 CFDPresent  : %d \n', RtChan2_CFDPresent(i));
    fprintf(1,'RtChan2 CFDLevel    : %4i mV\n', RtChan2_CFDLevel(i));
    fprintf(1,'RtChan2 CFDZeroCross: %4i mV\n', RtChan2_CFDZeroCross(i));
    fprintf(1,'-------------------------------------\n'); 

    % Router Ch3
    fprintf(1,'RtChan3 InputType   : %d \n', RtChan3_InputType(i));
    fprintf(1,'RtChan3 InputLevel  : %4i mV\n', RtChan3_InputLevel(i));
    fprintf(1,'RtChan3 InputEdge   : %d \n', RtChan3_InputEdge(i));
    fprintf(1,'RtChan3 CFDPresent  : %d \n', RtChan3_CFDPresent(i));
    fprintf(1,'RtChan3 CFDLevel    : %4i mV\n', RtChan3_CFDLevel(i));
    fprintf(1,'RtChan3 CFDZeroCross: %4i mV\n', RtChan3_CFDZeroCross(i));
    fprintf(1,'-------------------------------------\n'); 

    % Router Ch4
    fprintf(1,'RtChan4 InputType   : %d \n', RtChan4_InputType(i));
    fprintf(1,'RtChan4 InputLevel  : %4i mV\n', RtChan4_InputLevel(i));
    fprintf(1,'RtChan4 InputEdge   : %d \n', RtChan4_InputEdge(i));
    fprintf(1,'RtChan4 CFDPresent  : %d \n', RtChan4_CFDPresent(i));
    fprintf(1,'RtChan4 CFDLevel    : %4i mV\n', RtChan4_CFDLevel(i));
    fprintf(1,'RtChan4 CFDZeroCross: %4i mV\n', RtChan4_CFDZeroCross(i));
    fprintf(1,'-------------------------------------\n'); 
 
end;
 

end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%                Headers for each histogram (curve)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i = 1:NumberOfCurves

CurveIndex(i) = fread(fid, 1, 'int32');
fprintf(1,'\n        Curve Index: %d\n', CurveIndex(i));

TimeOfRecording(i) = fread(fid, 1, 'uint');

%  The PicoHarp software saves the time of recording
%  in a 32 bit serial time value as defined in all C libraries.
%  This equals the number of seconds elapsed since midnight
%  (00:00:00), January 1, 1970, coordinated universal time.
%  The conversion to normal date and time strings is tricky...

TimeOfRecording(i) = TimeOfRecording(i)/24/60/60+25569+693960;
fprintf(1,'  Time of Recording: %s \n', datestr(TimeOfRecording(i),'dd-mmm-yyyy HH:MM:SS'));

HardwareIdent(:,i) = char(fread(fid, 16, 'char'));
fprintf(1,'Hardware Identifier: %s\n', HardwareIdent(:,i));
    
HardwareVersion(:,i) = char(fread(fid, 8, 'char'));
fprintf(1,'   Hardware Version: %s\n', HardwareVersion(:,i));    
    
HardwareSerial(i) = fread(fid, 1, 'int32');
fprintf(1,'   HW Serial Number: %d\n', HardwareSerial(i));

SyncDivider(i) = fread(fid, 1, 'int32');
fprintf(1,'       Sync divider: %d \n', SyncDivider(i));

CFDZeroCross0(i) = fread(fid, 1, 'int32');
fprintf(1,'    CFD 0 ZeroCross: %3i mV\n', CFDZeroCross0(i));

CFDLevel0(i) = fread(fid, 1, 'int32');
fprintf(1,'    CFD 0 Discr.   : %3i mV\n', CFDLevel0(i));

CFDZeroCross1(i) = fread(fid, 1, 'int32');
fprintf(1,'    CFD 1 ZeroCross: %3i mV\n', CFDZeroCross1(i));

CFDLevel1(i) = fread(fid, 1, 'int32');
fprintf(1,'    CFD 1 Discr.   : %3i mV\n', CFDLevel1(i));

Offset(i) = fread(fid, 1, 'int32');
fprintf(1,'             Offset: %d\n', Offset(i));

RoutingChannel(i) = fread(fid, 1, 'int32');
fprintf(1,'    Routing Channel: %d\n', RoutingChannel(i));

ExtDevices(i) = fread(fid, 1, 'int32');
fprintf(1,'   External Devices: %d \n', ExtDevices(i));

MeasMode(i) = fread(fid, 1, 'int32');
fprintf(1,'   Measurement Mode: %d\n', MeasMode(i));

SubMode(i) = fread(fid, 1, 'int32');
fprintf(1,'           Sub-Mode: %d\n', SubMode(i));

P1(i) = fread(fid, 1, 'float');
fprintf(1,'                 P1: %d\n', P1(i));
P2(i) = fread(fid, 1, 'float');
fprintf(1,'                 P2: %d\n', P2(i));
P3(i) = fread(fid, 1, 'float');
fprintf(1,'                 P3: %d\n', P3(i));

RangeNo(i) = fread(fid, 1, 'int32');
fprintf(1,'          Range No.: %d\n', RangeNo(i));

Resolution(i) = fread(fid, 1, 'float');
fprintf(1,'         Resolution: %2.6g ns \n', Resolution(i));

Channels(i) = fread(fid, 1, 'int32');
fprintf(1,'           Channels: %d \n', Channels(i));

Tacq(i) = fread(fid, 1, 'int32');
fprintf(1,'   Acquisition Time: %d ms \n', Tacq(i));

StopAfter(i) = fread(fid, 1, 'int32');
fprintf(1,'         Stop After: %d ms \n', StopAfter(i));

StopReason(i) = fread(fid, 1, 'int32');
fprintf(1,'        Stop Reason: %d\n', StopReason(i));

InpRate0(i) = fread(fid, 1, 'int32');
fprintf(1,'       Input Rate 0: %d Hz\n', InpRate0(i));

InpRate1(i) = fread(fid, 1, 'int32');
fprintf(1,'       Input Rate 1: %d Hz\n', InpRate1(i));

HistCountRate(i) = fread(fid, 1, 'int32');
fprintf(1,'   Hist. Count Rate: %d cps\n', HistCountRate(i));

IntegralCount(i) = fread(fid, 1, 'int64');
fprintf(1,'     Integral Count: %d\n', IntegralCount(i));

Reserved(i) = fread(fid, 1, 'int32');
fprintf(1,'           Reserved: %d\n', Reserved(i));

DataOffset(i) = fread(fid, 1, 'int32');
fprintf(1,'        Data Offset: %d\n', DataOffset(i));

% below is new in format version 2.0

RouterModelCode(i)     = fread(fid, 1, 'int32');
RouterEnabled(i)       = fread(fid, 1, 'int32');
RtChan_InputType(i)    = fread(fid, 1, 'int32');
RtChan_InputLevel(i)   = fread(fid, 1, 'int32');
RtChan_InputEdge(i)    = fread(fid, 1, 'int32');
RtChan_CFDPresent(i)   = fread(fid, 1, 'int32');
RtChan_CFDLevel(i)     = fread(fid, 1, 'int32');
RtChan_CFDZeroCross(i) = fread(fid, 1, 'int32');

if RouterModelCode(i)>0

    fprintf(1,'  Router Model Code: %d\n', RouterModelCode(i));
    fprintf(1,'     Router Enabled: %d\n', RouterEnabled(i));
    fprintf(1,'RtChan InputType   : %d\n', RtChan_InputType(i));
    fprintf(1,'RtChan InputLevel  : %4i mV\n', RtChan_InputLevel(i));
    fprintf(1,'RtChan InputEdge   : %d\n', RtChan_InputEdge(i));
    fprintf(1,'RtChan CFDPresent  : %d\n', RtChan_CFDPresent(i));
    fprintf(1,'RtChan CFDLevel    : %4i mV\n', RtChan_CFDLevel(i));
    fprintf(1,'RtChan CFDZeroCross: %4i mV\n', RtChan_CFDZeroCross(i));
end;

end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%          Reads all histograms into one matrix
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i = 1:NumberOfCurves
    fseek(fid,DataOffset(i),'bof');
    Counts(:,i) = fread(fid, Channels(i), 'uint32');
end;

Peak=max(Counts);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%          Summary
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(1,'\n');
fprintf(1,'\n');
fprintf(1,'=====================================================\n');
fprintf(1,'                     SUMMARY                         \n');
fprintf(1,'=====================================================\n');
fprintf(1,' Curve    Channel     Number of    Peak     Integral \n');
fprintf(1,' index   resolution   channels     count     count   \n');
fprintf(1,'=====================================================\n');

for i = 1:NumberOfCurves
fprintf(1,'  %3i       %2.6g  %10i  %10i  %10i\n', CurveIndex(i),Resolution(i), Channels(i), Peak(i), IntegralCount(i));   
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%          This is a simple display of the histogram(s)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


figure(1);
semilogy(Counts);
% axis([0 max(max(Channels)) 1 10*max(max(Counts))]);
xlabel('Channel #');
ylabel('Counts');

if NumberOfCurves<21
   legend(num2str((1:NumberOfCurves)'),0);
end;

fclose(fid);