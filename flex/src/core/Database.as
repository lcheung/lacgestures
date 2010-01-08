package core
{
	import flash.data.SQLConnection;
	import flash.filesystem.File;

	public class Database
	{	
		private static var instance:Database;
		
		private var sqlLiteGesturesConn:SQLConnection;
		
		public function Database():void
		{
			this.openDatabase();
		}
		
		public static function getInstance():Database
		{
			if (Database.instance == null) {
				Database.instance = new Database();
			}

			return Database.instance;	
		}
		
		private function openDatabase():void
        {  	
           /* var file:File = new File();
            file.nativePath="/lacgestures/flex/srcC:/Users/Chris/Documents/lac/touchlib/AS3/src/gestures/Database/Gestures.db";
            var isDBAccesible:Boolean = file.exists;
            if (isDBAccesible) {
            	sqlLiteGesturesConn = new SQLConnection();
            	sqlLiteGesturesConn.open(file);
            	trace("SQL Connection Success");
            }
            else{
            	trace("SQL Connection Unsuccessful");
            }*/
        }
        
	}
}