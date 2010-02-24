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
		
		public function populateSingleGestureFromDB(key:Number):void
		{
			var stmtSelect:SQLStatement = new SQLStatement();
            stmtSelect.sqlConnection =  database.databaseUtilities.getInstance();
            stmtSelect.text =
            	"SELECT Name, NumBlobs, TimeLength FROM Gestures" +
            		" WHERE (GestureID=:GestureInputID)";
			stmtSelect.parameters[":GestureInputID"] = key;
			stmtSelect.execute();
			var results:ArrayCollection = new ArrayCollection(stmtSelect.getResult().data);	
			gestureName = results[0].Name;
			timeLength = results[0].timeLength;
			numBlobs = results[0].numBlobs;
			
		}

	}
}