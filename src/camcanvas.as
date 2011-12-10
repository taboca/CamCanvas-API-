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
import flash.utils.setTimeout;

[SWF(backgroundColor=0x000000, frameRate=30)]
public class camcanvas extends Sprite{
	
	private var camera:Camera;
	private var video:Video;
	private var w:int = 160;
	private var h:int = 120;
	private var quality:int = 75;
	
	private var snapshot:BitmapData;
	private var pixels:Array;
	
	private var jpeglib:Object;
	private var encBytes:ByteArray;
	private var working:Boolean = false;
	
	public function camcanvas():void {
		
		ExternalInterface.addCallback("ccInit", exportInit);
		ExternalInterface.addCallback("ccCapture", exportCapture);
		ExternalInterface.addCallback("ccList", exportCameraList);
		ExternalInterface.addCallback("ccQuality", exportQuality);
		
		if(stage) init();
		else addEventListener(Event.ADDED_TO_STAGE, init);
		
	}
	
	private function init(e:Event=null):void {
		removeEventListener(Event.ADDED_TO_STAGE, init);
		
		// Init stage
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		
		// load, wrap Jpeg encoder
		var jpeginit:CLibInit = new CLibInit(); // get library
		jpeglib = jpeginit.init(); // initialize library exported class to an object

	}

	public function exportCapture():void {
		// working was for async
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
			
			// Bitmap bytes to JPG bytes
			encBytes = new ByteArray();
			jpeglib.encode(rawBytes, encBytes, snapshot.width, snapshot.height, quality)
			
			// JPG bytes to Base64 to JavaScript
			ExternalInterface.call("jpegData", Base64.encode(encBytes));
			
			working = false;
			
		} catch (e:Error) {
			// Don't block the next try if it didn't work
			working = false;
		}
	}
		
	public function exportQuality(_q:int):void {
		if (0 <= _q && _q <= 100) {
			quality = _q;
		}
	}
	
	public function exportInit(_w:int=0, _h:int=0):void {
		var success:Boolean = false;
		var status:String = "";
		if( _w>0 && _h>0) { 
			w = _w;
			h = _h;
		}

		try {
			camera = Camera.getCamera();
						
			camera.setMode( w, h, 24 )
			video = new Video( w, h );
			video.attachCamera( camera );
			this.addChild(video);
			video.x = 0;
			video.y = 0;
			
			snapshot = new BitmapData( w, h, false );
			
			status = "setup "+w+"x"+h;
			success = true;
			
		} catch (e:Error) {
			status = "setup failed, try again";
		}
		
		var e:Object = {success: success, status: status};
		ExternalInterface.call("cameraSetup", e);
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
