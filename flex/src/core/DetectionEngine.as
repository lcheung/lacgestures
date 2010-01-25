package core
{
	import models.Section;
	
	import mx.collections.ArrayCollection;
	
	//an enum for defining path direction
	public final class Direction {
		public static const UP_LEFT:int = 1;
		public static const UP_RIGHT:int = 2;
		public static const DOWN_LEFT:int = 3;
		public static const DOWN_RIGHT:int = 4;
	}
	
	public class DetectionEngine
	{
		public function DetectionEngine()
		{
		}
		
		
		/* Comparison
		 * The functions related to comparing a reproduced gesture
		 * to a collection of base gestures
		 */
		 
		 //Compare the reproduced path to a collection of base pathes
		 public function comparePathes()
		 {
		 	//iterate through each section
		 	compareSection();
		 } 
		 
		 //Compare two sections
		 private function compareSection(base:Section, reprod:Section):int
		 {
		 	//look at direction, slopes, change in slopes, length
		 	
		 	
		 	//return integer representing error
		 }
		
		/* Analysis Preparation
		 * The functions related to determining path characteristics
		 * in preparation for comparison 
		 */
		
		//Categorize the points by their path
		private function sortPointsByPath():void
		{
			
		}
		   
		
		//Perform analysis on path
		//i.e. parse into section, determine direction, slope, etc.
		public function preparePath()
		{
			smoothPath();
			parsePath();
			determinePathScale();
		}
		
		//Remove anomalies from the path
		//i.e. remove points that are inconsistent with common trend
		private function smoothPath()
		{
			
		}

		//Split a single blob path into sections based on direction		
		private function parsePath(points:ArrayCollection):ArrayCollection
		{
			//collection all the sections in this particular path
			var sections:ArrayCollection = new ArrayCollection(); 
			
			//the index of the first point in that section
			var sectionStartIndex = 0;
			
			//a counter that indicates the current index of the point
			//for the overall path
			var currentPointIndex = 0;
			
			//these variables are used for tracking the most recent known state
			//in the iteration of points
			var previousPoint:TouchPoint = null;
			var previousDirection:int = 0;
			
			for each(var point:TouchPoint in points) {
				var currentDirection:int = 0;
				
				/* first define the direction from the previous point to current
				 */
				
				//temporary stores the change in X & Y directions from previous point to current
				//-1 = movement down/left
				//1 = movement up/right
				var deltaX = 1;
				var deltaY = 1;
				
				if(currentPointIndex != 0) {
					if(point.getX() < previousPoint.getX()) {
						deltaX = -1;
					}
					
					if(point.getY() < previousPoint.getY()) {
						deltaY = -1;
					}
				}
				
				if(deltaX < 0 && deltaY < 0) {
					currentDirection = Direction.DOWN_LEFT;
				} else if(deltaX < 0 && deltaY > 0) {
					currentDirection = Direction.UP_LEFT;
				} else if(deltaX > 0 && deltaY < 0) {
					currentDirection = Direction.DOWN_RIGHT;
				} else {
					currentDirection = Direction.UP_RIGHT;
				}
				
				/* now compare it to the direction of this section
				 * if it varies, start new section 
				 */
				if(currentDirection != previousDirection) {
					var section:Section = new Section();
					
					section.setStartIndex(sectionStartIndex);
					section.setEndIndex(currentPointIndex - 1);
					section.setDirection(previousDirection);
					
					
					sections.addItem(section);
					
					//set the start index for the next section
					sectionStartIndex = currentPointIndex;
				}
				
				
				previousPoint = point;
				previousDirection = currentDirection;
				currentPointIndex++;
			}
			
			return sections;
		}
		
		//Determine the size of the path
		//i.e. the max X & Y deltas 
		private function determinePathScale()
		{
			//accept a single path (collection of coords)
			
			//compute the difference between max & min values for X&Y direction
			
			//return X&Y distance 
		}
		
		
		 

	}
}