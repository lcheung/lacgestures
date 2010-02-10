package database
{
	import flash.data.SQLConnection;
	import flash.filesystem.File;
	
	import models.Gesture;	
	
	public class databaseUtilities
	{
        private static var sqlLiteGesturesConn:SQLConnection=null;
        
        public static function openDatabase():Boolean
        {  	
        	if (sqlLiteGesturesConn == null)
        	{
	            var file:File;// = new File("C:/Users/Chris/Documents/lac/touchlib/AS3/src/gestures/Database/Gestures.db");
	            file = File.userDirectory.resolvePath("Documents/lacgestures/flex/src//Database/Gestures.db");
	            //"C:/Users/Chris/Documents/lac/touchlib/AS3/src/gestures/Database/Gestures.db";
	            var isDBAccesible:Boolean = file.exists;
	            if (isDBAccesible) {
	            	sqlLiteGesturesConn = new SQLConnection();
	            	sqlLiteGesturesConn.open(file);
	            	trace("SQL Connection Success");
	            	return true;
	            }
	            else{
	            	trace("SQL Connection Unsuccessful");
	            	return false;
	            }
         	}
         	return true;
        }
        
        public static function closeDatabase():void
        {
        	sqlLiteGesturesConn = null;
        }
        
        public static function getInstance():SQLConnection
        {
        	openDatabase();
    		return sqlLiteGesturesConn;
        }
        
        
     
        /*  EXTRA TESTING CODE */
		public static function testGestureDBCreation():void
		{		              
            var newGesture: models.Gesture = new models.Gesture();
            var rowID:Number;
            newGesture.gestureName = "TestGesture";
            newGesture.numBlobs = 2;
            newGesture.timeLength = 14;
					
			rowID = newGesture.storeInDB();	         	
         	trace("The inserted rowID is:", rowID);		
		}
		
		public static function testGestureDBFetch():void
		{
			var newGesture: models.Gesture = new models.Gesture();
			
			newGesture.populateGestureFromDB(1);
						
		}

	}
}