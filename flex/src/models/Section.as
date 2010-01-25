package models
{	
	public class Section
	{
		private var startIndex:int = 0;
		private var endIndex:int = 0;
		private var direction:int = 0;
		private var width:int = 0;
		private var height:int = 0;
			
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
		
		public function setWidth(x:int):void
		{
			this.width = x;
		}
		
		public function getWidth():int
		{
			return this.width;
		}
		
		public function setHeight(y:int):void
		{
			this.height = y;
		}
		
		public function getHeight():int
		{
			return this.height;
		}
	}
}