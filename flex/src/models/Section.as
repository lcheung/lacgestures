package models
{
	import mx.automation.codec.ArrayPropertyCodec;
	import mx.collections.ArrayCollection;
		
	public class Section
	{
		private var startIndex:int = 0;
		private var endIndex:int = 0;
		private var direction:int = 0;
		private var width:Number = 0;
		private var height:Number = 0;
		private var slopes:ArrayCollection = new ArrayCollection();
			
		public function Section()
		{
			
		}
		
		public function setStartIndex(start:int):void
		{
			this.startIndex = start;
		}
		
		public function getStartIndex():int
		{
			return this.startIndex;
		}
		
		public function setEndIndex(end:int):void
		{
			this.endIndex = end;
		}
		
		public function getEndIndex():int
		{
			return this.endIndex;
		}

		public function setDirection(dir:int):void
		{
			this.direction = dir;
		}
		
		public function getDirection():int
		{
			return this.direction;
		}
		
		public function setWidth(x:Number):void
		{
			this.width = x;
		}
		
		public function getWidth():Number
		{
			return this.width;
		}
		
		public function setHeight(y:Number):void
		{
			this.height = y;
		}
		
		public function getHeight():Number
		{
			return this.height;
		}
		
		public function setSlopes(s:ArrayCollection):void
		{
			this.slopes = s;
		}
		
		public function getSlopes():ArrayCollection
		{
			return this.slopes;
		}
	}
}