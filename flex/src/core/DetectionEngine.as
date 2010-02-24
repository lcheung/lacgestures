package core
{
	import models.Gesture;
	import models.Path;
	import models.Section;
	import models.TouchPoint;
	
	import mx.collections.ArrayCollection;
	
	//an enum for defining path direction
	public final class Direction {
		public static const UP_LEFT:int = 1;
		public static const UP_RIGHT:int = 2;
		public static const DOWN_LEFT:int = 3;
		public static const DOWN_RIGHT:int = 4;
	}
	
	public static class DetectionEngine
	{
		//values used for configuring comparison
		public static const ERROR_THRESHOLD = 1000;
		public static const SLOPE_WEIGHT = 1;
		public static const SCALE_WEIGHT = 1;
		
		
		/* Comparison
		 * The functions related to comparing a reproduced gesture
		 * to a collection of base gestures
		 */
		 
		 //Attempts to match a given gesture with those existing in the repository
		 public static function matchGesture(var reprod:Gesture):Gesture
		 {
		 	var minError:int = 0;
		 	var closestGesture:Gesture = null;
		 	//get list of existing gestures
		 	var storedGestures:ArrayCollection = new ArrayCollection();
		 	
		 	var reprodPaths:ArrayCollection = reprod.getPaths();
		 	var numPaths = reprodPaths.length
		 	
		 	//prepare each path in the reproduced gesture by removing unnecessary points and parsing into sections
		 	for each(var path:Path in reprodPaths) {
		 		preparePath(path);
		 	}
		 	
		 	//remove any gestures that don't have the same number of points
		 	for each(var baseGesture:Gesture in storedGestures) {
		 		if(baseGesture.getPaths().length != numPaths) {
		 			//TODO: Remove these gestures from ones being compared
		 		}
		 	}
		 	
		 	//create a 1-to-1 mapping of the base and reproduced gesture paths
		 	//correlatePaths();
		 	
		 	for each(var gesture:Gesture in storedGestures) {
		 		var gestureError:int = 0;
		 		
		 		//TODO: In the future, match the paths to be compared based on outcome from correlatePaths()
		 		for(var i:int = 0; i < numPaths; i++) {
			 		gestureError += comparePaths(reprodPaths.getItemAt(i), gesture.getPaths().getItemAt(i));
			 	}
			 	
			 	if(gestureError < minError || closestGesture == null) {
			 		minError = gestureError;
			 		closestGesture = gesture;
			 	}
			 	
		 	}
		 	
		 	//is the most similar gesture close enough to the reproduced?
		 	if(minError < DetectionEngine.ERROR_THRESHOLD) {
		 		return closestGesture;
		 	}
		 	
		 	//no gestures found
		 	return null;
		 	
		 }
		 
		 //Compare the reproduced path to a collection of base pathes
		 private static function comparePaths(var reprod:Path, var base:Path):int
		 {
		 	var error:int = 0;
		 	
		 	var reprodSections:ArrayCollection = reprod.getSections();
		 	var baseSections:ArrayCollection = base.getSections();
		 	
		 	var numReprodSections:int = reprodSections.length;
		 	 
		 	//iterate through each section
		 	for(var i:int = 0; i < numReprodSections; i++) {
		 		error += compareSection(reprodSections.getItemAt(i), baseSections.getItemAt(i));
		 	}
		 	
		 	return error;
		 } 
		 
		 //Compare two sections
		 private static function compareSection(reprod:Section, base:Section):int
		 {
		 	//TODO: Adjust weight contributing to error for each comparison
		 	//TODO: are their of the sections small enough to ignore?
		 	
		 	var error:int = 0;
		 	 
		 	/* look at direction, slopes, change in slopes, length
		 	 */
		 	
		 	//compare slopes at each defined interval 
		 	var baseSlopes:ArrayCollection = base.getSlopes();
		 	var reprodSlopes:ArrayCollection = reprod.getSlopes();
		 	
		 	for(var i:int = 0; i < baseSlopes.length; i++ ) {
		 		error += Math.abs(baseSlopes.getItemIndex(i) - reprodSlopes.getItemAt(i)) * DetectionEngine.SLOPE_WEIGHT;
		 	}
		 	
		 	
		 	//TODO: This needs to be scaled relative to the entire size of each respective gesture
		 	//e.g. section width divided by total gesture width  
		 	error += Math.abs(base.getWidth() - reprod.getWidth()) * DetectionEngine.SCALE_WEIGHT;
		 	error += Math.abs(base.getHeight() - reprod.getHeight()) * DetectionEngine.SCALE_WEIGHT;
		 	
		 	return error;
		 }
		
		/* Analysis Preparation
		 * The functions related to determining path characteristics
		 * in preparation for comparison 
		 */
		
		//Categorize the points by their path
		private static function sortPointsByPath():void
		{
			
		}
		   
		
		//Perform analysis on path
		//i.e. parse into section, determine direction, slope, etc.
		public static function preparePath(path:Path):void
		{
			smoothPath();
			parsePath();
			//determinePathScale();
		}
		
		//Remove anomalies from the path
		//i.e. remove points that are inconsistent with common trend
		private static function smoothPath()
		{
			
		}

		//Split a single blob path into sections based on direction		
		private static function parsePath(path:Path):void
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
			
			path.setSections(sections);
		}
		
		//Determine the size of the path
		//i.e. the max X & Y deltas 
		private static function determineSectionScale(points:ArrayCollection, section:Section)
		{
			var firstPoint:TouchPoint = points.getItemAt(0);
			
			var maxX:int = firstPoint.getX();
			var minX:int = firstPoint.getX();
			var maxY:int = firstPoint.getY();
			var minY:int = firstPoint.getY();
						
			for each(var point:TouchPoint in points) {
				if(point.getX() < minX) {
					minX = point.getX()
				} else if(point.getX() > maxX) {
					maxX = point.getX();
				}
				
				if(point.getY() < minY) {
					minX = point.getY()
				} else if(point.getY() > maxY) {
					maxY = point.getY();
				}
			}
			
			section.setWidth(maxX - minX);
			section.setHeight(maxY - minY); 
		}
		
		//Calculate and store the slope at 20% intervals of the section
		private static function defineSectionSubslopes(path:Path, section:Section):void
		{
			var slopes:ArrayCollection = new ArrayCollection();		
			
			var points = path.getPoints();
			var numPoints:int = section.getEndIndex() - section.getStartIndex();
			
			for(var i:int = 0; i < numPoints; i += numPoints/5) {
				var firstPoint:TouchPoint = points.getItemAt(i);
				var secondPoint:TouchPoint = points.getItemAt(i + numPoints/5);
				
				var rise:Number = secondPoint.getY() - firstPoints.getY();
				var run:Number = secondPoint.getX() - firstPoints.getX();
				
				//prevent divide by zero error
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
		
		//Pair up the paths on the reproduced gesture with those of the base gestures
		private static function correlatePaths(var reprod:Gesture, var baseCollection:ArrayCollection)
		{
			//TODO: Don't just take any path at random to set as origin, use left-most (for example), instead
			
			/* pick the starting coordinates of any path and use the relative X/Y variation
			 * of the start coords of the other paths to match
			 */
			 
			
			//first find the relative positions for the reproduced gesture
			var reprodPaths:ArrayCollection = reprod.getPaths();
			
			//stores the list of relative X/Y distances from origin point
			var reprodX:Array = new Array();
			var reprodY:Array = new Array();
			
			var reprodOriginX:int = reprodPaths.getPoints().getItemAt(0).getX();
			var reprodOriginY:int = reprodPaths.getPoints().getItemAt(0).getY();
			
			for each(var path:Path in reprodPaths) {
				reprodX.push(path.getPoints().getItemAt(0).getX() - reprodOriginX);
				reprodY.push(path.getPoints().getItemAt(0).getY() - reprodOriginY);
			}
			
			//now do this for all the base gestures
			for each(var gesture:Gesture in baseCollection) {
				var paths = gesture.getPaths();
				
				//stores the list of relative X/Y distances from origin point
				var baseX:Array = new Array();
				var baseY:Array = new Array();
				
				var baseOriginX:int = paths.getPoints().getItemAt(0).getX();
				var baseOriginY:int = paths.getPoints().getItemAt(0).getY();
				
				for each(var path:Path in paths) {
					baseX.push(path.getPoints().getItemAt(0).getX() - baseOriginX);
					baseY.push(path.getPoints().getItemAt(0).getY() - baseOriginY);
				}
				
				//TODO: compare the relative distances between reproduced and base paths
				
					
			}
			
			
			
		}
		 

	}
}