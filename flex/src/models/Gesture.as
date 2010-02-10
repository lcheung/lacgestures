package models
{
	import database.databaseUtilities;
	
	import flash.data.SQLStatement;
	
	import mx.collections.ArrayCollection;
		
	
	public class Gesture
	{
		private var gestureName:String;
		private var timeLength:Number;
		private var numBlobs:int;	
		private var pathes:ArrayCollection = new ArrayCollection();
		var stmtGestureInsert:SQLStatement = new SQLStatement();
		var stmtPathInsert:SQLStatement = new SQLStatement();
		var stmtTouchPointInsert:SQLStatement = new SQLStatement();
		var stmtSectionInsert:SQLStatement = new SQLStatement();
		
		public function getGestureName():Sting
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
		public function getPathes():ArrayCollection
		{
			return pathes;
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
		public function setPathes(inPathes:ArrayCollection ):void
		{
			pathes = inPathes;
		}
		
		public function Gesture()
		{			
			stmtGestureInsert.sqlConnection = database.databaseUtilities.getInstance();			
			stmtPathInsert.sqlConnection = database.databaseUtilities.getInstance();
			stmtTouchPointInsert.sqlConnection = database.databaseUtilities.getInstance();
			
			stmtSectionInsert.sqlConnection = database.databaseUtilities.getInstance();
			
			stmtGestureInsert.text = "INSERT INTO Gestures (Name, NumBlobs, TimeLength) " +
                "VALUES (:Name, :NumBlobs, :TimeLength)";
                    
        	stmtPathInsert.text = "INSERT INTO Pathes (GestureID) " +
        		"VALUES (:GestID)";

    		stmtSectionInsert.text = "INSERT INTO Section (GestureID, startIndex, endIndex, direction, witdth, height) " +
    			"VALUES (:GestID, :StartIndex, :EndIndex, :Direction, :Width, :Height)";
    			   		
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
            for each(var path:Path in pathes)  
            {
            	var PathID:Number;
            	var SectionID:Number;
            	
            	stmtPathInsert.parameters[":GestID"] = GestureID;
            	
            	PathID = stmtPathInsert.getResult().lastInsertRowID;
            	
            	//for each path, store the Sections
            	for each (var section:Section in path.getSections()) 
            	{
				//	var slopes:ArrayCollection = section.getSlopes(); TODO what do we do with this???
					
					stmtSectionInsert.text = "INSERT INTO Section (GestureID, startIndex, endIndex, direction, witdth, height) " +
            			"VALUES (:GestID, :StartIndex, :EndIndex, :Direction, :Width, :Height)";
            		stmtSectionInsert.parameters[":GestID"] = GestureID;	
            		stmtSectionInsert.parameters[":StartIndex"] = section.getStartIndex();
            		stmtSectionInsert.parameters[":EndIndex"] = section.getEndIndex();
            		stmtSectionInsert.parameters[":Direction"] = section.getDirection();
            		stmtSectionInsert.parameters[":Width"] = section.getWidth();
            		stmtSectionInsert.parameters[":Height"] = section.getHeight();

            		SectionID = stmtSectionInsert.getResult().lastInsertRowID;
            	}
            	
            	//for each path, store the touch points
            	for each (var touchpoint:TouchPoint in path.getPoints())
            	{
            		var TouchPointID: Number;

					stmtTouchPointInsert.text = "INSERT INTO touchPoints (SectionID, X, Y, TimeStamp) " +
               			"VALUES (:SectionID, :X, :Y, :TimeStamp)";
            		stmtTouchPointInsert.parameters[":SectionID"] = SectionID;	
            		stmtTouchPointInsert.parameters[":X"] = touchpoint.getX();
            		stmtTouchPointInsert.parameters[":Y"] = touchpoint.getY();
            		stmtTouchPointInsert.parameters[":TimeStamp"] = touchpoint.getTimestamp();

            		TouchPointID = stmtTouchPointInsert.getResult().lastInsertRowID;
            		
            	}
            }
            
               
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