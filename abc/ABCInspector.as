package abc {
	import abc.traits.*

	/**
	 * Pretty prints ABC blocks.  Eventually this output should be similar to that of abcdump in Tamarin.
	 */
	public class ABCInspector {
		public var _abc:ABC
		
		private var s:String
		
		public function ABCInspector(abc:ABC){
			this._abc = abc
		}
		
		public function get inspect():String {
			s = ''
			line(_abc.toString())
			line('ints(' + _abc.int_pool.length + '): {\n\t' + _abc.int_pool.join('\n\t') + '\n}')
			line('uints(' + _abc.uint_pool.length + '): {\n\t' + _abc.uint_pool.join('\n\t') + '\n}')
			line('doubles(' + _abc.double_pool.length + '): {\n\t' + _abc.double_pool.join('\n\t') + '\n}')
			line('Strings(' + _abc.string_pool.length + '): {\n\t"' + _abc.string_pool.join('"\n\t"') + '"\n}')
			line()
			
			if(_abc.script_info_pool.length > 0){
				line('Scripts', _abc.script_info_pool.length, ':')
				line(_abc.script_info_pool[_abc.script_info_pool.length - 1])
			}
			
			line('Classes: ', _abc.class_info_pool)
			
			for each(var ii:InstanceInfo in _abc.instance_info_pool){
				str('public class ' + ii.name)
				if(ii.super_name) str(' extends ' + ii.super_name) // this might not actually be a simple null check (ie, Object is default)
				
				// TODO: interfaces, 'implements'
				
				line(' {')
				
				// class body
				
				// constructor
				str('public function ' + ii.name + '(')
				if(ii.iinit.paramTypes.length > 0){
					for each(pType in ii.iinit.paramTypes){
						str(pType + ', ')
					}
				}
				line('){')
				if(ii.iinit.body){
					body = ii.iinit.body
					for each(instr in body.code) line(instr)
				}
				line('\n}')
				
				// methods
				for each(var t:Trait in ii.traits){
					switch(t.type){
						case Trait.Method:
							var mt:MethodTrait = t as MethodTrait
							str(mt.name.ns.name + ' function ' + mt.name.name + '(')
							
							// params
							if(mt.method.paramTypes.length > 0){
								for each(var pType:Multiname in mt.method.paramTypes){
									str(pType + ', ')
								}
							}
							
							str('):')
							str(mt.method.returnType)
							line(' {')
							
							// method body
							if(mt.method.body){
								var body:MethodBodyInfo = mt.method.body
								for each(var instr:Instruction in body.code){
									line(instr)
								}
							}
							
							line('}')
					}
				}
				
				line('\n}\n')
			}
			
			line('InstanceInfos: ', _abc.instance_info_pool)
			
			return s
		}
		
		public function str(...args):void {
			for(var i:int = 0; i < args.length; i++){
				s += args[i]
				if(i < args.length - 1) s += '\t'
			}
		}
		
		public function line(...args):void {
			for(var i:int = 0; i < args.length; i++){
				s += args[i]
				if(i < args.length - 1) s += '\t'
			}
			s += '\n'
		}
		
		public function lines(...args):void {
			s += args.join('\n')
		}
	}
}