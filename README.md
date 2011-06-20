# An AS3 Library for ABC Manipulation

ActionScript Bytecode / Action Block Code is the bytecode format used by AVM+, aka Tamarin, aka AVM2, aka avmplus, part of Flash Player, Red Tamarin, and probably a number of other runtimes.  

## It's only natural…

…that there'd be an AS3 library to manipulate its compiled form.  In fact, there are at least 4-5 of these around the web, with various capabilities.  This one was started before some of them, but it probably wasn't the first.  It is, however, the only one that I've written.  Most of the original development was done in a semi-private Mercurial repository which is available on request.

## Overview

There are a few main points of functionality.  Of course, the abc.ABC class is probably at the center of this functionality.  The idea is that someone who's familiar with the ABC format can manipulate elements of a particular bytecode block at an abstract level, rather than pushing around bytes or worrying about constant pool indices.  Things like a MethodBodyInfo's stack and scope depths are calculated automatically any time that an ABC is written back into a ByteArray.

## Examples?

All of the files in the root directory are essentially examples, although I haven't committed my folder of test SWF files, since some of them are just randomly grabbed from the web as stress tests, and because it seems silly to keep them in a source repository.  

In general, though typical usage might look like this: 

```
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

## Thanks to…

senocular, for writing the SWFReader class upon which my SWFReader is _heavily_ based!  In fact, most of the code in that file is his, but I moved it into the "swf" package so I didn't have a stray com/senocular/utils folder with only one file.

http://www.senocular.com/flash/actionscript/?file=ActionScript_3.0/com/senocular/utils/SWFReader.as