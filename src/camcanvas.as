import flash.external.ExternalInterface;
import flash.display.BitmapData;
import flash.geom.Matrix;

class camcanvas {

	public static function exportCapture(input:String):String {
		snap();
		return input;
	}
	public static function exportInit(input:String):String {
		return "  " ;
	}

	public static function exportCameraList(input:String):String {
		//http://www.adobe.com/support/flash/action_scripts/actionscript_dictionary/actionscript_dictionary124.html

		var camListLength = Camera.names.length; 
		var strNames = "";
		for(var i=0;i<camListLength;i++) { 
			strNames+=Camera.names[i]+",";
		} 
		return strNames;

	}

	
	public static function main() {		

		_root.cam = Camera.get();
		_root.cam.setMode(320,240, 24)
		_root.attachMovie("ObjetVideo", "webcamVideo", 1);
		_root.webcamVideo.attachVideo(_root.cam);
		_root.webcamVideo._x = 0;

		_root.refFunc = exportCapture;
		_root.refFunc2 = exportCameraList;
		_root.refFunc3 = exportInit;

		ExternalInterface.addCallback("ccCapture", _root, _root.refFunc);
		ExternalInterface.addCallback("ccCameraList", _root, _root.refFunc2);
		ExternalInterface.addCallback("ccInit", _root, _root.refFunc3);

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
