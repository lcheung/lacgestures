package models
{
	public class TouchPoint
	{
		private var x:int = 0;
		private var y:int = 0;
		private var timestamp:int = 0;
		private var slope:Number = 0;
		
		public function TouchPoint():void
		{
		}
		
		public function setX(x:int):void
		{
			this.x = x;
		}
		
		public function getX():int
		{
			return this.x;
		}
		
		public function setY(y:int):void
		{
			this.y = y;
		}
		
		public function getY():int
		{
			return this.y;
		}

		public function setTimestamp(ts:int):void
		{
			this.timestamp = ts;
		}
		
		public function getTimestamp():int
		{
			return this.timestamp;
		}
		
		public function setSlope(s:Number):void
		{
			this.slope = s;
		}
		
		public function getSlope():Number
		{
			return this.slope;
		}
	}
}