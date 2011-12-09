package {

// Thanks http://www.websector.de/blog/2009/06/21/speed-up-jpeg-encoding-using-alchemy/
import cmodule.as3_jpeg_wrapper.CLibInit;

import flash.display.BitmapData;
import flash.display.Sprite;
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
	private var quality:int = 75;
	
	private var snapshot:BitmapData;
	private var pixels:Array;
	
	private static var as3_jpeg_wrapper:Object;

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
		stage.align = StageAlign.TOP;
		
		// load Jpeg encoder module
		var loader:CLibInit = new CLibInit;
		as3_jpeg_wrapper = loader.init();

	}



	public function exportCapture():void {
		snapshot.draw(video);
		
		// Thanks https://github.com/cameron314/PNGEncoder2
		// ExternalInterface.call("bitmapData", Base64.encode(PNGEncoder2.encode(snapshot)));
		
		// Encode to JPEG
		var rawBytes:ByteArray = snapshot.getPixels( snapshot.rect );
		var encBytes:ByteArray = as3_jpeg_wrapper.write_jpeg_file(rawBytes, snapshot.width, snapshot.height, 3, 2, quality);
		
		// Encode to Base64 and send to HTML
		ExternalInterface.call("jpegData", Base64.encode(encBytes)); 
		
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
