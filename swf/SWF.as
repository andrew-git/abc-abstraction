package swf {
	
	import flash.geom.*;
	import flash.utils.ByteArray;
	
	import swf.tags.Tag;
	
	public class SWF {
		public var 
			compressed	:Boolean,
			version		:uint,
			frameSize	:Rectangle,
			frameRate	:uint,
			frameCount	:uint,
			tags		:Vector.<Tag>;
		
		public function SWF(){
			_initDefaults();
		}
		
		public static function readFrom(bytes:ByteArray):SWF {
			var reader:SWFReader = new SWFReader(bytes);
			trace('[SWF: ', reader.swf.compressed, reader.swf.version, reader.swf.frameSize, reader.swf.frameRate, ' fps ]');
			return reader.swf;
		}
		
		public function toByteArray():ByteArray {
			return new SWFWriter(this).toByteArray();
		}
		
		private function _initDefaults():void {
			// header
			compressed = false;
			version = 1;
			frameSize = new Rectangle();
			frameRate = 12;
			
			tags = new Vector.<Tag>();
		}
	}
}