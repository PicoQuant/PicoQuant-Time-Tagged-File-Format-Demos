
/************************************************************************

  PicoHarp 300    File Access Demo in C

  Demo access to binary PicoHarp 300 Data Files (*.phd)
  for file format version 2.0 only!
  Read a PicoHarp data file and dump the contents in ASCII
  Michael Wahl, PicoQuant GmbH, September 2006

  Tested with the following compilers:

  - MinGW 2.0.0-3 (free compiler for Win 32 bit)
  - MS Visual C++ 4.0/5.0/6.0 (Win 32 bit)
  - Borland C++ 5.5 (Win 32 bit)

  It should work with most others.
  Observe the 4-byte structure alignment!

  This is demo code. Use at your own risk. No warranties.

************************************************************************/


#include <stdio.h>
#include <time.h>
#include <string.h>

#define DISPCURVES 8
#define MAXCURVES 512
#define MAXCHANNELS 65536

/*
The following structures are used to hold the file data.
They directly reflect the file structure.
The data types used here to match the file structure are correct
for the tested compilers.
They may have to be changed for other compilers.
*/


#pragma pack(4) //structure alignment to 4 byte boundaries

/* These are substructures used below */

typedef struct{ float Start;
                float Step;
				float End;  } tParamStruct;

typedef struct{ int MapTo;
				int Show; } tCurveMapping;

/* The following represents the readable ASCII file header portion */

struct {		char Ident[16];				//"PicoHarp 300"
				char FormatVersion[6];		//file format version
				char CreatorName[18];		//name of creating software
				char CreatorVersion[12];	//version of creating software
				char FileTime[18];
				char CRLF[2];
				char CommentField[256]; } TxtHdr;

/* The following is binary file header information */

struct {		int Curves;
				int BitsPerHistoBin;
				int RoutingChannels;
				int NumberOfBoards;
				int ActiveCurve;
				int MeasMode;
				int SubMode;
				int RangeNo;
				int Offset;
				int Tacq;				// in ms
				int StopAt;
				int StopOnOvfl;
				int Restart;
				int DispLinLog;
				int DispTimeFrom;		// 1ns steps
				int DispTimeTo;
				int DispCountsFrom;
				int DispCountsTo;
				tCurveMapping DispCurves[DISPCURVES];	
				tParamStruct Params[3];
				int RepeatMode;
				int RepeatsPerCurve;
				int RepeatTime;
				int RepeatWaitTime;
				char ScriptName[20];	} BinHdr;

/* The next is a board specific header */

struct {		
				char HardwareIdent[16]; 
				char HardwareVersion[8]; 
				int HardwareSerial; 
				int SyncDivider;
				int CFDZeroCross0;
				int CFDLevel0;
				int CFDZeroCross1;
				int CFDLevel1;
				float Resolution;
				//below is new in format version 2.0
				int RouterModelCode;
				int RouterEnabled;
				int RtChan1_InputType; 
				int RtChan1_InputLevel;
				int RtChan1_InputEdge;
				int RtChan1_CFDPresent;
				int RtChan1_CFDLevel;
				int RtChan1_CFDZeroCross;
				int RtChan2_InputType; 
				int RtChan2_InputLevel;
				int RtChan2_InputEdge;
				int RtChan2_CFDPresent;
				int RtChan2_CFDLevel;
				int RtChan2_CFDZeroCross;
				int RtChan3_InputType; 
				int RtChan3_InputLevel;
				int RtChan3_InputEdge;
				int RtChan3_CFDPresent;
				int RtChan3_CFDLevel;
				int RtChan3_CFDZeroCross;
				int RtChan4_InputType; 
				int RtChan4_InputLevel;
				int RtChan4_InputEdge;
				int RtChan4_CFDPresent;
				int RtChan4_CFDLevel;
				int RtChan4_CFDZeroCross;
	} BoardHdr;

/* The following are the curve headers */

struct{			int CurveIndex;
				unsigned long TimeOfRecording; //this is a time_t
				char HardwareIdent[16];
				char HardwareVersion[8];
				int  HardwareSerial;
				int SyncDivider;
				int CFDZeroCross0;
				int CFDLevel0;
				int CFDZeroCross1;
				int CFDLevel1;			
				int Offset;
				int RoutingChannel;
				int ExtDevices;
				int MeasMode;
				int SubMode;
				float P1;  
				float P2;  
				float P3;  
				int RangeNo;
				float Resolution;		
				int Channels;			
				int Tacq;	
				int StopAfter;
				int StopReason;
				int InpRate0;
				int	InpRate1;
				int HistCountRate;
				__int64 IntegralCount;
				int reserved; 
				int DataOffset;
				//below is new in format version 2.0
				int RouterModelCode;
				int RouterEnabled;
				int RtChan_InputType; 
				int RtChan_InputLevel;
				int RtChan_InputEdge;
				int RtChan_CFDPresent;
				int RtChan_CFDLevel;
				int RtChan_CFDZeroCross;
	 } CurveHdr[MAXCURVES];


/* This is the count data of one curve */

unsigned int Counts[MAXCHANNELS];


int main(int argc, char* argv[])
{

 FILE *fpin,*fpout; 		/* input/output file pointers */
 int i,j,result;

 printf("\nPicoHarp File Demo");
 printf("\n~~~~~~~~~~~~~~~~~~");

 if(argc!=3)
 {
  printf("\nUsage: phdemo infile outfile");
  printf("\ninfile is a binary PicoHarp 300 data file (*.phd)");
  printf("\noutfile will be ASCII");
  goto ex;
 }

 if((fpin=fopen(argv[1],"rb"))==NULL)
 {
  printf("\ncannot open input file\n");
  goto ex;
 }

 if((fpout=fopen(argv[2],"w"))==NULL)
  {
   printf("\ncannot open output file\n");
   goto ex;
  }

 result = fread( &TxtHdr, 1, sizeof(TxtHdr) ,fpin);
 if (result!= sizeof(TxtHdr))
 {
  printf("\nerror reading txt header, aborted.");
  goto close;
 }

 fprintf(fpout,"Ident            : %.*s\n",sizeof(TxtHdr.Ident),TxtHdr.Ident);
 fprintf(fpout,"Format Version   : %.*s\n",sizeof(TxtHdr.FormatVersion),TxtHdr.FormatVersion);
 fprintf(fpout,"Creator Name     : %.*s\n",sizeof(TxtHdr.CreatorName),TxtHdr.CreatorName);
 fprintf(fpout,"Creator Version  : %.*s\n",sizeof(TxtHdr.CreatorVersion),TxtHdr.CreatorVersion);
 fprintf(fpout,"Time of Creation : %.*s\n",sizeof(TxtHdr.FileTime),TxtHdr.FileTime);
 fprintf(fpout,"File Comment     : %.*s\n",sizeof(TxtHdr.CommentField),TxtHdr.CommentField);

 if(  strncmp(TxtHdr.FormatVersion,"2.0",3)  )
 {
    printf("\nError: File format version is %s. This program is for v. 2.0 only.", TxtHdr.FormatVersion);
    goto ex;
 }

 result = fread( &BinHdr, 1, sizeof(BinHdr) ,fpin);
 if (result!= sizeof(BinHdr))
 {
   printf("\nerror reading bin header, aborted.");
   goto ex;
 }
 fprintf(fpout,"No of Curves     : %ld\n",BinHdr.Curves);
 fprintf(fpout,"Bits per HistoBin: %ld\n",BinHdr.BitsPerHistoBin);
 fprintf(fpout,"RoutingChannels  : %ld\n",BinHdr.RoutingChannels);
 fprintf(fpout,"No of Boards     : %ld\n",BinHdr.NumberOfBoards);
 fprintf(fpout,"Active Curve     : %ld\n",BinHdr.ActiveCurve);
 fprintf(fpout,"Measurement Mode : %ld\n",BinHdr.MeasMode);
 fprintf(fpout,"Sub-Mode         : %ld\n",BinHdr.SubMode);
 fprintf(fpout,"Range No         : %ld\n",BinHdr.RangeNo);
 fprintf(fpout,"Offset           : %ld\n",BinHdr.Offset);
 fprintf(fpout,"AcquisitionTime  : %ld\n",BinHdr.Tacq);
 fprintf(fpout,"Stop at          : %ld\n",BinHdr.StopAt);
 fprintf(fpout,"Stop on Ovfl.    : %ld\n",BinHdr.StopOnOvfl);
 fprintf(fpout,"Restart          : %ld\n",BinHdr.Restart);
 fprintf(fpout,"DispLinLog       : %ld\n",BinHdr.DispLinLog);
 fprintf(fpout,"DispTimeAxisFrom : %ld\n",BinHdr.DispTimeFrom);
 fprintf(fpout,"DispTimeAxisTo   : %ld\n",BinHdr.DispTimeTo);
 fprintf(fpout,"DispCountAxisFrom: %ld\n",BinHdr.DispCountsFrom);
 fprintf(fpout,"DispCountAxisTo  : %ld\n",BinHdr.DispCountsTo);

 for(i=0;i<DISPCURVES;++i)
 {
  fprintf(fpout,"---------------------\n");
  fprintf(fpout,"Curve No %1d\n",i);
  fprintf(fpout," MapTo           : %ld\n",BinHdr.DispCurves[i].MapTo);
  if(BinHdr.DispCurves[i].Show !=0)
  {
   fprintf(fpout," Show            : true\n");
  }
  else
  {
   fprintf(fpout," Show            : false\n");
  }
  fprintf(fpout,"---------------------\n");
 }

 for(i=0;i<3;++i)
 {
  fprintf(fpout,"---------------------\n");
  fprintf(fpout,"Parameter No %1d\n",i);
  fprintf(fpout," Start           : %f\n",BinHdr.Params[i].Start);
  fprintf(fpout," Step            : %f\n",BinHdr.Params[i].Step);
  fprintf(fpout," End             : %f\n",BinHdr.Params[i].End);
  fprintf(fpout,"---------------------\n");
 }

 fprintf(fpout,"Repeat Mode      : %ld\n",BinHdr.RepeatMode);
 fprintf(fpout,"Repeats per Curve: %ld\n",BinHdr.RepeatsPerCurve);
 fprintf(fpout,"Repeat Time      : %ld\n",BinHdr.RepeatTime);
 fprintf(fpout,"Repeat wait Time : %ld\n",BinHdr.RepeatWaitTime);
 fprintf(fpout,"Script Name      : %.*s\n",sizeof(BinHdr.ScriptName),
                                                  BinHdr.ScriptName);

 for(i=0;i<BinHdr.NumberOfBoards;++i)
 {
  fprintf(fpout,"---------------------\n");
  result = fread( &BoardHdr, 1, sizeof(BoardHdr) ,fpin);
  if (result!= sizeof(BoardHdr))
  {
    printf("\nerror reading board header, aborted.");
    goto close;
  }
  fprintf(fpout,"Board No %1d\n",i);
  fprintf(fpout," HardwareIdent   : %.*s\n",sizeof(BoardHdr.HardwareIdent),BoardHdr.HardwareIdent);
  fprintf(fpout," HardwareVersion : %.*s\n",sizeof(BoardHdr.HardwareVersion),BoardHdr.HardwareVersion);
  fprintf(fpout," HardwareSerial  : %ld\n",BoardHdr.HardwareSerial);
  fprintf(fpout," SyncDivider     : %ld\n",BoardHdr.SyncDivider);
  fprintf(fpout," CFDZeroCross0   : %ld\n",BoardHdr.CFDZeroCross0);
  fprintf(fpout," CFDLevel0       : %ld\n",BoardHdr.CFDLevel0 );
  fprintf(fpout," CFDZeroCross1   : %ld\n",BoardHdr.CFDZeroCross1);
  fprintf(fpout," CFDLevel1       : %ld\n",BoardHdr.CFDLevel1);
  fprintf(fpout," Resolution      : %lf\n",BoardHdr.Resolution);

  if(BoardHdr.RouterModelCode>0) //otherwise this information is meaningless
  {
    fprintf(fpout," RouterModelCode       : %ld\n",BoardHdr.RouterModelCode);  
    fprintf(fpout," RouterEnabled         : %ld\n",BoardHdr.RouterEnabled);   

    fprintf(fpout," RtChan1_InputType     : %ld\n",BoardHdr.RtChan1_InputType);
    fprintf(fpout," RtChan1_InputLevel    : %ld\n",BoardHdr.RtChan1_InputLevel); 
    fprintf(fpout," RtChan1_InputEdge     : %ld\n",BoardHdr.RtChan1_InputEdge);
    fprintf(fpout," RtChan1_CFDPresent    : %ld\n",BoardHdr.RtChan1_CFDPresent); 
    fprintf(fpout," RtChan1_CFDLevel      : %ld\n",BoardHdr.RtChan1_CFDLevel);
    fprintf(fpout," RtChan1_CFDZeroCross  : %ld\n",BoardHdr.RtChan1_CFDZeroCross);

    fprintf(fpout," RtChan2_InputType     : %ld\n",BoardHdr.RtChan2_InputType);
    fprintf(fpout," RtChan2_InputLevel    : %ld\n",BoardHdr.RtChan2_InputLevel); 
    fprintf(fpout," RtChan2_InputEdge     : %ld\n",BoardHdr.RtChan2_InputEdge);
    fprintf(fpout," RtChan2_CFDPresent    : %ld\n",BoardHdr.RtChan2_CFDPresent); 
    fprintf(fpout," RtChan2_CFDLevel      : %ld\n",BoardHdr.RtChan2_CFDLevel);
    fprintf(fpout," RtChan2_CFDZeroCross  : %ld\n",BoardHdr.RtChan2_CFDZeroCross);
 
    fprintf(fpout," RtChan3_InputType     : %ld\n",BoardHdr.RtChan3_InputType);
    fprintf(fpout," RtChan3_InputLevel    : %ld\n",BoardHdr.RtChan3_InputLevel); 
    fprintf(fpout," RtChan3_InputEdge     : %ld\n",BoardHdr.RtChan3_InputEdge);
    fprintf(fpout," RtChan3_CFDPresent    : %ld\n",BoardHdr.RtChan3_CFDPresent); 
    fprintf(fpout," RtChan3_CFDLevel      : %ld\n",BoardHdr.RtChan3_CFDLevel);
    fprintf(fpout," RtChan3_CFDZeroCross  : %ld\n",BoardHdr.RtChan3_CFDZeroCross);
 
    fprintf(fpout," RtChan4_InputType     : %ld\n",BoardHdr.RtChan4_InputType);
    fprintf(fpout," RtChan4_InputLevel    : %ld\n",BoardHdr.RtChan4_InputLevel); 
    fprintf(fpout," RtChan4_InputEdge     : %ld\n",BoardHdr.RtChan4_InputEdge);
    fprintf(fpout," RtChan4_CFDPresent    : %ld\n",BoardHdr.RtChan4_CFDPresent); 
    fprintf(fpout," RtChan4_CFDLevel      : %ld\n",BoardHdr.RtChan4_CFDLevel);
    fprintf(fpout," RtChan4_CFDZeroCross  : %ld\n",BoardHdr.RtChan4_CFDZeroCross);
  }
  fprintf(fpout,"---------------------\n");

 }

 /*
 The following is repeated here for all stored curves.
 */

  /*
 Read and display the curve headers.
 */
 for(i=0;i<BinHdr.Curves;++i)
 {
  fprintf(fpout,"---------------------\n");
  result = fread( &CurveHdr[i], 1, sizeof(CurveHdr[i]) ,fpin);
  if (result!= sizeof(CurveHdr[i]))
  {
    printf("\nerror reading curve header, aborted.");
    goto close;
  }
  fprintf(fpout,"Curve Index       : %ld\n",CurveHdr[i].CurveIndex);
  fprintf(fpout,"Time of Recording : %s\n",ctime((time_t*)&CurveHdr[i].TimeOfRecording));
  fprintf(fpout,"HardwareIdent     : %.*s\n",sizeof(CurveHdr[i].HardwareIdent),CurveHdr[i].HardwareIdent);
  fprintf(fpout,"HardwareVersion   : %.*s\n",sizeof(CurveHdr[i].HardwareVersion),CurveHdr[i].HardwareVersion);
  fprintf(fpout,"HardwareSerial    : %ld\n",CurveHdr[i].HardwareSerial);
  fprintf(fpout,"SyncDivider       : %ld\n",CurveHdr[i].SyncDivider);
  fprintf(fpout,"CFDZeroCross0     : %ld\n",CurveHdr[i].CFDZeroCross0);
  fprintf(fpout,"CFDLevel0         : %ld\n",CurveHdr[i].CFDLevel0 );
  fprintf(fpout,"CFDZeroCross1     : %ld\n",CurveHdr[i].CFDZeroCross1);
  fprintf(fpout,"CFDLevel1         : %ld\n",CurveHdr[i].CFDLevel1);
  fprintf(fpout,"Offset            : %ld\n",CurveHdr[i].Offset);
  fprintf(fpout,"RoutingChannel    : %ld\n",CurveHdr[i].RoutingChannel);
  fprintf(fpout,"ExtDevices        : %ld\n",CurveHdr[i].ExtDevices);
  fprintf(fpout,"Meas. Mode        : %ld\n",CurveHdr[i].MeasMode);
  fprintf(fpout,"Sub-Mode          : %ld\n",CurveHdr[i].SubMode);
  fprintf(fpout,"Par. 1            : %f\n",CurveHdr[i].P1);
  fprintf(fpout,"Par. 2            : %f\n",CurveHdr[i].P2);
  fprintf(fpout,"Par. 3            : %f\n",CurveHdr[i].P3);
  fprintf(fpout,"Range No          : %ld\n",CurveHdr[i].RangeNo);
  fprintf(fpout,"Resolution        : %f\n",CurveHdr[i].Resolution);
  fprintf(fpout,"Channels          : %ld\n",CurveHdr[i].Channels);
  fprintf(fpout,"Acq. Time         : %ld\n",CurveHdr[i].Tacq);
  fprintf(fpout,"Stop after        : %ld\n",CurveHdr[i].StopAfter);
  fprintf(fpout,"Stop Reason       : %ld\n",CurveHdr[i].StopReason);
  fprintf(fpout,"InpRate0          : %ld\n",CurveHdr[i].InpRate0);
  fprintf(fpout,"InpRate1          : %ld\n",CurveHdr[i].InpRate1);
  fprintf(fpout,"HistCountRate     : %ld\n",CurveHdr[i].HistCountRate);
  fprintf(fpout,"IntegralCount     : %I64d\n",CurveHdr[i].IntegralCount);
  fprintf(fpout,"reserved          : %ld\n",CurveHdr[i].reserved);
  fprintf(fpout,"dataoffset        : %ld\n",CurveHdr[i].DataOffset);

  if(CurveHdr[i].RouterModelCode>0)
  {
    fprintf(fpout,"RouterModelCode      : %ld\n",CurveHdr[i].RouterModelCode);  
    fprintf(fpout,"RouterEnabled        : %ld\n",CurveHdr[i].RouterEnabled);   
    fprintf(fpout,"RtChan_InputType     : %ld\n",CurveHdr[i].RtChan_InputType);
    fprintf(fpout,"RtChan_InputLevel    : %ld\n",CurveHdr[i].RtChan_InputLevel); 
    fprintf(fpout,"RtChan_InputEdge     : %ld\n",CurveHdr[i].RtChan_InputEdge);
    fprintf(fpout,"RtChan_CFDPresent    : %ld\n",CurveHdr[i].RtChan_CFDPresent); 
    fprintf(fpout,"RtChan_CFDLevel      : %ld\n",CurveHdr[i].RtChan_CFDLevel);
    fprintf(fpout,"RtChan_CFDZeroCross  : %ld\n",CurveHdr[i].RtChan_CFDZeroCross);
  }
 }

 /*
 Read and display the actual curve data.
 */
 fprintf(fpout,"---------------------\n");
 fprintf(fpout,"Counts:\n");

 for(i=0;i<BinHdr.Curves;++i)
 {
  fseek(fpin,CurveHdr[i].DataOffset,SEEK_SET);
  result = fread( &Counts, 4, CurveHdr[i].Channels ,fpin);
  if (result!= CurveHdr[i].Channels)
  {
    printf("\nerror reading count data, aborted. ");
    goto close;
  }
  for(j=0;j<CurveHdr[i].Channels;++j)
     fprintf(fpout,"%lu\n",Counts[j]);
  fprintf(fpout,"---------------------\n");
 }

close:
 fclose(fpin);
 fclose(fpout);
ex:
 printf("\npress return to exit");
 getchar();
 return(0);
}

