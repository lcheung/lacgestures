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
		private var paths:ArrayCollection = new ArrayCollection();
		
		public function Gesture()
		{
		}
		
		public function getPaths():ArrayCollection
		{
			return this.paths;
		}
		
		public function setPaths(paths:ArrayCollection):void
		{
			this.paths = paths;
		}
		
		public function storeInDB():Number
		{
			var stmtInsert:SQLStatement = new SQLStatement();
			stmtInsert.sqlConnection = database.databaseUtilities.getInstance();
			stmtInsert.text = 
                "INSERT INTO Gestures (Name, NumBlobs, TimeLength) " +
                    "VALUES (:Name, :NumBlobs, :TimeLength)";
                    
            stmtInsert.parameters[":Name"] = gestureName;
            stmtInsert.parameters[":TimeLength"] = timeLength;
            stmtInsert.parameters[":NumBlobs"] = numBlobs;
            stmtInsert.execute();
            return stmtInsert.getResult().lastInsertRowID;        
		}

		
		public function populateGestureFromDB(key:Number):void
		{
			var stmtSelect:SQLStatement = new SQLStatement();
            stmtSelect.sqlConnection =  database.databaseUtilities.getInstance();
            stmtSelect.text =
            	"SELECT Name, NumBlobs, TimeLength FROM Gestures" +
            		" WHERE (GestureID=:GestureInputID)";
			stmtSelect.parameters[":GestureInputID"] = key;
			stmtSelect.execute();
			var results:ArrayCollection = new ArrayCollection(stmtSelect.getResult().data);	
		}

	}
}