package models
{	
	public class Section
	{
		private var startIndex:int = 0;
		private var endIndex:int = 0;
		private var direction:int = 0;
			
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
	}
}