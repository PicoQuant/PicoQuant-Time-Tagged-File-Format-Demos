% Read_PHU.m    Read PicoQuant Unified Histogram Files
% This is demo code. Use at your own risk. No warranties.
% Marcus Sackrow, Michael Wahl, PicoQUant GmbH, December 2013

% Note that marker events have a lower time resolution and may therefore appear 
% in the file slightly out of order with respect to regular (photon) event records.
% This is by design. Markers are designed only for relatively coarse 
% synchronization requirements such as image scanning. 

% T Mode data are written to an output file [filename].out 
% We do not keep it in memory because of the huge amout of memory
% this would take in case of large files. Of course you can change this, 
% e.g. if your files are not too big. 
% Otherwise it is best process the data on the fly and keep only the results.

% All header data are introduced as Variable to Matlab and can directly be
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

    % start Main program
    [filename, pathname]=uigetfile('*.phu', 'PQ histogram data:');
    fid=fopen([pathname filename]);
    
    fprintf(1,'\n');
    Magic = fread(fid, 8, '*char');
    if not(strcmp(Magic(Magic~=0)','PQHISTO'))
        error('Magic invalid, this is not a PHU file.');
    end;
    Version = fread(fid, 8, '*char');
    fprintf(1,'Tag Version: %s\n', Version);

    % there is no repeat.. until (or do..while) construct in matlab so we use
    % while 1 ... if (expr) break; end; end;
    while 1
        % read Tag Head
        TagIdent = fread(fid, 32, '*char'); % TagHead.Ident
        TagIdent = (TagIdent(TagIdent ~= 0))'; % remove #0 and make more readable
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
        % check Type of Header
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

     
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%          Read all histograms into one matrix
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i = 1:HistoResult_NumberOfCurves
    fseek(fid,HistResDscr_DataOffset(i),'bof');
    Counts(:,i) = fread(fid, HistResDscr_HistogramBins(i), 'uint32');
end;    

Peak=max(Counts);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%          Summary
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(1,'\n');
fprintf(1,'\n');
fprintf(1,'=======================================================\n');
fprintf(1,'                HISTOGRAM DATA SUMMARY                 \n');
fprintf(1,'=======================================================\n');
fprintf(1,'  Curve    Time bin    Number of     Peak     Integral \n');
fprintf(1,'  index   resolution   time bins     count     count   \n');
fprintf(1,'=======================================================\n');

for i = 1:HistoResult_NumberOfCurves
fprintf(1,'  %3i       %2.6g  %10i  %10i  %10i\n', HistResDscr_CurveIndex(i),HistResDscr_MDescResolution(i), HistResDscr_HistogramBins(i), Peak(i), HistResDscr_IntegralCount(i));   
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%          Next is a simple display of the histogram(s)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure(1);
semilogy(Counts);
% axis([0 max(max(Channels)) 1 10*max(max(Counts))]);
xlabel('Channel #');
ylabel('Counts');

if HistoResult_NumberOfCurves<21
   legend(num2str((1:HistoResult_NumberOfCurves)'),0);
end;

fclose(fid);



