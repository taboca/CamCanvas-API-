#!/bin/sh

# This compiles the binary for production. If you need to add debug level check mtasc options 

./swfmill simple library.xml ./swf/camcanvas.swf
./mtasc -version 8 -swf ./swf/camcanvas.swf -main ./src/camcanvas.as -cp lib/std -cp lib/std8 
