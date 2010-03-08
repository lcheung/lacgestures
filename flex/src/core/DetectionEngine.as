package core
{
	import models.Direction;
	import models.Gesture;
	import models.Path;
	import models.Section;
	import models.TouchPoint;
	
	import mx.collections.ArrayCollection;
	
	
	public class DetectionEngine
	{
		//values used for configuring comparison
		public static const ERROR_THRESHOLD:int = 1000;
		public static const SLOPE_WEIGHT:int = 50;
		public static const SCALE_WEIGHT:int = 1;
		public static const SMALL_SECTION_SIZE:Number = 10; //the maximum size a section can be to be a candidate for being ignored
		
		
		/* Comparison
		 * The functions related to comparing a reproduced gesture
		 * to a collection of base gestures
		 */
		 
		 //Attempts to match a given gesture with those existing in the repository
		 public static function matchGesture(reprod:Gesture):Gesture
		 {
		 	var minError:int = 0;
		 	var closestGesture:Gesture = null;
		 	//get list of existing gestures
		 	var storedGestures:ArrayCollection = Gesture.getGesturesFromDB();
		 	
		 	//TODO: This is just temporary until all the proper info is stored in DB
		 	for each(var g:Gesture in storedGestures) {
		 		prepareGesture(g);
		 	}
		 	
		 	var reprodPaths:ArrayCollection = reprod.getPaths();
		 	var numPaths:int = reprodPaths.length;
		 	
		 	//prepare each path in the reproduced gesture by removing unnecessary points and parsing into sections
		 	prepareGesture(reprod);
		 	/*for each(var path:Path in reprodPaths) {
		 		preparePath(path);
		 	}*/
		 	
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
			 		gestureError += comparePaths(reprodPaths.getItemAt(i) as Path, gesture.getPaths().getItemAt(i) as Path);
			 	}
			 	
			 	//look at average error overall paths, not total error
			 	gestureError = gestureError / numPaths;
			 	
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
		 private static function comparePaths(reprod:Path, base:Path):int
		 {
		 	var error:int = 0;
		 	
		 	var reprodSections:ArrayCollection = reprod.getSections();
		 	var baseSections:ArrayCollection = base.getSections();
		 	
		 	var numReprodSections:int = reprodSections.length;
		 	var numBaseSections:int = baseSections.length;
		 	
		 	//used in case where a section should be ignored
		 	var reprodIndex:int = 0;
		 	var baseIndex:int = 0;
		 	 
		 	//iterate through each section
		 	//for(var i:int = 0; i < numReprodSections; i++) {
		 	while(reprodIndex < numReprodSections && baseIndex < numBaseSections) {
		 		
		 		var reprodSection:Section = reprodSections.getItemAt(reprodIndex) as Section;
		 		var baseSection:Section = baseSections.getItemAt(baseIndex) as Section;
		 		
		 		//TODO: ignoreSection should be an enum		 		 				 		
		 		var ignoreSection:int = prelimCompareSections(reprodSection, baseSection);
		 		
		 		if(ignoreSection == 0) {
		 			//sections are adequately matched so compare them
			 		error += compareSection(reprodSection, baseSection);
			 		reprodIndex++;
			 		baseIndex++;
			 	} else if(ignoreSection == -1) {
			 		baseIndex++;
			 	} else if(ignoreSection == 1) {
			 		reprodIndex++;
			 	}
		 	}
		 	
		 	//check if the surplus sections are significant in size, penalize accordingly
		 	for(var i:int = reprodIndex; i < numReprodSections; i++) {
		 		error += assessSectionSignificance(reprodSections.getItemAt(i) as Section);
		 	}
		 	
		 	for(var j:int = baseIndex; j < numBaseSections; j++) {
		 		error += assessSectionSignificance(baseSections.getItemAt(j) as Section);
		 	}
		 		
		 	return error;
		 } 
		 
		 //Check how big the section is to know how important it is
		 //use when calculating stray sections
		 private static function assessSectionSignificance(section:Section):int
		 {
		 	return determineSectionLength(section) * SCALE_WEIGHT;
		 }
		 
		 //Check to see if the two sections are even suitable for error assessment
		 //i.e. are they small imperfect sections that should be ignored?
		 //return 1 if reprod is illegitimate
		 //return -1 if base is illegitimate
		 //return 0 if both valid
		 private static function prelimCompareSections(reprod:Section, base:Section):int
		 {
		 	//in order to rule a section out, only one of the two can be small
		 	//approximate section path length as diagonal
		 	var reprodLength:Number = determineSectionLength(reprod);
		 	var baseLength:Number = determineSectionLength(base);
		 	
		 	if(reprodLength > SMALL_SECTION_SIZE && baseLength <= SMALL_SECTION_SIZE) {
		 		return -1;
		 	} else if(reprodLength <= SMALL_SECTION_SIZE && baseLength > SMALL_SECTION_SIZE) {
		 		return 1;
		 	}
		 	
		 	return 0;
		 }
		 
		 //determine approximate length of a section (it's diagonal length)
		 private static function determineSectionLength(section:Section):Number
		 {
		 	trace("h^2: " + Math.pow(section.getHeight(), 2) + " w^2:" + Math.pow(section.getWidth(), 2));
		 	trace("len: " + Math.sqrt(Math.pow(section.getHeight(), 2) + Math.pow(section.getWidth(), 2)));
		 	return Math.sqrt(Math.pow(section.getHeight(), 2) + Math.pow(section.getWidth(), 2));
		 }
		 
		 //Compare two sections
		 private static function compareSection(reprod:Section, base:Section):int
		 {
		 	//TODO: Adjust weight contributing to error for each comparison
		 	//TODO: are their of the sections small enough to ignore?
		 	
		 	var error:int = 0;
		 	 
		 	/* look at direction, slopes, change in slopes, length
		 	 */
		 	 
		 	 if(reprod.getDirection() != base.getDirection()) {
		 	 	error += 500;
		 	 }
		 	
		 	//compare slopes at each defined interval 
		 	var baseSlopes:ArrayCollection = base.getSlopes();
		 	var reprodSlopes:ArrayCollection = reprod.getSlopes();
		 	
		 	for(var i:int = 0; i < baseSlopes.length; i++ ) {
		 		trace("s" + i);
		 		trace("reprod= " + (reprodSlopes.getItemAt(i) as Number));
		 		trace("base= " + (baseSlopes.getItemAt(i) as Number));
		 		error += Math.abs((baseSlopes.getItemIndex(i) as Number) - (reprodSlopes.getItemAt(i) as Number)) * DetectionEngine.SLOPE_WEIGHT;
		 	}
		 	
		 	trace("reprod= w:" + reprod.getWidth() + ", h:" + reprod.getHeight());
		 	trace("base= w:" + base.getWidth() + ", h:" + base.getHeight());
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
		   
		//Perform analysis on gesture
		//i.e. parse into section, determine direction, slope, etc.
		public static function prepareGesture(gesture:Gesture):void
		{
			for each(var path:Path in gesture.getPaths()) {
				preparePath(path);
			}
		}
		
		//Perform analysis on path
		//i.e. parse into section, determine direction, slope, etc.
		public static function preparePath(path:Path):void
		{
			smoothPath(path);
			parsePath(path);
			determinePathSize(path);
			
			for each(var section:Section in path.getSections()) {
				determineSectionSize(path.getPoints(), section, path.getHeight(), path.getWidth());	
			}
			
			
		}
		
		//Remove anomalies from the path
		//i.e. remove points that are inconsistent with common trend
		private static function smoothPath(path:Path):void
		{
			var points:ArrayCollection = path.getPoints();
			var recentValidPoint:TouchPoint = points.getItemAt(0) as TouchPoint;
			var index:int = 0;
			for each(var point:TouchPoint in points) {
				if(index != 0) {
					if(point.getX() == recentValidPoint.getX() && point.getY() == recentValidPoint.getY()) {
						points.removeItemAt(index);
					}
				}
				
				index++;
			}
		}

		//Split a single blob path into sections based on direction		
		private static function parsePath(path:Path):void
		{
			//collection all the sections in this particular path
			var sections:ArrayCollection = new ArrayCollection(); 
			
			//the index of the first point in that section
			var sectionStartIndex:int = 0;
			
			//a counter that indicates the current index of the point
			//for the overall path
			var currentPointIndex:int = 0;
			
			var currentDirection:int = Direction.UNDEFINED;
			
			//these variables are used for tracking the most recent known state
			//in the iteration of points
			var previousPoint:TouchPoint = null;
			var previousDirection:int = Direction.UNDEFINED;
			
			for each(var point:TouchPoint in path.getPoints()) {
				//currentDirection = Direction.UNDEFINED;
				
				/* first define the direction from the previous point to current
				 */
				
				//temporary stores the change in X & Y directions from previous point to current
				//-1 = movement down/left
				//1 = movement up/right
				var deltaX:int = 1;
				var deltaY:int = 1;
				trace(point.getX() + ", " + point.getY()); 
						
				if(currentPointIndex != 0) {
					
					 
					
					if(point.getX() < previousPoint.getX()) {
						deltaX = -1;
					}
					
					if(point.getY() > previousPoint.getY()) {
						deltaY = -1;
					}
				
				
					//added this IF statement to reduce the hyper-switching of sections
					if(point.getX() != previousPoint.getX() && point.getY() != previousPoint.getY()) {
						if(deltaX < 0 && deltaY < 0) {
							currentDirection = Direction.DOWN_LEFT;
						} else if(deltaX < 0 && deltaY > 0) {
							currentDirection = Direction.UP_LEFT;
						} else if(deltaX > 0 && deltaY < 0) {
							currentDirection = Direction.DOWN_RIGHT;
						} else {
							currentDirection = Direction.UP_RIGHT;
						}
						
						//add this to prevent the UNDEFINED direction from being a section initially
						if(previousDirection == Direction.UNDEFINED) {
							previousDirection = currentDirection;
						}
					}
					
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
			
			//if no sections have been made, create one large one
			var finalSection:Section = new Section();
			if(sections.length == 0) {
				finalSection.setStartIndex(0);
			} else {
				finalSection.setStartIndex(sectionStartIndex);
			}
			
			finalSection.setEndIndex(path.getPoints().length - 1);
			finalSection.setDirection(currentDirection);
			defineSectionSubslopes(path, finalSection)
			sections.addItem(finalSection);
			
			/*
			if(sections.length == 0) {
				var singleSection:Section = new Section();
						
				singleSection.setStartIndex(0);
				singleSection.setEndIndex(path.getPoints().length - 1);
				
				
				singleSection.setDirection(currentDirection);
				
				defineSectionSubslopes(path, singleSection)
				
				sections.addItem(singleSection);
			}
			*/
			
			path.setSections(sections);
		}
		
		private static function determineDirection(currentX:int, currentY:int, previousX:int, previousY:int):int 
		{
			return 0;
		} 
		
		
		private static function determinePathSize(path:Path):void
		{
			var points:ArrayCollection = path.getPoints();
			
			var firstPoint:TouchPoint = points.getItemAt(0) as TouchPoint;
			
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
					minY = point.getY()
				} else if(point.getY() > maxY) {
					maxY = point.getY();
				}
			}
			
			path.setHeight(maxY - minY);
			path.setWidth(maxX - minX);
		}
		
		//Determine the size of the section as a percentage of the overall path size
		//i.e. the max X & Y deltas 
		private static function determineSectionSize(points:ArrayCollection, section:Section, pathHeight:int, pathWidth:int):void
		{
			var startIndex:int = section.getStartIndex();
			var endIndex:int = section.getEndIndex();
			
			var firstPoint:TouchPoint = points.getItemAt(startIndex) as TouchPoint;
			
			var maxX:int = firstPoint.getX();
			var minX:int = firstPoint.getX();
			var maxY:int = firstPoint.getY();
			var minY:int = firstPoint.getY();
						
			//for each(var point:TouchPoint in points) {
			for(var i:int = startIndex + 1; i <= endIndex; i++) {
				var point:TouchPoint = points.getItemAt(i) as TouchPoint;
								
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
			
			
			trace("section");
			trace("width: " + (maxX - minX));
			trace("height: " + (maxY - minY));
			
			section.setWidth(maxX - minX);
			section.setHeight(maxY - minY);
			/*
			trace("width: " + (maxX - minX) / (pathWidth as Number));
			trace("height: " + (maxY - minY) / (pathHeight as Number));
			
			section.setWidth((maxX - minX) / (pathWidth as Number));
			section.setHeight((maxY - minY) / (pathHeight as Number));
			*/ 
		}
		
				
		//Calculate and store the slope at 20% intervals of the section
		private static function defineSectionSubslopes(path:Path, section:Section):void
		{
			var slopes:ArrayCollection = new ArrayCollection();		
			
			var points:ArrayCollection = path.getPoints();
			var numPoints:int = section.getEndIndex() - section.getStartIndex() + 1;
			/*
			for(var i:int = 0; i < numPoints - (numPoints/5); i += numPoints/5) {
				var firstPoint:TouchPoint = points.getItemAt(i) as TouchPoint;
				var secondPoint:TouchPoint = points.getItemAt(i + numPoints/5) as TouchPoint;
				
				if(secondPoint == null) {
					
				}
			*/
			var sampleSize:int = numPoints/5 + 1;
			if(sampleSize == 0) {
				sampleSize = 1;
			}
			
			for(var i:int = 0; i < 5; i++) {
				var firstIndex:int = i * (sampleSize-1);
				var secondIndex:int = (i+1) * (sampleSize-1);
				if(secondIndex > numPoints - 1) {
					secondIndex = numPoints - 1;
				}
				
				var firstPoint:TouchPoint = points.getItemAt(firstIndex) as TouchPoint;
				var secondPoint:TouchPoint = points.getItemAt(secondIndex) as TouchPoint;
				
				if(i == 4) {
					secondPoint = points.getItemAt(numPoints - 1) as TouchPoint;
				}
				
				if(firstPoint == null) {
					if(numPoints > 1) {
						firstPoint = points.getItemAt(numPoints - 2)  as TouchPoint;	
					} else {
						firstPoint = points.getItemAt(0)  as TouchPoint;
					}
					
				}
				
				if(secondPoint == null) {
					secondPoint = points.getItemAt(numPoints - 1) as TouchPoint;
				}
				
					
				var rise:Number = secondPoint.getY() - firstPoint.getY();
				var run:Number = secondPoint.getX() - firstPoint.getX();
				
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
		private static function correlatePaths(reprod:Gesture, baseCollection:ArrayCollection):void
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
			
			var reprodOriginX:int = (reprodPaths as Path).getPoints().getItemAt(0).getX();
			var reprodOriginY:int = (reprodPaths as Path).getPoints().getItemAt(0).getY();
			
			for each(var path:Path in reprodPaths) {
				reprodX.push(path.getPoints().getItemAt(0).getX() - reprodOriginX);
				reprodY.push(path.getPoints().getItemAt(0).getY() - reprodOriginY);
			}
			
			//now do this for all the base gestures
			for each(var gesture:Gesture in baseCollection) {
				/*
				var paths:ArrayCollection = gesture.getPaths();
				
				//stores the list of relative X/Y distances from origin point
				var baseX:Array = new Array();
				var baseY:Array = new Array();
				
				var baseOriginX:int = paths.getPoints().getItemAt(0).getX();
				var baseOriginY:int = paths.getPoints().getItemAt(0).getY();
				
				for each(var path:Path in paths) {
					baseX.push(path.getPoints().getItemAt(0).getX() - baseOriginX);
					baseY.push(path.getPoints().getItemAt(0).getY() - baseOriginY);
				}
				*/
				//TODO: compare the relative distances between reproduced and base paths
				
					
			}
			
			
			
		}
		 

	}
}