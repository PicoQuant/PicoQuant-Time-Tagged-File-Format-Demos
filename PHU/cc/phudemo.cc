/************************************************************************

  PicoQuant Unified Histogram (PHU) File Access Demo in C/C++

  This is demo code. Use at your own risk. No warranties.

  Tested with MS Visual Studio 2010 and Mingw 4.5

  Marcus Sackrow, Michael Wahl PicoQuant GmbH, December 2013
  Michael Wahl, revised July 2014


************************************************************************/

#include  <windows.h>
#include  <dos.h>
#include  <stdio.h>
#include  <conio.h>
#include  <stddef.h>
#include  <stdlib.h>
#include    <time.h>

// some important Tag Idents (TTagHead.Ident) that we will need to read the most common content of a PHU file
// check the output of this program and consult the tag dictionary if you need more

#define PHUTagNumCurves     "HistoResult_NumberOfCurves"  // Number of histograms (curves) in the file;
#define PHUTagDataOffset    "HistResDscr_DataOffset"      // File offset of binary histogram data 
#define PHUTagHistogramBins "HistResDscr_HistogramBins"   // Number of bins in histogram
#define PHUTagHistResol     "HistResDscr_MDescResolution" // Histogram bin width in seconds
#define FileTagEnd          "Header_End"                  // Always appended as last tag (BLOCKEND)

#define MAXCURVES   512  
#define MAXHISTBINS 65536

// TagTypes  (TTagHead.Typ)
#define tyEmpty8      0xFFFF0008
#define tyBool8       0x00000008
#define tyInt8        0x10000008
#define tyBitSet64    0x11000008
#define tyColor8      0x12000008
#define tyFloat8      0x20000008
#define tyTDateTime   0x21000008
#define tyFloat8Array 0x2001FFFF
#define tyAnsiString  0x4001FFFF
#define tyWideString  0x4002FFFF
#define tyBinaryBlob  0xFFFFFFFF


#pragma pack(8) //structure alignment to 8 byte boundaries

// A Tag entry
struct TgHd{
  char Ident[32];     // Identifier of the tag
  int Idx;            // Index for multiple tags or -1
  unsigned int Typ;  // Type of tag ty..... see const section
    long long TagValue; // Value of tag.
} TagHead;


// TDateTime (in file) to time_t (standard C) conversion

const int EpochDiff = 25569; // days between 30/12/1899 and 01/01/1970
const int SecsInDay = 86400; // number of seconds in a day

time_t TDateTime_TimeT(double Convertee)
{
  time_t Result((long)(((Convertee) - EpochDiff) * SecsInDay));
  return Result;
}

FILE *fpin,*fpout;
bool IsT2;
long long RecNum;
long long oflcorrection;
long long truensync, truetime;
int m, c;
double GlobRes = 0.0;
double Resolution = 0.0;
unsigned int dlen = 0;
unsigned int cnt_0=0, cnt_1=0;




int main(int argc, char* argv[])
{
  char Magic[8];
  char Version[8];
  char Buffer[40];
  char* AnsiBuffer;
  WCHAR* WideBuffer;
  int i,j,Result;
  long long NumCurves = -1;

  struct{ //there are actually more items in the curve headers, here we keep only the minimum
          long DataOffset;
          long HistogramBins;
          double Resolution;
  } CurveHdr[MAXCURVES]; //storage for ALL curve hedares

  unsigned int Counts[MAXHISTBINS]; //storage for ONE histogram, we read them sequentially



  printf("\nPicoQuant Unified Histogram (PHU Mode File Demo");
  printf("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n");

  if((argc<3)||(argc>3))
  {
   printf("usage: ht2demo infile oufile\n");
   printf("infile is a phu file (binary)\n");
   printf("outfile is ASCII\n");
   _getch();
   exit(-1);
  }
  if((fpin=fopen(argv[1],"rb"))==NULL)
      {printf("\n ERROR! Input file cannot be opened, aborting.\n"); goto ex;}


  if((fpout=fopen(argv[2],"w"))==NULL)
   {printf("\n ERROR! Output file cannot be opened, aborting.\n"); goto ex;}

  printf("\n Loading data from %s \n", argv[1]);
  printf("\n Writing output to %s \n", argv[2]);

  Result = fread( &Magic, 1, sizeof(Magic) ,fpin);
  if (Result!= sizeof(Magic))
  {
    printf("\nerror reading header, aborted.");
      goto close;
  }
  Result = fread(&Version, 1, sizeof(Version) ,fpin);
  if (Result!= sizeof(Version))
    {
    printf("\nerror reading header, aborted.");
      goto close;
  }
  if (strncmp(Magic, "PQHISTO", 7))
  {
    printf("\nWrong Magic, this is not a PHU file.");
    goto close;
  }
  fprintf(fpout, "Tag Version: %s \n", Version);

  // read tagged header
  do
  {
    // This loop is very generic. It reads all header items and displays the identifier and the
    // associated value, quite independent of what they mean in detail.
    // Only some selected items are kept in memory because they are needed to subsequently 
	// interpret the histogram data. See "retrieve selected value.."

    Result = fread( &TagHead, 1, sizeof(TagHead) ,fpin);
    if (Result!= sizeof(TagHead))
    {
         printf("\nIncomplete File.");
         goto close;
    }

    strcpy(Buffer, TagHead.Ident);
    if (TagHead.Idx > -1)
    {
      sprintf(Buffer, "%s(%d)", TagHead.Ident,TagHead.Idx);
    }
    fprintf(fpout, "\n%-40s", Buffer);

    switch (TagHead.Typ)
    {
        case tyEmpty8:
        fprintf(fpout, "<empty Tag>");
        break;
      case tyBool8:
        fprintf(fpout, "%s", bool(TagHead.TagValue)?"True":"False");
        break;
      case tyInt8:
        fprintf(fpout, "%lld", TagHead.TagValue);

        // retrieve  selected value we need to process the histogram data
        if (strcmp(TagHead.Ident, PHUTagNumCurves  )==0) // Number of curves (histograms)
                    NumCurves = TagHead.TagValue;
        if(NumCurves > MAXCURVES) 
        {
                    printf("\nToo many curves.");
                    goto close;
        }

		// retrieve selected value we need to process the histogram data
        if (strcmp(TagHead.Ident, PHUTagDataOffset )==0)  // Histogram data offset
             if(TagHead.Idx < MAXCURVES)
                    CurveHdr[TagHead.Idx].DataOffset = TagHead.TagValue;

		// retrieve selected value we need to process the histogram data
        if (strcmp(TagHead.Ident, PHUTagHistogramBins )==0)  // Number of histogram bins
             if(TagHead.Idx < MAXCURVES)
                    CurveHdr[TagHead.Idx].HistogramBins = TagHead.TagValue;

        break;
      case tyBitSet64:
        fprintf(fpout, "0x%16.16X", TagHead.TagValue);
        break;
      case tyColor8:
        fprintf(fpout, "0x%16.16X", TagHead.TagValue);
        break;
      case tyFloat8:
        fprintf(fpout, "%E", *(double*)&(TagHead.TagValue));

		// retrieve selected value we need to process the histogram data
        if (strcmp(TagHead.Ident, PHUTagHistResol  )==0) // Resolution (histogram bin width)
            if(TagHead.Idx < MAXCURVES)
                    CurveHdr[TagHead.Idx].Resolution = *(double*)&(TagHead.TagValue);
  
        break;
      case tyFloat8Array:
        fprintf(fpout, "<Float Array with %d Entries>", TagHead.TagValue / sizeof(double));
        // only seek the Data, if one needs the data, it can be loaded here
        fseek(fpin, (long)TagHead.TagValue, SEEK_CUR);
        break;
      case tyTDateTime:
        time_t CreateTime;
        CreateTime = TDateTime_TimeT(*((double*)&(TagHead.TagValue)));
        fprintf(fpout, "%s", asctime(gmtime(&CreateTime)), "\0");
        break;
      case tyAnsiString:
        AnsiBuffer = (char*)calloc((size_t)TagHead.TagValue,1);
                Result = fread(AnsiBuffer, 1, (size_t)TagHead.TagValue, fpin);
              if (Result!= TagHead.TagValue)
        {
          printf("\nIncomplete File.");
          free(AnsiBuffer);
                  goto close;
        }
        fprintf(fpout, "%s", AnsiBuffer);
        free(AnsiBuffer);
        break;
            case tyWideString:
        WideBuffer = (WCHAR*)calloc((size_t)TagHead.TagValue,1);
                Result = fread(WideBuffer, 1, (size_t)TagHead.TagValue, fpin);
              if (Result!= TagHead.TagValue)
        {
          printf("\nIncomplete File.");
          free(WideBuffer);
                  goto close;
        }
        fwprintf(fpout, L"%s", WideBuffer);
        free(WideBuffer);
        break;
            case tyBinaryBlob:
        fprintf(fpout, "<Binary Blob contains %d Bytes>", TagHead.TagValue);
        // only seek the Data, if one needs the data, it can be loaded here
        fseek(fpin, (long)TagHead.TagValue, SEEK_CUR);
        break;
      default:
        printf("Illegal Type identifier found! Broken file?");
        goto close;
    }
  }
  while((strncmp(TagHead.Ident, FileTagEnd, sizeof(FileTagEnd))));
  fprintf(fpout, "\n-----------------------\n");
  // End header loading

  // Now read the histogram data
  for(i=0; i<NumCurves ; ++i)
  {

		fprintf(fpout, "Curve#  %u\n", i);
		fprintf(fpout, "nBins:  %u\n", CurveHdr[i].HistogramBins);
		fprintf(fpout, "Resol:  %E\n", CurveHdr[i].Resolution);
        fprintf(fpout, "Counts: \n");

        fseek (fpin, CurveHdr[i].DataOffset, SEEK_SET);
       
        Result = fread (&Counts, sizeof (unsigned int), CurveHdr[i].HistogramBins, fpin);
        if (Result!= CurveHdr[i].HistogramBins)
        {
          printf("\nerror reading histogram data. ");
          goto close;
        }

        for(j=0; j<CurveHdr[i].HistogramBins ; ++j)
		   fprintf(fpout, "%u\n", Counts[j]);

        fprintf(fpout, "\n-----------------------\n");
  }



close:
  fclose(fpin);
  fclose(fpout);

ex:
  printf("\n any key...");
  getch();
  exit(0);
  return(0);
}