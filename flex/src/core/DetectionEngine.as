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
		public static const NUM_SLOPES_PER_SECTION:int = 5;
		//values used for configuring comparison
		public static const ERROR_THRESHOLD:int = 1200;
		public static const SLOPE_WEIGHT:int = 50;
		public static const SCALE_WEIGHT:int = 5;
		public static const UNMATCHED_SCALE_WEIGHT:int = 25;
		public static const WRONG_DIRECTION_PENALTY:int = 1500; //error to apply for conflicting section directions
		public static const SLOPE_VARIATION_TOLERANCE:Number = 0.25; //on fringe cases between directions, the maximum (absolute ratio) slope difference allowed
		public static const SMALL_SECTION_SIZE:int = 10; //the maximum size a section can be to be a candidate for being ignored
		public static const MAX_DIVISION_FACTOR:Number = 3.0; //the maximum ratio that the path error can be scaled down by
		public static const EXCESS_SECTION_INCREMENT:Number = 2.0; //for every excess section in a path comparison, how much do you progressively penalize by? 
		public static const MULTI_FINGER_ERROR_TOLERANCE:Number = 1.25; //allow more error per path for multi touch gestures
		
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
		 	
		 	var numPaths:int = reprod.getPaths().length;			
		 				
		 	for(var j:int = storedGestures.length - 1; j >= 0; j--) {
				var baseGesture:Gesture = storedGestures.getItemAt(j) as Gesture;
			 	if(baseGesture.getPaths().length != numPaths) {
			 		storedGestures.removeItemAt(j);	
			 	}
		 	}
		 	
		 	//process the 
		 	storedGestures = correlatePaths(reprod, storedGestures);
		 	var reprodPaths:ArrayCollection = reprod.getPaths();
		 	
		 	//TODO: This is just temporary until all the proper info is stored in DB
		 	for each(var g:Gesture in storedGestures) {
		 		prepareGesture(g);
		 	}
		 	

		 	
		 	//prepare each path in the reproduced gesture by removing unnecessary points and parsing into sections
		 	prepareGesture(reprod);
		 	/*for each(var path:Path in reprodPaths) {
		 		preparePath(path);
		 	}*/
		 	
		 	//remove any gestures that don't have the same number of points
		 	/*
		 	for each(var baseGesture:Gesture in storedGestures) {
		 		if(baseGesture.getPaths().length != numPaths) {
		 			//TODO: Remove these gestures from ones being compared
		 			
		 		}
		 	
		 	}
		 	*/
		 	

		 	
		 				 	
		 	//create a 1-to-1 mapping of the base and reproduced gesture paths
		 	//correlatePaths();
		 	
		 	for each(var gesture:Gesture in storedGestures) {
		 		var gestureError:int = 0;
		 		
		 		trace("=== GESTURE ===");
		 		trace("===============");
		 		var numPathsInRepr:int = reprodPaths.length;
		 		var numPathsInCurrGest:int = gesture.getPaths().length;
		 		
		 		//TODO: In the future, match the paths to be compared based on outcome from correlatePaths()
		 		for(var i:int = 0; i < numPaths; i++) {
		 			trace("Path " + i + ":")
			 		gestureError += comparePaths(reprodPaths.getItemAt(i) as Path, gesture.getPaths().getItemAt(i) as Path);
			 	}
			 	
			 	//look at average error overall paths, not total error
			 	gestureError = gestureError / numPaths;
			 	
			 	trace("GESTURE ERROR: " + gestureError);
			 	
			 	if(gestureError < minError || closestGesture == null) {
			 		minError = gestureError;
			 		closestGesture = gesture;
			 	}
			 	
		 	}
		 	
		 	//is the most similar gesture close enough to the reproduced?
		 	var errorThreshold:int = ERROR_THRESHOLD;
		 	if(numPaths > 1) {
		 		errorThreshold *= MULTI_FINGER_ERROR_TOLERANCE * (numPaths - 1);
		 	} 
		 	
		 	if(minError < errorThreshold) {
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
		 		trace("Section r: " + reprodIndex + " b: " + baseIndex); 
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
		 	
		 	var numExcess:int = 1; //the number of extra sections, used to penalize excess sections progressively more heavily 
		 	 
		 	//check if the surplus sections are significant in size, penalize accordingly
		 	for(var i:int = reprodIndex; i < numReprodSections; i++) {
		 		error += assessSectionSignificance(reprodSections.getItemAt(i) as Section) * (numExcess * EXCESS_SECTION_INCREMENT);
		 		numExcess++;
		 	}
		 	
		 	for(var j:int = baseIndex; j < numBaseSections; j++) {
		 		error += assessSectionSignificance(baseSections.getItemAt(j) as Section) * (numExcess * EXCESS_SECTION_INCREMENT);
		 		numExcess++;
		 	}
		 		
		 	return normalizePathError(error, reprod, base);
		 } 
		 
		 //adjust the path error based on the path characteristics
		 //to reduce error compounding on large paths
		 private static function normalizePathError(error:int, reprodPath:Path, basePath:Path): int
		 {
		 	
		 	//TODO: should also be impacted by overall path size in some way
		 	
		 	//look at the number of sections
		 	var divisionFactor:Number = Math.min(reprodPath.getSections().length, basePath.getSections().length); //how much to cut the error down by
		 	
		 	if(divisionFactor > MAX_DIVISION_FACTOR) {
		 		divisionFactor = MAX_DIVISION_FACTOR;
		 	}
		 	
		 	error = error / divisionFactor;
		 	
		 	return error;
		 }
		 
		 //Check how big the section is to know how important it is
		 //use when calculating stray sections
		 private static function assessSectionSignificance(section:Section):int
		 {
		 	return determineSectionLength(section) * UNMATCHED_SCALE_WEIGHT;
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

			trace("section lengths r: " + reprodLength + " b: " + baseLength);

			//check to see if the lengths are quite different relative to each other
		 	if(reprodLength / baseLength > 3.0 || baseLength / reprodLength > 3.0) {
		 		//then check to see if either of the lengths are small
			 	if(reprodLength > SMALL_SECTION_SIZE && baseLength <= SMALL_SECTION_SIZE) {
			 		return -1;
			 	} else if(reprodLength <= SMALL_SECTION_SIZE && baseLength > SMALL_SECTION_SIZE) {
			 		return 1;
			 	}
		 	}
		 	
		 	return 0;
		 }
		 
		 //determine approximate length of a section (it's diagonal length)
		 private static function determineSectionLength(section:Section):Number
		 {
		 	//trace("h^2: " + Math.pow(section.getHeight(), 2) + " w^2:" + Math.pow(section.getWidth(), 2));
		 	//trace("len: " + Math.sqrt(Math.pow(section.getHeight(), 2) + Math.pow(section.getWidth(), 2)));
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
		 	 trace("r dir: " + reprod.getDirection());
		 	 trace("b dir: " + base.getDirection());
		 	 	
		 	 if(reprod.getDirection() != base.getDirection()) {
		 	 	error += determineLineProximity(reprod, base);
		 	 }
		 	
		 	//compare slopes at each defined interval 
		 	var baseSlopes:ArrayCollection = base.getSlopes();
		 	var reprodSlopes:ArrayCollection = reprod.getSlopes();
		 	
		 	for(var i:int = 0; i < NUM_SLOPES_PER_SECTION; i++ ) {
		 		trace("slope " + i);
		 		trace("reprod= " + (reprodSlopes.getItemAt(i) as Number));
		 		trace("base= " + (baseSlopes.getItemAt(i) as Number));
		 		
		 		var baseSlope:Number = baseSlopes.getItemIndex(i) as Number;
		 		var reprodSlope:Number = reprodSlopes.getItemAt(i) as Number;
		 		
		 		if(Math.abs(baseSlope) > 1.0 && Math.abs(reprodSlope) > 1.0) {
		 			baseSlope = negativeReciprocal(baseSlope);
		 			reprodSlope = negativeReciprocal(reprodSlope);
		 		}
		 		
		 		error += Math.abs(Math.abs(baseSlope) - Math.abs(reprodSlope)) * SLOPE_WEIGHT;
		 	}
		 	
		 	trace("reprod= w:" + reprod.getWidth() + ", h:" + reprod.getHeight());
		 	trace("base= w:" + base.getWidth() + ", h:" + base.getHeight());
		 	
		 	//compare (approximate) lengths of the section
		 	error += Math.abs(determineSectionLength(base) - determineSectionLength(reprod)) * SCALE_WEIGHT;
		 	
			trace("section error: " + error);
		 	
		 	return error;
		 }
		
		//if section directions are different, see if they're at least close
		//to protect against close cases in vertical/horizontal
		private static function determineLineProximity(first:Section, second:Section):int
		{
			//check for adjacency of sections
			//if adjacent, don't worry about adding error, will be done when comparing slopes
			if(isSectionAdjacent(first, second)) return 0;
						
			return WRONG_DIRECTION_PENALTY;
		}
		
		//check if the two sections are beside each other
		private static function isSectionAdjacent(first:Section, second:Section):Boolean
		{
			switch(first.getDirection()) {
				case Direction.UP_LEFT:
				if(second.getDirection() == Direction.DOWN_RIGHT) return false;
				if(second.getDirection() == Direction.UP_RIGHT) return checkSectionSlopesProximity(first, second, false);
				if(second.getDirection() == Direction.DOWN_LEFT) return checkSectionSlopesProximity(first, second, true);
				
				break;
				
				case Direction.UP_RIGHT:
				if(second.getDirection() == Direction.DOWN_LEFT) return false;
				if(second.getDirection() == Direction.UP_LEFT) return checkSectionSlopesProximity(second, first, false);
				if(second.getDirection() == Direction.DOWN_RIGHT) return checkSectionSlopesProximity(first, second, true);
				
				break;
				
				case Direction.DOWN_LEFT:
				if(second.getDirection() == Direction.UP_RIGHT) return false;
				if(second.getDirection() == Direction.UP_LEFT) return checkSectionSlopesProximity(second, first, true);
				if(second.getDirection() == Direction.DOWN_RIGHT) return checkSectionSlopesProximity(first, second, false);
				
				break;
				
				case Direction.DOWN_RIGHT:
				if(second.getDirection() == Direction.UP_LEFT) return false;
				if(second.getDirection() == Direction.UP_RIGHT) return checkSectionSlopesProximity(second, first, true);
				if(second.getDirection() == Direction.DOWN_LEFT) return checkSectionSlopesProximity(second, first, false);
				
				break;
			}
			
			return true;
		}
		
		private static function checkSectionSlopesProximity(topOrLeft:Section, bottomOrRight:Section, isVertical:Boolean): Boolean
		{
			var topOrLeftSlopes:ArrayCollection = topOrLeft.getSlopes();
			var bottomOrRightSlopes:ArrayCollection = bottomOrRight.getSlopes();
			
			var topOrLeftSlopesClone:Array = topOrLeftSlopes.toArray();
			var bottomOrRightSlopesClone:Array = bottomOrRightSlopes.toArray();
			
			if(isVertical) {
				//one section is on top of the other
				
				//look if either have an absolute slope greater than 1
				if(Math.abs(findAverageSectionSlope(topOrLeft)) >= 1 || Math.abs(findAverageSectionSlope(bottomOrRight)) >= 1) {
					return false;
				}
				
				
			} else {
				//sections are side by side
				
				//look if either have an absolute slope less than 1
				if(Math.abs(findAverageSectionSlope(topOrLeft)) <= 1 || Math.abs(findAverageSectionSlope(bottomOrRight)) <= 1) {
					return false;
				}
				
				//find negative reciprocal so that small values can be compared
				for(var j:int = 0; j < NUM_SLOPES_PER_SECTION; j++) {
					topOrLeftSlopesClone[j] = negativeReciprocal(topOrLeftSlopesClone[j]);
					bottomOrRightSlopesClone[j] = negativeReciprocal(bottomOrRightSlopesClone[j]);  
				}
				
			}
			
			//make sure to look at absolute values
			for(var i:int = 0; i < NUM_SLOPES_PER_SECTION; i++) {
				
				if(Math.abs(Math.abs(topOrLeftSlopesClone[i]) - Math.abs(bottomOrRightSlopesClone[i])) > SLOPE_VARIATION_TOLERANCE) {
					return false;
				}  
				
			}
			return true;
		}
		
		private static function negativeReciprocal(slope:Number):Number
		{
			return -1 / slope;
		}
		
		private static function findAverageSectionSlope(section:Section):Number
		{
			var accumulator:Number = 0;
			for each(var slope:Number in section.getSlopes()) {
				accumulator += slope;
			}
			
			return accumulator / NUM_SLOPES_PER_SECTION;
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
		private static function preparePath(path:Path):void
		{
			trace("before smoothing: # points: " + path.getPoints().length);
			smoothPath(path);
			trace("after smoothing: # points: " + path.getPoints().length);
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
			/*
			var recentValidPoint:TouchPoint = points.getItemAt(0) as TouchPoint;
			
			var index:int = 0;
			for each(var point:TouchPoint in points) {
				if(index != 0) {
					if(point.getX() == recentValidPoint.getX() && point.getY() == recentValidPoint.getY()) {
						points.removeItemAt(index);
					}
				}
				
				index++;
			}*/
			var recentValidPoint:TouchPoint = points.getItemAt(points.length - 1) as TouchPoint;
			for(var i:int = points.length - 1; i >= 0; i--) {
				var point:TouchPoint = path.getPoints().getItemAt(i) as TouchPoint;
				if(i != points.length - 1) {
					if(point.getX() == recentValidPoint.getX() && point.getY() == recentValidPoint.getY()) {
						points.removeItemAt(i);
					} else {
						recentValidPoint = point;
					}
				}
				
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
				
				
				//TODO: be more forgiving on section splitting
				//check the difference in slopes first
				//or wait for a few more points to see where it's going				
				
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
					minY = point.getY()
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
			var sampleSize:int = numPoints/NUM_SLOPES_PER_SECTION + 1;
			if(sampleSize == 0) {
				sampleSize = 1;
			}
			
			for(var i:int = 0; i < NUM_SLOPES_PER_SECTION; i++) {
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
				
				if(slopes.length < NUM_SLOPES_PER_SECTION) {
					slopes.addItem(slope);
				}
			}  
			
			section.setSlopes(slopes);
		}
		
		private static function reorderPathsLeftToRight(pathSets:ArrayCollection):ArrayCollection
		{
			var reorderedPathSets:ArrayCollection = new ArrayCollection();
			var leftMostPoint:int;
			var leftMostIndex:int;
			var numPaths: int = pathSets.length;
			for(var i:int=0; i<numPaths; i++)
			{
				var thePath:Path = pathSets.getItemAt(0) as Path;
				var thePoint: TouchPoint = thePath.getPoints().getItemAt(0) as TouchPoint;
				leftMostPoint = thePoint.getX();
				leftMostIndex = 0;
				
				var indexCounter: int = 0;
				for each(var path:Path in pathSets )
				{
					
					var firstPoint:TouchPoint = path.getPoints().getItemAt(0) as TouchPoint;				
					if(firstPoint.getX() < leftMostPoint)
					{
						leftMostPoint = firstPoint.getX();
						leftMostIndex = indexCounter;
					}
					indexCounter = indexCounter + 1;
					
				}
				indexCounter = 0;
				reorderedPathSets.addItem(pathSets.getItemAt(leftMostIndex));
				pathSets.removeItemAt(leftMostIndex);
			}
			return reorderedPathSets;
			
		}
		
		//Pair up the paths on the reproduced gesture with those of the base gestures
		private static function correlatePaths(reprod:Gesture, baseCollection:ArrayCollection):ArrayCollection
		{
			//return an array collection of Gestures from baseCollection, but reorder the paths internally
			var possibleGestures:ArrayCollection = new ArrayCollection();
			var numPaths:int = reprod.getPaths().length;
			
			var pathSets:ArrayCollection = reorderPathsLeftToRight(reprod.getPaths());
			reprod.setPaths(pathSets);
			numPaths = reprod.getPaths().length;
			//reprod.getPaths(); //							
/*
			var intialPath:Path = pathSets.getItemAt(0) as Path;
			var intialPoint:TouchPoint = intialPath.getPoints().getItemAt(0) as TouchPoint;
			
	
			// pick the starting coordinates of any path and use the relative X/Y variation
			// of the start coords of the other paths to match 
			var reprodOriginX:int = intialPoint.getX();
			var reprodOriginY:int = intialPoint.getY();		
			
			//stores the list of relative X/Y distances from origin point
			var reprodXDist:ArrayCollection = new ArrayCollection();
			var reprodYDist:ArrayCollection = new ArrayCollection();
			

			//push the absolulte relative distances of each start point in an array for later comparison
			for each(var path:Path in pathSets) 
			{
				reprodXDist.addItem(  Math.abs(  path.getPoints().getItemAt(0).getX() - reprodOriginX) );
				reprodYDist.addItem(  Math.abs( path.getPoints().getItemAt(0).getY() - reprodOriginY) );
			}
			
			//Now calculate the diagonal distances and push them onto an arrayCollection
			var diagonalDistReprod:ArrayCollection = new ArrayCollection();
			for(var i:int =0; i<reprodXDist.length; i++)
			{
				diagonalDistReprod.addItem(Math.sqrt(  (reprodXDist[i] * reprodXDist[i]) + (reprodYDist[i] * reprodYDist[i]) ) );
			}
			
			
			//now do this for all the base gestures, and comparing to the Reprod Gesture
			for each(var gesture:Gesture in baseCollection)
			{	
				var basePathSets:ArrayCollection = gesture.getPaths();//reorderPathsLeftToRight(gesture.getPaths());							
				intialPath = pathSets.getItemAt(0) as Path;
				intialPoint = intialPath.getPoints().getItemAt(0) as TouchPoint;
				
				
				var baseCollectionOriginX:int = intialPoint.getX();
				var baseCollectionOriginY:int = intialPoint.getY();
				
				//stores the list of relative X/Y distances from origin point
				var baseCollectionXDist:ArrayCollection = new ArrayCollection();
				var baseCollectionYDist:ArrayCollection = new ArrayCollection();
				
				//push the absolulte relative distances of each start point in an array for later comparison
				for each(var thePath:Path in gesture.getPaths()) 
				{
					baseCollectionXDist.addItem( Math.abs( thePath.getPoints().getItemAt(0).getX() - baseCollectionOriginX) );
					baseCollectionYDist.addItem( Math.abs( thePath.getPoints().getItemAt(0).getY() - baseCollectionOriginY) );
				}
				
				//Now calculate the diagonal distances and push them onto an arrayCollection
				var diagonalDistBase:ArrayCollection = new ArrayCollection();
				for(var q:int=0; q<reprodXDist.length; q++)
				{
					diagonalDistBase.addItem(Math.sqrt(  (baseCollectionXDist[q] * baseCollectionXDist[q]) + (baseCollectionYDist[q] * baseCollectionYDist[q]) ) );
				}
				
				
				// compare the relative distances between reproduced and base paths
				var probableMatch:int = 0;
				var probability:int = 0;

				
				//make an array to store the matched indexes of paths
				var possibleMatchedPaths:ArrayCollection = new ArrayCollection();
				var definiteMatchedPaths:ArrayCollection = new ArrayCollection();
				
				
				//for each path in the reproduced Gesture
				for(var r:int=0; r<diagonalDistReprod.length; r++)
				{	
					var closestValue:int=0;
					var indexOfClosestValue:int=0;
					
					//find the closest path match in the reproduced gesture
					for(var j:int=0; j<diagonalDistBase.length; j++)
					{											
						var difference:Number = Math.abs(  Number(diagonalDistBase.getItemAt(j)) - Number(diagonalDistReprod.getItemAt(j)) );
						
						if (j==0)	//closest needs to be initialized just the first time
						{
							closestValue=difference;
						}
						
						//TUNE THIS VALUE, if the relative distance is say 5 units away
						if(  difference < DISTANCETUNABLE)
						{
							probableMatch++;	//increment the counter to show that this is close
							//store the index for later, in case there are more than 1 close match
							possibleMatchedPaths.addItem(j);					
						}
						else
						{					
							if( closestValue > difference) 
							{
								closestValue = difference;
								indexOfClosestValue = j;
							} 
						}
					}
					
					if(probableMatch > 1)	//more than 1 probable match
					{
						probableMatch=0; //reset the flag for next path

						//Now its time to look at slopes, and find the matches
						
						var dxGold:Number;
						var dyGold:Number;
						var slopeGold:Number;
						
						var dx:int;
						var dy:int;
						var slope:Number;
						
						//cycle through all the possible matches
						var tempPoint:TouchPoint;	
						var tempIndex:int;
						var tempPath:Path;
						tempIndex = int(possibleMatchedPaths.getItemAt(r))
						tempPath = pathSets.getItemAt(tempIndex) as Path;
						tempPoint = tempPath.getPoints().getItemAt(0) as TouchPoint;
						
						dxGold =  reprodOriginX - tempPoint.getX();
						
						dyGold =  reprodOriginY - tempPoint.getY();
						slopeGold = dyGold/dxGold;
						
						var closestSlope:Number; 
						var indexOfClosestSlope:Number;
						//cycle through all the possible matches
						for (var k:int=0; k<possibleMatchedPaths.length; k++)
						{

							tempIndex = Number (possibleMatchedPaths.getItemAt(k));
							tempPath = basePathSets.getItemAt(tempIndex) as Path;
							tempPoint = tempPath.getPoints().getItemAt(0) as TouchPoint;	
							dx = baseCollectionOriginX - tempPoint.getX();
							dy = baseCollectionOriginY - tempPoint.getY();
							
							slope = dy/dx;
							
							var slopeDiff:Number = Math.abs(slopeGold-slope);
							
							if(k==0)
							{
								closestSlope=slopeDiff;
							}
							else
							{
								if(slopeDiff<closestSlope)
								{
									closestSlope=slopeDiff;
									indexOfClosestSlope=k;
								}
							}		
						}
						definiteMatchedPaths.addItem(possibleMatchedPaths.getItemAt(indexOfClosestSlope));
						diagonalDistBase.removeItemAt( int( possibleMatchedPaths.getItemAt(indexOfClosestSlope)) );
						
					}
					else if (probableMatch == 1) //Exactly 1 probable match, best case!!!
					{
						probableMatch=0; //reset the flag for next path
						diagonalDistBase.removeItemAt( int(possibleMatchedPaths.getItemAt(i)) ); //remove the items so that they don't conflict with others
						definiteMatchedPaths.addItem(possibleMatchedPaths.getItemAt(i));
						probability++;
					}					
					else
					{
						//no match found...uh oh... might as well choose the closest.
						probableMatch=0; //reset the flag for next path
						diagonalDistBase.removeItemAt(indexOfClosestValue); //remove the items so that they don't conflict with others
						definiteMatchedPaths.addItem(indexOfClosestValue);
					}
				}
				
				//TUNE THIS VALUE, if matches for more than say 75% of the paths
				if(probability > (baseCollectionXDist.length * PROBABILITYTUNABLE) )
				{
					//Likely its a match, keep it for return
					
					
					//reorder the paths in the gesture
					var rearrangedPaths:ArrayCollection = new ArrayCollection();
					//use the matchedPathes array items
					for(var s:int=0; s< reprodXDist.length; s++)
					{
						var theSinglePath:Path = gesture.getPaths().getItemAt( int(definiteMatchedPaths.getItemAt(s)) ) as Path;
						rearrangedPaths.addItem( theSinglePath );	
					}
					gesture.setPaths( rearrangedPaths);
					
					//add the gesture to the arraycollection for return
					possibleGestures.addItem(gesture);
				}
				else
				{
					//Not a match... don't keep it for return
				}
				
			}
*/			
			for each(var gesture:Gesture in baseCollection)
			{	
				
				var rearrangedPaths:ArrayCollection = reorderPathsLeftToRight(gesture.getPaths());							
				//var numPaths:int = rearrangedPaths.length;
				gesture.setPaths( rearrangedPaths);
				possibleGestures.addItem(gesture);
			}	
			return possibleGestures;	
		}
			
			
			
		
		 

	}
}