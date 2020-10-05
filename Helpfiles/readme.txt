The folder "DccmonHelp" contains the (editable) sources of the help files.


To add these help files to the application code:
1) Select with the mouse the folder "Supporting files" in the Project navigator at the left side of the Xcode window
2) From the Xcode "File menu", select "Add Files to ..."
   - Select the folder "DccmonHelp" from the Helpfiles folder
   - Make sure to select "Create folder references for any added folders"
   
   
To modify existing help files:
1) Modify the source files in the subfolder "DccmonHelp" of "Helpfiles"
2) Delete to Trash the subfolder "DccmonHelp" under "Supporting files"
3) Perform the steps described above under "To add ..."


If help files are added first to the project:
1) Edit "Programmer Dccmon-Info.plist" and add two rows:
   - Help book directory name
   - Help book identifier
2) Select with the mouse the "target" (Dccmon) in the Project navigator at the left side of the Xcode
   - Select the "Build Phases" tab
   - Edit (if needed) the "Copy Bundle Resources"


Note: editing the HTML files should be performed in Xcode, since TextEdit will change (ruin) the complete formatting 
