#Structure of the pre-histogrammed Image Data File


|Data Item    ||||Type                 |Description|
|-------------||||---------------------------------|


|PixX         ||||''int32''            |pixels in X-direction                                   |
|PixY         ||||''int32''            |pixels in Y-direction                                   |
|PixResol     ||||''float32''          |spatial pixel resolution in μm                          |
|TCSPCChannels||||''int32''            |number of TCSPC channels per pixel                      |
|TimeResol    ||||''float32''          |time resolution of the TCSPC histograms in ns           |
|The following block will appear in the file for each ''y = 1 to <PixY>''                  ||||||
| |The following block will appear in block (y) for each ''x = 1 to <PixX>''                |||||
| | | The following data will appear in the block (x,y) for each ''t = 1 to <TCSPCChannels>''||||
| | | | ''HistogramData [x,y,t]'' |''int32''| counts of the TCSPC channel t of pixel (x,y)      |
| | | end of block                                                                           ||||
| | end of block                                                                            |||||
| end of block                                                                             ||||||
