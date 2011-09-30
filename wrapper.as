package {
	import flash.display.*
	// private var classes:Array = [Sprite, MovieClip];
	public function wrapper(c:Class):Class {
		if(c == Sprite) return MovieClip
		return c
	}
}