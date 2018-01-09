To use the sample Visual Basic event handler, both RetroEventHandler.bat and 
SampleRetroEventHandler need to be installed.

To overcome the inherent limitations of Visual Basic, The VB version of RetroEventHandler 
comes in two files: RetroEventHandler.bat and SampleRetroEventHandler.exe. 

Since Visual Basic does not have the ability to pass on a return value upon exiting, it 
instead creates a file to indicate any return value. RetroEventHandler.bat calls  
SampleRetroEventHandler.exe and checks for the existence of the file "returnCancel" upon 
the completion of SampleRetroEventHandler.exe.