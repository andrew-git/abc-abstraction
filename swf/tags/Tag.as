package swf.tags {
	import swf.SWFReader
	
	import flash.utils.*

	public class Tag {
		public var 
			code	:uint,
			bytes	:ByteArray
		
		public function Tag(code:uint){
			this.code = code
		}
		
		public static function fromCode(code:uint):Tag {
			var tag:Tag
			switch(code){
				case End:
					tag = new EndTag
					break
				case FileAttributes:
					tag = new FileAttributesTag
					break
				case Metadata:
					tag = new MetadataTag
					break
				case DoABC:
					tag = new DoABCTag
					break
				case ScriptLimits:
					tag = new ScriptLimitsTag
					break
				case DefineBinaryData:
					tag = new DefineBinaryDataTag
					break
				default:
					tag = new Tag(code)
			}
			return tag // until implemented
		}
		
		public function readFrom(reader:SWFReader, length:uint):void {
			bytes = new ByteArray
			reader.bytes.readBytes(bytes, 0, length)
		}
		
		/**
		 * Tags shouldn't supply their own tag header.  SWFWriter writes those.
		 */
		public function toByteArray():ByteArray {
			return bytes
		}
		
		public static const
			End					:uint = 0,
			SetBackgroundColor	:uint = 9,
			Protect				:uint = 24,
			EnableDebugger		:uint = 58,
			EnableDebugger2		:uint = 64,
			ScriptLimits		:uint = 65,
			FileAttributes		:uint = 69,
			Metadata			:uint = 77,
			DefineShape			:uint = 2,
			DefineShape2		:uint = 22,
			DefineShape3		:uint = 32,
			DefineShape4		:uint = 83,
			DoABC				:uint = 82,
			DefineBinaryData	:uint = 87
	}
}