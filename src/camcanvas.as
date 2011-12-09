package {

// Thanks http://www.websector.de/blog/2009/06/21/speed-up-jpeg-encoding-using-alchemy/
//import cmodule.as3_jpeg_wrapper.CLibInit;

// Thanks http://segfaultlabs.com/devlogs/alchemy-asynchronous-jpeg-encoding-2
import cmodule.aircall.CLibInit;

import flash.display.BitmapData;
import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.external.ExternalInterface;
import flash.media.Camera;
import flash.media.Video;
import flash.utils.ByteArray;

[SWF(backgroundColor=0x000000, frameRate=30)]
public class camcanvas extends Sprite{
	
	private var camera:Camera;
	private var video:Video;
	private var w:int;
	private var h:int;
	private var quality:int = 50;
	
	private var snapshot:BitmapData;
	private var pixels:Array;
	
//	private static var as3_jpeg_wrapper:Object;
	
	private var jpeglib:Object;
	private var encBytes:ByteArray;
	private var working:Boolean = false;
	
	public function camcanvas():void {
		
		ExternalInterface.addCallback("ccInit", exportInit);
		ExternalInterface.addCallback("ccCapture", exportCapture);
		ExternalInterface.addCallback("ccList", exportCameraList);
		
		if(stage) init();
		else addEventListener(Event.ADDED_TO_STAGE, init);
		
	}
	
	private function init(e:Event=null):void {
		removeEventListener(Event.ADDED_TO_STAGE, init);
		
		// Init stage
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		
		// load, wrap Jpeg encoder
//		var loader:CLibInit = new CLibInit;
//		as3_jpeg_wrapper = loader.init();
		
		var jpeginit:CLibInit = new CLibInit(); // get library
		jpeglib = jpeginit.init(); // initialize library exported class to an object

	}



	public function exportCapture():void {
		// Use async so that we can ignore requests while the last frame is still encoding
		if (working) {
			return void;
		}
		
		try {
			working = true;
			
			// Webcam to bitmap
			snapshot.draw(video);
			
			// Bitmap to bytes
			var rawBytes:ByteArray = snapshot.getPixels( snapshot.rect );
			rawBytes.position = 0; 
			encBytes = new ByteArray();
			
			jpeglib.encodeAsync(encodeComplete, rawBytes, encBytes, snapshot.width, snapshot.height, quality);

		} catch (e:Error) {
			// Don't block the next try if it didn't work
			working = false;
		}
		
	}
	
	private function encodeComplete(e:Event=null):void {
		// Encode to Base64 and send to JavaScript
		ExternalInterface.call("jpegData", Base64.encode(encBytes));
		
		// Allow next frame
		working = false;
	}
	
	
	public function exportInit(_w:int, _h:int):String {
		
		camera = Camera.getCamera();
		
		if( _w && _h) { 
			w = _w;
			h = _h;
		} else { 
			w = 160;
			h = 120;
		}
		
		camera.setMode( w, h, 24 )
		video = new Video( w, h );
		video.attachCamera( camera );
		
		snapshot = new BitmapData( w, h, false );
		
		pixels = new Array(w*h*4);
		
		this.addChild(video);
		video.x = 0;
		video.y = 0;
		
		return "setup "+w+"x"+h;
	}

	public function exportCameraList(input:String):String {
		//http://www.adobe.com/support/flash/action_scripts/actionscript_dictionary/actionscript_dictionary124.html

		var camListLength:int = Camera.names.length; 
		var strNames:String = "";
		for(var i:int=0;i<camListLength;i++) { 
			strNames+=Camera.names[i]+",";
		} 
		return strNames;

	}

}

}
