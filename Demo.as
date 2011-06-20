package {
	import swf.SWFReader;
	
	import flash.display.*;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.net.*;
	import flash.utils.ByteArray;
	
	import abc.*;
	import abc.traits.*;
	
	public class Demo extends Sprite {
		public static var CONTENT_READY:String = 'contentReady';
		
		private var _urll:URLLoader;
		private var _libLoader:URLLoader;
		private var _lib:ByteArray;
		private var _libABC:ABC;
		
		public var content:Sprite;
		
		private var _proxySWFPath:String = "Hold_proxyURL.swf";
		private var _path:String = "UseExternalInterface.swf";
		
		public function Demo(path:String = null) {
			if(path) _path = path;
			
			//_loadLib();
			// ==> should be uncommented with the large block comment: _loadContent();
		}
		/*
		private function _loadLib():void {
			_libLoader = new URLLoader();
			_libLoader.dataFormat = URLLoaderDataFormat.BINARY;
			_libLoader.addEventListener(Event.COMPLETE, _onLibLoad);
			_libLoader.load(new URLRequest(_proxySWFPath));
		}
		
		private function _onLibLoad(e:Event):void {
			var libSWFBytes:ByteArray = (e.target as URLLoader).data as ByteArray;
			var libABC_r:ABCReader = new ABCReader(libSWFBytes, null);
			var libABC:ABC = libABC_r.abcs[0];
			var libABCBytes:ByteArray = libABC_r.abcBytes[0];
			_lib = libABCBytes;
			_libABC = libABC;
			
			_loadContent();
		}
		
		private function _loadContent():void {
			// then load the dynamically specified SWF
			_urll = new URLLoader();
			_urll.dataFormat = URLLoaderDataFormat.BINARY;
			_urll.addEventListener(Event.COMPLETE, _onComplete);
			_urll.load(new URLRequest(_path));
		}
		
		private function _onComplete(e:Event):void {
			var bytes:ByteArray = (e.target as URLLoader).data as ByteArray;
			var r:ABCReader = new ABCReader(bytes, modifyABC, null);
			trace('~~', r.output.length, bytes.length);
			var loadOutput:Loader = new Loader();
			addChild(loadOutput);
			loadOutput.contentLoaderInfo.addEventListener(Event.INIT, onOutputInit);
			loadOutput.contentLoaderInfo.addEventListener(Event.COMPLETE, onOutputLoad);
			loadOutput.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onOutputError);
			loadOutput.contentLoaderInfo.addEventListener(HTTPStatusEvent.HTTP_STATUS, onOutputError);
			
			loadOutput.loadBytes(r.output);

			trace(r);
			
			trace('-----------////////////////\\\\\\\\\\\\\\------------')
			var readModified:ABCReader = new ABCReader(r.output, function(abc:*):void {});
			trace('finished all of that');
			//for(var i:int = 0; i < r.abcs.length; i++){
			//	modifyABC(r.abcs[i]);
			//	var ba:ByteArray = ABCWriter.writeABC(r.abcs[i]);
			//	var r2:ABCReader = new ABCReader(ba, false);
			//}
		}
		*/
		private function onOutputInit(e:Event):void {
			trace('!! on output init');
		}
		
		private function onOutputLoad(e:Event):void {
			trace('!! output load success!: ', e.target.content);
			this.content = e.target.content;
			var e2:Event = new Event(CONTENT_READY);
			dispatchEvent(e2);
		}
		
		private function onOutputError(err:IOError):void {
			trace('!! terrible IO error: ', err);
		}
		
		private function addLibABC(dynABC:ABC):void {
			if(!_libABC) throw new Error('trying to add lib abc, but it is not defined');
			
			dynABC.string_pool.push.apply(dynABC.string_pool, _libABC.string_pool);
			dynABC.namespace_pool.push.apply(dynABC.namespace_pool, _libABC.namespace_pool);
			dynABC.ns_set_pool.push.apply(dynABC.ns_set_pool, _libABC.ns_set_pool);
			dynABC.multiname_pool.push.apply(dynABC.multiname_pool, _libABC.multiname_pool);
			dynABC.method_info_pool.push.apply(dynABC.method_info_pool, _libABC.method_info_pool);
			dynABC.instance_info_pool.push.apply(dynABC.instance_info_pool, _libABC.instance_info_pool);
			dynABC.class_info_pool.push.apply(dynABC.class_info_pool, _libABC.class_info_pool);
			dynABC.method_body_info_pool.push.apply(dynABC.method_body_info_pool, _libABC.method_body_info_pool);
			dynABC.script_info_pool.unshift.apply(dynABC.script_info_pool, _libABC.script_info_pool);
		}
		
		private function modifyABC($abc:ABC):void {
			for(var i:int = 0; i < $abc.method_body_info_pool.length; i++){
				var mbi:MethodBodyInfo = $abc.method_body_info_pool[i];
				search: for(var j:int = 0; j < mbi.code.length; j++){
					var instr:Instruction = mbi.code[j];
					if(instr.opcode == Op.findpropstrict){
						// then look for constructprop, insert proxyURL
						for(var k:int = j + 1; k < mbi.code.length; k++){
							var instr2:Instruction = mbi.code[k];
							if(instr2.opcode == Op.constructprop && !instr2.used){
								if(instr.operands[0] == instr2.operands[0] && (instr.operands[0] as Multiname).name == 'URLRequest'){
									instr2.used = true;
									trace('found pair: ', instr, instr2);
									trace('-- ', (instr.operands[0] as Multiname).name);
									
									// in abstract, do this: (order is intentionally backwards)
									// bytecode.splice(k, 0, '--callproperty	(public)::proxyURL, 1');
									var proxyURL:Multiname = new Multiname(Multiname.QName, ABCNamespace.public_ns, 'proxyURL');
									var call_instr:Instruction = new Instruction(Op.callproperty, [proxyURL, 1]);
									call_instr.used = true;
									mbi.code.splice(k, 0, call_instr);
									mbi.code_length += 3; // should find the size of the U30s
									mbi.max_stack += 1;
									
									// bytecode.splice(j + 1, 0, '--findpropstrict	(public)::proxyURL');
									var find_instr:Instruction = new Instruction(Op.findpropstrict, [proxyURL]);
									find_instr.used = true;
									mbi.code.splice(j + 1, 0, find_instr);
									mbi.code_length += 2;
									mbi.max_stack += 1;
									j++;
									continue search;
								}
							}
						}
					}
				}
				trace('((MethodBodyInfo stuff' + mbi.code_length + ', ' + mbi.max_stack);
			}
			
			//addLibABC(abc);
			
			var publicString:Multiname = new Multiname(Multiname.QName, new ABCNamespace(ABC.PackageNamespace, ''), 'String');
			var proxy_method:MethodInfo = new MethodInfo(1, publicString, [publicString], '', 0, [], []);
			var code:Array = [
				new Instruction(Op.getlocal0),
				new Instruction(Op.pushscope),
				new Instruction(Op.getlex, [new Multiname(Multiname.QName, new ABCNamespace(ABC.PackageNamespace, 'flash.external'), 'ExternalInterface')]),
				new Instruction(Op.pushstring, ['parent.FlashDOM.proxyURL']),
				new Instruction(Op.getlocal1),
				new Instruction(Op.callproperty, [new Multiname(Multiname.QName, ABCNamespace.public_ns, 'call'), 2]),
				new Instruction(Op.returnvalue)
			];
			var proxy_mbi:MethodBodyInfo = new MethodBodyInfo(proxy_method, 3, 3, 1, 2, 11, code, [], []);
			$abc.method_body_info_pool.push(proxy_mbi);
			$abc.method_info_pool.push(proxy_method);
			
			var do_nothing:MethodInfo = new MethodInfo(0, new Multiname(Multiname.QName, new ABCNamespace(ABC.PackageNamespace, ''), 'void'), [], '$init~', 0, [], []);
			var do_nothingCode:Array = [
				new Instruction(Op.getlocal0),
				new Instruction(Op.pushscope),
				new Instruction(Op.returnvoid)
			];
			var do_nothingMBI:MethodBodyInfo = new MethodBodyInfo(do_nothing, 1, 1, 1, 2, 3, do_nothingCode, [], []);
			var proxy_mtrait:MethodTrait = new MethodTrait(new Multiname(Multiname.QName, new ABCNamespace(ABC.PackageNamespace, ''), 'proxyURL'), Trait.Method);
			proxy_mtrait.fastInit(0, proxy_method);
			var proxy_si:ScriptInfo = new ScriptInfo(do_nothing, [proxy_mtrait]);
			$abc.script_info_pool.unshift(proxy_si);
			$abc.method_info_pool.push(do_nothing);
			$abc.method_body_info_pool.push(do_nothingMBI);
		}
	}
}