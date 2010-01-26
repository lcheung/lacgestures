package core
{
	import models.Path;
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
		 	//TODO: Adjust weight contributing to error for each comparison
		 	
		 	var error:int = 0;
		 	//TODO: are their of the sections small enough to ignore?
		 	
		 	
		 	//look at direction, slopes, change in slopes, length
		 	
		 	
		 	//compare slopes at each defined interval 
		 	var baseSlopes:ArrayCollection = base.getSlopes();
		 	var reprodSlopes:ArrayCollection = reprod.getSlopes();
		 	
		 	for(var i:int = 0; i < baseSlopes.length; i++ ) {
		 		error += Math.abs(baseSlopes.getItemIndex(i) - reprodSlopes.getItemAt(i));
		 	}
		 	
		 	
		 	//TODO: This needs to be scaled relative to the entire size of each respective gesture
		 	//e.g. section width divided by total gesture width  
		 	error += Math.abs(base.getWidth() - reprod.getWidth());
		 	error += Math.abs(base.getHeight() - reprod.getHeight());
		 	
		 	
		 	
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
		private function parsePath(path:Path):ArrayCollection
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
			
			for each(var point:TouchPoint in path.getPoints()) {
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
					
					defineSectionSubslopes(path, section)
					
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
		
		//Calculate and store the slope at 20% intervals of the section
		private function defineSectionSubslopes(path:Path, section:Section):void
		{
			var slopes:ArrayCollection = new ArrayCollection();		
			
			var points = path.getPoints();
			var numPoints:int = section.getEndIndex() - section.getStartIndex();
			
			for(var i:int = 0; i < numPoints; i += numPoints/5) {
				var firstPoint:TouchPoint = points.getItemAt(i);
				var secondPoint:TouchPoint = points.getItemAt(i + numPoints/5);
				
				var rise:Number = secondPoint.getY() - firstPoints.getY();
				var run:Number = secondPoint.getX() - firstPoints.getX();
				
				if(run == 0) {
					run = 0.001;
				}
				
				var slope:Number = rise / run;  
				
				if(slopes.length < 5) {
					slopes.addItem(slope);
				}
			}  
			
			section.setSlopes(slopes);
		}
		
		
		 

	}
}