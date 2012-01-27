# An AS3 Library for ABC Manipulation

ActionScript bytecode is the bytecode format used by AVM+ aka Tamarin aka AVM2 aka avmplus, part of Flash Player, Red Tamarin, and probably a number of other runtimes.  

## It's only natural…

…that there'd be an AS3 library to manipulate its compiled form.  In fact, there are at least 4-5 of these around the web, with various capabilities.  This one was started before some of them, but it probably wasn't the first.  It is, however, the only one that I've written.  Most of the original development was done during the spring and summer of 2010 in a semi-private Mercurial repository which is available upon request.

## Overview

There are a few main points of functionality.  Of course, the abc.ABC class is probably at the center of this functionality.  The idea is that someone who's familiar with the ABC format can manipulate elements of a particular bytecode block at an abstract level, rather than pushing around bytes or worrying about constant pool indices.  Things like a MethodBodyInfo's stack and scope depths are calculated automatically any time that an ABC is written back into a ByteArray.

## Examples?

All of the files in the root directory are essentially examples, although I haven't committed my folder of test SWF files, since some of them are just randomly grabbed from the web as stress tests, and because it seems silly to keep them in a source repository.  

In general, though typical usage might look like this: 

```actionscript
var swfData:ByteArray = urlLoader.data as ByteArray // these are the bytes of an SWF
var _swf:SWF = SWF.readFrom(swfData)
for each(var t:Tag in _swf.tags){ // there might only be one DoABCTag per file, or tons of them!
	if(t is DoABCTag){
		var abct:DoABCTag = t as DoABCTag
		abct.abc // this is an ABC instance that you can change around
		
		// do stuff here
	}
}

var new_bytes:ByteArray = _swf.toByteArray()
(addChild(new Loader()) as Loader).loadBytes(new_bytes) // this loads the SWF with modified bytecode

```

## Bugs?

Probably.  In a straight read-in, write-out pass, it's unlikely that anything will break.  You're responsible for getting your code past the Flash Player verifier, because this library doesn't do any verification itself.  

Some things that are currently especially untested include the auto-calculated max_scope_depth, max_stack, and local_count fields of a MethodBodyInfo.  The good thing about this fragility is that you don't have to calculate these values yourself.  

## Thanks to…

senocular, for writing the SWFReader class upon which my SWFReader is _heavily_ based!  In fact, most of the code in that file is his, but I moved it into the "swf" package so I didn't have a stray com/senocular/utils folder with only one file.

http://www.senocular.com/flash/actionscript/?file=ActionScript_3.0/com/senocular/utils/SWFReader.as

## Longer Example:
### Fixing a loaded SWF's improper/early access to the stage

This example addresses the common problem that occurs when an SWF loads another SWF that wasn't 
programmed with this usage scenario in mind.  The crippling aspect of this frequent error is that 
the problem typically occurs in the constructor of the main class of the loaded SWF, often meaning 
that the entire application will fail to initialize.

The code below fixes the problem by swapping the constructor of the loaded SWF with an inserted 
method that calls the old constructor when it is ADDED_TO_STAGE. 

```actionscript
package {
	import abc.*
	import abc.traits.*
	import swf.*
	import swf.tags.*

	import flash.display.*
	import flash.events.*
	import flash.utils.*
	import flash.net.*

	public class AnyUse extends Sprite {
		public function AnyUse(){
			var urlL:URLLoader = new URLLoader
			urlL.addEventListener(Event.COMPLETE, onSWFBytesLoaded)
			urlL.dataFormat = URLLoaderDataFormat.BINARY
			urlL.load(new URLRequest('useStage.swf'))
		}
		
		public function onSWFBytesLoaded(e:Event):void {
			var bytes:ByteArray = e.target.data
			var $swf:SWF = SWF.readFrom(bytes)
			
			var docClass:String
			
			var doABCs:Vector.<DoABCTag> = new <DoABCTag>[]
			tags: for each(var t:Tag in $swf.tags){
				if(t is SymbolClassTag){
					var st:SymbolClassTag = t as SymbolClassTag
					for(var i:int = 0; i < st.tags.length; i++){
						if(st.tags[i] == 0){
							docClass = st.names[i]
							continue tags
						}
					}
				} else if(t is DoABCTag){
					doABCs.push(t as DoABCTag)
				}
			}
			
			for each(var doABC:DoABCTag in doABCs){
				var bc:ABC = doABC.abc
				for each(var ii:InstanceInfo in bc.instance_info_pool){
					var name:Multiname = ii.name
					if((name.ns.name == '' && name.name == docClass) || ((name.ns.name + '.' + name.name) == docClass)){
						modify(bc, ii)
					}
				}
			}
			
			var newBytes:ByteArray = $swf.toByteArray()
			newBytes.position = 0
			var l:Loader = new Loader
			l.loadBytes(newBytes)
			addChild(l)
		}
		
		private function modify(bc:ABC, ii:InstanceInfo):void {
			var mbi:MethodBodyInfo = makeConstructor(bc)
			var konstructor:MethodInfo = ii.iinit
			ii.iinit = mbi.method
			
			konstructor.paramCount = 1
			konstructor.paramTypes = [Multiname.Any]
			konstructor.name = 'konstructor'
			
			var mt:MethodTrait = new MethodTrait(new Multiname(Multiname.QName, ABCNamespace.public_ns, 'konstructor'), Trait.Method)
			mt.fastInit(0, konstructor)
			ii.traits.push(mt)
		}
		
		private function makeConstructor(bc:ABC):MethodBodyInfo {
			var mi:MethodInfo = new MethodInfo(0, Multiname.Any, [], 'constructor', 0)
			var addEvent:Multiname = new Multiname(Multiname.QName, ABCNamespace.public_ns, 'addEventListener')
			var konstructor:Multiname = new Multiname(Multiname.QName, ABCNamespace.public_ns, 'konstructor')
			var code:Array = [
				new Instruction(Op.getlocal0),
				new Instruction(Op.pushscope),
				new Instruction(Op.getlocal0),
				new Instruction(Op.constructsuper, [0]),
				new Instruction(Op.findpropstrict, [addEvent]),
				new Instruction(Op.pushstring, ['addedToStage']),
				new Instruction(Op.getlocal0),
				new Instruction(Op.getproperty, [konstructor]),
				new Instruction(Op.callpropvoid, [addEvent, 2]),
				new Instruction(Op.returnvoid)
			]
			
			var mbi:MethodBodyInfo = new MethodBodyInfo(mi, 3, 1, 9, 10, code.length, code, [], [])
			bc.method_body_info_pool.push(mbi)
			bc.method_info_pool.push(mi)	
			
			return mbi
		}
	}
}
```