Webcam to Canvas JavaScript API 0.1
===
This API allows you to capture webcam images and use it in the canvas tag to do whatever you like. This version depends on a flash-based SWF file. The .as source is also part of this project and can be compiled with Mtasc. You can also simply use the less than 5K swf binary. This is a client side library and once you have the webcam image in the canvas, you can do anything. 

Online Projects using CamCanvas and Demos
====
http://remixpic.taboca.com/co/mozilla/
http://www.taboca.com/p/camcanvas/

Roadmap
====

* Cam Gestures - higher level edge/pattern detection
* More image manipulation samples ( eliminate background, chromakey etc ) 


Depends on: 
===

Mtasc - http://www.mtasc.org/#download 
SwfMill - http://swfmill.org/

How to
===
Put mtasc and swfmill binary in this directory and use the build script. 
You will also need ./lib/* from mtasc : ./lib/std and ./lib/std8

./build.sh

Cp the binary ./swf/* to the ./samples/ and enjoy the samples. 


