package models
{
	import mx.collections.ArrayCollection;
	
	public class Path
	{
		private var sections:ArrayCollection = new ArrayCollection();
		private var points:ArrayCollection = new ArrayCollection();
		private var height:int = 0;
		private var width:int = 0;
		
		public function Path()
		{
		}
		
		public function getSections():ArrayCollection
		{
			return this.sections;
		}
		
		public function setSections(s:ArrayCollection):void
		{
			this.sections = s;
		}
		
		public function getPoints():ArrayCollection
		{
			return this.points;
		}
		
		public function setPoints(p:ArrayCollection):void
		{
			this.points = p;
		}
		
		public function getHeight():int
		{
			return this.height;
		}

		public function setHeight(h:int):void
		{
			this.height = h;
		}

		public function getWidth():int
		{
			return this.width;
		}

		public function setWidth(w:int):void
		{
			this.width = w;
		}
	}
}