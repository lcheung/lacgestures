package models
{
	import database.databaseUtilities;
	
	import flash.data.SQLStatement;
	
	import mx.collections.ArrayCollection;
		
	
	public class Gesture
	{
		private var gestureName:String;
		private var timeLength:Number;
		private var numBlobs:Number;	
		private var paths:ArrayCollection = new ArrayCollection();
		private var stmtGestureInsert:SQLStatement = new SQLStatement();
		private var stmtPathInsert:SQLStatement = new SQLStatement();
		private var stmtTouchPointInsert:SQLStatement = new SQLStatement();
		private var stmtSectionInsert:SQLStatement = new SQLStatement();
		private var stmtSlopeSectionInsert:SQLStatement = new SQLStatement();
		
		public function getGestureName():String
		{
			return gestureName;
		}
		public function getTimeLength():Number
		{
			return timeLength;
		}
		public function getNumBlobs():int
		{
			return numBlobs;
		}	
		public function getPaths():ArrayCollection
		{
			return paths;
		}
		
		public function setGestureName(inName:String ):void
		{
			gestureName = inName;
		}
		public function setTimeLength(inTimeLength:Number ):void
		{
			timeLength = inTimeLength;
		}
		public function setNumBlobs(inNumBlobs:int):void
		{
			numBlobs = inNumBlobs;
		}		
		public function setPaths(inPaths:ArrayCollection ):void
		{
			paths = inPaths;
		}
		
		public function Gesture()
		{			
			stmtGestureInsert.sqlConnection = database.databaseUtilities.getInstance();			
			stmtPathInsert.sqlConnection = database.databaseUtilities.getInstance();
			stmtSectionInsert.sqlConnection = database.databaseUtilities.getInstance();
			stmtTouchPointInsert.sqlConnection = database.databaseUtilities.getInstance();
			
			stmtSectionInsert.sqlConnection = database.databaseUtilities.getInstance();
			
			stmtGestureInsert.text = "INSERT INTO Gestures (Name, NumBlobs, TimeLength) " +
                "VALUES (:Name, :NumBlobs, :TimeLength)";
                    
        	stmtPathInsert.text = "INSERT INTO Paths (GestureID) " +
        		"VALUES (:GestID)";

    		stmtSectionInsert.text = "INSERT INTO Sections (PathID, StartIndex, EndIndex, Direction, Width, Height) " +
    			"VALUES (:PathID, :StartIndex, :EndIndex, :Direction, :Width, :Height)";
    		
			stmtTouchPointInsert.text = "INSERT INTO TouchPoints (PathID, XCord, YCord, TimeStamp) " +
       			"VALUES (:PathID, :XCord, :YCord, :TimeStamp)";	
       			
       		stmtSlopeSectionInsert.text = "INSERT INTO SectionSlopes (SectionID, Slope) " +
       			"VALUES (:SectionID, :Slope)";		   		
		}
		
		public function storeInDB():Number
		{                
            stmtGestureInsert.parameters[":Name"] = gestureName;
            stmtGestureInsert.parameters[":TimeLength"] = timeLength;
            stmtGestureInsert.parameters[":NumBlobs"] = numBlobs;
            stmtGestureInsert.execute();
            var GestureID:Number;
            GestureID = stmtGestureInsert.getResult().lastInsertRowID;    
            
            // store all the pathes in the Gesture
            for each(var path:Path in paths)  
            {
            	var PathID:Number;
            	var SectionID:Number;
            	
            	stmtPathInsert.parameters[":GestID"] = GestureID;
            	stmtPathInsert.execute();
            	PathID = stmtPathInsert.getResult().lastInsertRowID;
            	
            	//for each path, store the Sections
            	for each (var section:Section in path.getSections()) 
            	{				
            		stmtSectionInsert.parameters[":PathID"] = PathID;	
            		stmtSectionInsert.parameters[":StartIndex"] = section.getStartIndex();
            		stmtSectionInsert.parameters[":EndIndex"] = section.getEndIndex();
            		stmtSectionInsert.parameters[":Direction"] = section.getDirection();
            		stmtSectionInsert.parameters[":Width"] = section.getWidth();
            		stmtSectionInsert.parameters[":Height"] = section.getHeight();

					stmtSectionInsert.execute();
            		SectionID = stmtSectionInsert.getResult().lastInsertRowID;
            		
            		
            		for each(var slope:Number in section.getSlopes())
            		{
	            		stmtSlopeSectionInsert.parameters[":SectionID"] = SectionID;
	            		stmtSlopeSectionInsert.parameters[":Slope"] = slope;
	            		stmtSlopeSectionInsert.execute();
	            		var SectionSlopeID:int = stmtSlopeSectionInsert.getResult().lastInsertRowID;
            		}			
            		
            	}
            	
            	//for each path, store the touch points
            	for each (var touchpoint:TouchPoint in path.getPoints())
            	{
            		var TouchPointID: Number;
            		stmtTouchPointInsert.parameters[":PathID"] = PathID;	
            		stmtTouchPointInsert.parameters[":XCord"] = touchpoint.getX();
            		stmtTouchPointInsert.parameters[":YCord"] = touchpoint.getY();
            		stmtTouchPointInsert.parameters[":TimeStamp"] = touchpoint.getTimestamp();

					stmtTouchPointInsert.execute();
            		TouchPointID = stmtTouchPointInsert.getResult().lastInsertRowID;            		
            	}
            }
            
           return GestureID;    
		}
		
		public function getGesturesFromDB():ArrayCollection
		{
			var stmtKeySelect:SQLStatement = new SQLStatement();
            stmtKeySelect.sqlConnection =  database.databaseUtilities.getInstance();
            stmtKeySelect.text = "SELECT GestureID FROM Gestures";
			stmtKeySelect.execute();			
			var GestureIDs:ArrayCollection = new ArrayCollection(stmtKeySelect.getResult().data);	
			
			var stmtGestureSelect:SQLStatement = new SQLStatement();
           	stmtGestureSelect.sqlConnection =  database.databaseUtilities.getInstance();
            stmtGestureSelect.text = "SELECT Name, NumBlobs, TimeLength FROM Gestures"
            	+ "WHERE GestureID = :GestID";
            	
            var stmtPathsSelect:SQLStatement = new SQLStatement();
            stmtPathsSelect.sqlConnection =  database.databaseUtilities.getInstance();	
			stmtPathsSelect.text = "SELECT PathID FROM Paths"
            	+ "WHERE GestureID = :GestID";
            	
            var stmtSectionsSelect:SQLStatement = new SQLStatement();
            stmtSectionsSelect.sqlConnection =  database.databaseUtilities.getInstance();	
			stmtSectionsSelect.text = "SELECT SectionID, Direction, StartIndex, EndIndex, Width, " 
				 + "Height FROM Sections WHERE PathID = :PathID";	           	
     
            var stmtSectionSlopesSelect:SQLStatement = new SQLStatement();
            stmtSectionSlopesSelect.sqlConnection =  database.databaseUtilities.getInstance();	
			stmtSectionSlopesSelect.text = "SELECT Slope FROM SectionSlopes"
            	+ "WHERE SectionID = :SectID ORDER BY SectionSlopeID ASC";	
            	
            var stmtTouchPointsSelect:SQLStatement = new SQLStatement();
            stmtTouchPointsSelect.sqlConnection =  database.databaseUtilities.getInstance();	
			stmtTouchPointsSelect.text = "SELECT XCord, YCord, TimeStamp " 
				 + "FROM TouchPoints WHERE PathID = :PathID";
				 	
			var PopulatedGestures:ArrayCollection = new ArrayCollection();
			
			for each (var GestureID:Number in GestureIDs)
			{
				
				var singleGesture:Gesture = new Gesture();
				
				stmtGestureSelect.parameters[":GestID"] = GestureID; 
				stmtGestureSelect.execute();
				var gestureResults:ArrayCollection = new ArrayCollection(stmtGestureSelect.getResult().data);
				singleGesture.setGestureName(gestureResults[0].Name); 
				singleGesture.setNumBlobs(gestureResults[0].NumBlobs);
				singleGesture.setTimeLength(gestureResults[0].TimeLength);
				
				stmtPathsSelect.parameters[":GestID"] = GestureID; 
				stmtPathsSelect.execute();
				var pathSQLResults:ArrayCollection = new ArrayCollection(stmtPathsSelect.getResult().data);
				
				var populatedPaths:ArrayCollection = new ArrayCollection();
				
				for each (var pathFromDB:Object in pathSQLResults)
				{
					var pathObject:Path = new Path();
										
					stmtSectionsSelect.parameters[":PathID"] = pathFromDB.PathID; 
					stmtSectionsSelect.execute();
					var sectionResults:ArrayCollection = new ArrayCollection(stmtSectionsSelect.getResult().data);

					var sectionObjectList:ArrayCollection = new ArrayCollection();
					
					for each (var section:Object in sectionResults)
					{
						var sectionObject:Section = new Section();	
						//populate the section information to the section object
						sectionObject.setDirection(section.Direction);
						sectionObject.setStartIndex(section.StartIndex);
						sectionObject.setEndIndex(section.EndIndex);
						sectionObject.setHeight(section.Height);
						sectionObject.setWidth(section.Width);
						
						//obtain and add the section slopes for the section
						stmtSectionSlopesSelect.parameters[":SectID"] = section.SectionID; 
						stmtSectionSlopesSelect.execute();				
						var sectionSlopesData:ArrayCollection = new ArrayCollection(stmtSectionSlopesSelect.getResult().data);	
						sectionObject.setSlopes(sectionSlopesData);													
						
						//add the section to the sectionList
						sectionObjectList.addItem(sectionObject);
										
					}
					
					//add the section Objects to the path
					pathObject.setSections(sectionObjectList);
						
					stmtTouchPointsSelect.parameters[":PathID"] = pathFromDB.PathID; 
					stmtTouchPointsSelect.execute();
					var touchPointResults:ArrayCollection = new ArrayCollection(stmtTouchPointsSelect.getResult().data);
					
					var touchPointObjectList:ArrayCollection = new ArrayCollection();
					
					for each (var touchPoint:Object in touchPointResults)
					{
						var touchPointObject:TouchPoint = new TouchPoint();
						
						touchPointObject.setTimestamp(touchPoint.timeStamp);
						touchPointObject.setX(touchPoint.XCord);
						touchPointObject.setY(touchPoint.YCord);
						
						// add the touchPoints to the path
						touchPointObjectList.addItem(touchPointObject);
					}
					
					//add the touchpointlist to the path
					pathObject.setPoints(touchPointObjectList);
					
					//add the path the list of paths
					populatedPaths.addItem(pathObject);
				}
				
				singleGesture.setPaths(populatedPaths);
				
				PopulatedGestures.addItem(singleGesture);
			}
			return PopulatedGestures;
		}
	}
}