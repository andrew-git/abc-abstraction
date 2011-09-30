package {
	import abc.*
	
	import flash.display.*
	import flash.events.*
	import flash.net.*
	import flash.utils.*
	
	import swf.*
	import swf.tags.*
	
	public class FlashFirebugTest extends Sprite {
		private static const
			instructions:Array = new Array
		
		private var
			initLoader:URLLoader = new URLLoader
		
		
		public function FlashFirebugTest(){
			_initConsts()
			
			initLoader.addEventListener(Event.COMPLETE, _onInitComplete)
			initLoader.dataFormat = URLLoaderDataFormat.BINARY
			initLoader.load(new URLRequest('Kode6.swf'))
		}
		
		private function _initConsts():void {
			instructions[Op.construct] = 1, instructions[Op.constructprop] = 1
		}
		
		private function _onInitComplete(e:Event):void {
			var bytes:ByteArray = (e.target as URLLoader).data
			var $swf:SWF = SWF.readFrom(bytes)
			trace('-------------------------~')
			trace($swf)
			
			trace(wrapper)

			_addWrapper($swf)
			_guardConstructors($swf)
			
			var new_bytes:ByteArray = $swf.toByteArray()
			trace('~~~~~~~~~~~ new swf')
			trace(SWF.readFrom(new_bytes))
			
			;(addChild(new Loader()) as Loader).loadBytes(new_bytes)
		}
		
		private function _addWrapper(s:SWF):void {
			var self:SWF = SWF.readFrom(loaderInfo.bytes)
			var code:ABC
			for each(var tag:Tag in self.tags){
				if(tag is DoABCTag && (tag as DoABCTag).name == 'FlashFirebugTest'){
					trace('abcname: ', (tag as DoABCTag).name)
					code = (tag as DoABCTag).abc
				}
			}
			
			for each(var m:MethodInfo in code.method_info_pool){
				trace(m.name, m)
				trace(m.returnType, m.paramTypes)
			}
			throw 'done'
		}
		
		private function _guardConstructors(s:SWF):void {
			var abcTags:Vector.<DoABCTag> = new Vector.<DoABCTag>
			for each(var tag:Tag in s.tags) if(tag is DoABCTag) abcTags.push(tag)
			
			for each(var abcTag:DoABCTag in abcTags){
				var code:ABC = abcTag.abc
				for each(var mbi:MethodBodyInfo in code.method_body_info_pool){
					_guardConstructInstructions(mbi)
				}
			}
		}
		
		private static const
			wrapper_name:Multiname = new Multiname(Multiname.QName, ABCNamespace.public_ns, 'wrapper'),
			find_func:Instruction = new Instruction(Op.findpropstrict, [wrapper_name]),
			call_func:Instruction = new Instruction(Op.callproperty, [wrapper_name, 1]),
			construct:Instruction = new Instruction(Op.construct, [0])
		
		private function _guardConstructInstructions(mbi:MethodBodyInfo):void {
			for(var i:int = 0; i < mbi.code.length; i++){
				var instr:Instruction = mbi.code[i]
				if(!instructions[instr.opcode]) continue
				
				if(instr.opcode == Op.constructprop){
					mbi.code.splice(i, 1, construct)
				}
				
				trace('adding wrapper by: ', mbi.method)
				mbi.code.splice(i, 0, find_func, call_func)
				
				i += 2
			}
		}
	}
}