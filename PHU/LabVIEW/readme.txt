Demos for reading PicoQuant PHU files.
Michael Wahl, PicoQuant GmbH, April 2015

MainPHUdemo.vi is a demo that reads a PHU file and dumps its contents in 
an ASCII file. Note that this is not meant to be a conversion tool. 
You are encouraged to modify it for immediate processing of the data
according to whatever your application actually requires.
Conversion to ASCII is silly because it massively increases the file 
size and does not get you closer to the ultimate goal of somehow 
meaningfully processing the data.

MainTagBrowser.vi is a generic little demo that reads the header of
any kind of PicoQUant's tagged files (*.pco;*.pfs;*.phu;*.pqres;*.ptu;*.pus)
and lets you browse the header items. Payload data beyond the header will 
not be shown.

Common.llb is a library that provides sub-vis shared by the demos.

Disclaimer
This software is provided free of charge 'as is' without any guaranteed 
fitness for a specific purpose and without any liability for damage 
resulting from its use.
