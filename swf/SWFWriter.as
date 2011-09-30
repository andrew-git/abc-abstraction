package swf {
	import flash.utils.*
	import abc.*
	import swf.tags.*
	
	public class SWFWriter {
		private const TAG_HEADER_ID_BITS:int	= 6
		private const TAG_HEADER_MAX_SHORT:int	= 0x3F		
		
		private var _swf:SWF
		private var _bytes:ByteArray = new ByteArray
		
		public function SWFWriter(swf:SWF){
			if(!swf) throw new ArgumentError('`swf` cannot reasonably be null.', 1009) 
			_bytes.endian = Endian.LITTLE_ENDIAN
			_swf = swf
		}
		
		public static function write(swf:SWF):ByteArray {
			return new SWFWriter(swf).toByteArray()
		}
		
		public function toByteArray():ByteArray {
			_write()
			return _bytes
		}
		
		private function _write():void {
			_writeHeader()
			var compressedBytes:ByteArray = new ByteArray
			compressedBytes.endian = Endian.BIG_ENDIAN
			ByteUtils.writeRect(compressedBytes, _swf.frameSize)
			compressedBytes.writeShort(_swf.frameRate) // FIXME: SWFReader only reads a single byte, but the spec says it's a U16
			compressedBytes.writeShort(_swf.frameCount)
			
			var tagBytes:ByteArray = _writeTags()
			compressedBytes.writeBytes(tagBytes)
			if(_swf.compressed){
				trace('is compressed')
				// ZLIB compress the bytes past the header
				compressedBytes.compress()
			}
			_bytes.writeBytes(compressedBytes) // todo: check 2nd arg accuracy
			
			// go back and write the real file length
			_bytes.position = 4
			_bytes.writeUnsignedInt(_bytes.length)
			_bytes.position = _bytes.length
		}
		
		private function _writeHeader():void {
			// signature FWS or CWS
			_bytes.writeByte(_swf.compressed ? 0x43 : 0x46)
			_bytes.writeByte(0x57)
			_bytes.writeByte(0x53)
			
			_bytes.writeByte(_swf.version)
			_bytes.writeUnsignedInt(0) // FileLength is unknown at this point, it'll be filled in later
		}
		
		private function _writeTags():ByteArray {
			var bytes:ByteArray = new ByteArray
			bytes.endian = Endian.LITTLE_ENDIAN
			var tags:Vector.<Tag> = _swf.tags
			var len:int = tags.length
			for(var i:int = 0; i < len; i++){
				var t:Tag = tags[i]
				var tagBytes:ByteArray = t.toByteArray()
				
				var tagHeader:uint = t.code << TAG_HEADER_ID_BITS
				var tagLen:uint = tagBytes.length
				if(tagLen >= TAG_HEADER_MAX_SHORT){
					tagHeader |= TAG_HEADER_MAX_SHORT
					bytes.writeShort(tagHeader)
					bytes.writeUnsignedInt(tagLen)
				} else {
					tagHeader |= tagLen
					bytes.writeShort(tagHeader)
				}
				
				bytes.writeBytes(tagBytes)
			} 
			return bytes
		}
	}
}