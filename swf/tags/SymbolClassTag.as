package swf.tags {
	import swf.*
	import abc.*
	
	import flash.utils.*
	
	public class SymbolClassTag extends ControlTag {
		public var 
			tags:Vector.<uint>,
			names:Vector.<String>
		
		public function SymbolClassTag(){
			super(Tag.SymbolClass)
			tags = new <uint>[]
			names = new <String>[]
		}
		
		override public function readFrom(reader:SWFReader, length:uint):void {
			var len:uint = reader.bytes.readUnsignedShort()
			trace('slen', len)
			for(var i:int = 0; i < len; i++){
				tags[i] = reader.bytes.readUnsignedShort()
				names[i] = reader.readString()
				trace('reading syms', tags[i], names[i])
			}
		}
		
		override public function toByteArray():ByteArray {
			var bytes:ByteArray = new ByteArray
			
			ByteUtils.writeU16(bytes, tags.length)
			
			for(var i:int = 0; i < tags.length; i++){
				trace('writing syms', tags[i], names[i])
				ByteUtils.writeU16(bytes, tags[i])
				bytes.writeUTFBytes(names[i])
				bytes.writeByte(0)
			}
			
			return bytes
		}
	}
}