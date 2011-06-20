package {
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.utils.*;
	
	import abc.ABCInspector;
	import swf.*;
	import swf.tags.*;
	
	public class SWFTest extends Sprite {
		private var
			_urlL:URLLoader,
			_swfPath:String = 'Kode5.swf';
		
		public function SWFTest(){
			_loadSWF();
		}
		
		private function _loadSWF():void {
			_urlL = new URLLoader();
			_urlL.dataFormat = URLLoaderDataFormat.BINARY;
			_urlL.addEventListener(Event.COMPLETE, _onSWFLoad);
			_urlL.load(new URLRequest(_swfPath));
		}
		
		private function _onSWFLoad(e:Event):void {
			var swfData:ByteArray = (_urlL.data as ByteArray);
			var _swf:SWF = SWF.readFrom(swfData);
			trace('hmm!!');
			for each(var t:Tag in _swf.tags){
				if(t is DoABCTag){
					var abct:DoABCTag = t as DoABCTag;
					trace(new ABCInspector(abct.abc).inspect);
				}
			}
			
			// for now, return so that the 'inspect' output is last
			//return
			
			var swfBytes:ByteArray = _swf.toByteArray();
			trace('Loadbytes');
			SWF.readFrom(swfBytes);
			
			var l:Loader = new Loader();
			l.addEventListener(Event.COMPLETE, onNewSWF);
			
			function onNewSWF(e:Event):void {
				trace(l.content);
			}
			
			//(addChild(l) as Loader).loadBytes(swfBytes);
			
			
			var s:String = '';
			swfData.position = 0;
			swfData.endian = Endian.LITTLE_ENDIAN;
			for(var i:int = 0; i < swfData.length; i++){
				if(swfData.position >= swfData.length) break;
				var num:String = swfData.readUnsignedByte().toString(16);
				if(num.length == 1) num = '0' + num;
				s += num;
				if(i % 4 == 3) s += ' ';
				if(i % 32 == 31) s += '\n';
			}
			trace(s);
			
			s = '';
			swfBytes.position = 0;
			for(i = 0; i < swfBytes.length; i++){
				if(swfBytes.position >= swfBytes.length) break;
				num = swfBytes.readUnsignedByte().toString(16);
				if(num.length == 1) num = '0' + num;
				s += num;
				if(i % 4 == 3) s += ' ';
				if(i % 32 == 31) s += '\n';
			}
			trace(s);
		}
	}
}