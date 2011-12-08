package {

import flash.display.BitmapData;
import flash.display.Sprite;
import flash.external.ExternalInterface;
import flash.media.Camera;
import flash.media.Video;
import flash.utils.ByteArray;

[SWF(backgroundColor=0x000000, frameRate=24, scaleMode=noscale)]
public class camcanvas extends Sprite{
	
	private var camera:Camera;
	private var video:Video;
	private var w:int;
	private var h:int;
	
	private var snapshot:BitmapData;
	private var pixels:Array;

	public function camcanvas():void {
		
		ExternalInterface.addCallback("ccInit", exportInit);
		ExternalInterface.addCallback("ccCapture", exportCapture);
		ExternalInterface.addCallback("ccList", exportCameraList);
		
	}

	public function exportCapture():void {
		snapshot.draw(video);
		
		// Thanks https://github.com/cameron314/PNGEncoder2
		ExternalInterface.call("bitmapData", Base64.encode(PNGEncoder2.encode(snapshot)));
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
