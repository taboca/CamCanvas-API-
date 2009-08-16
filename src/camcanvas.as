import flash.external.ExternalInterface;
import flash.display.BitmapData;
import flash.geom.Matrix;

class camcanvas {

	public static function exportCapture(input:String):String {
		snap();
		return input;
	}
	
	public static function main() {		

		var cam = Camera.get();
		cam.setMode(320,240, 24)
		_root.attachMovie("ObjetVideo", "webcamVideo", 1);
		_root.webcamVideo.attachVideo(cam);
		_root.webcamVideo._x = 0;

		_root.refFunc = exportCapture;
		ExternalInterface.addCallback("ccCapture", _root, _root.refFunc);

	}
	
	public static function snap() {

		var snapshot:flash.display.BitmapData = new flash.display.BitmapData(_root.webcamVideo._width,_root.webcamVideo.height,true);
		snapshot.draw(_root.webcamVideo);
		var string="";
		for(var j=0;j<240;j++) { 
			var currLine = "";
			for(var i=0;i<320;i++) { 
				currLine +=  snapshot.getPixel(i,j)+"-";				
			}
			ExternalInterface.call("passLine", currLine)
		} 
	}
}
