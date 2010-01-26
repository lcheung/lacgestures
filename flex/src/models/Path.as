package models
{
	import mx.collections.ArrayCollection;
	
	public class Path
	{
		private var sections:ArrayCollection = new ArrayCollection();
		private var points:ArrayCollection = new ArrayCollection();
		
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

	}
}