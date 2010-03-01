// ActionScript file
package controllers
{
	import flash.events.Event;
	import flash.events.TUIO;
	import flash.events.TUIOObject;
	import flash.events.TouchEvent;
	
	import models.Gesture;
	import models.Path;
	import models.TouchPoint;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	
	import tools.UIHelper;
	
	import views.HomeView;
	
	public class HomeController
	{
		private var view:HomeView = null;
		
		private var isDetecting:Boolean;	
		// map of blobId to array of paths
		private var currDetection:Array;
		// array of blobIds that are currently touching the surface
		private var activeBlobIds:ArrayCollection = new ArrayCollection();
		
		public function HomeController():void
		{
			this.view = new HomeView();
			UIHelper.pushView(this.view);
			
			this.attachListeners(); 
		}
		
		private function attachListeners():void
		{
			//attach event listeners
			this.view.cnvs_gesturePad.addEventListener(TouchEvent.MOUSE_DOWN, this.gesturePadTouchDown);
			this.view.cnvs_gesturePad.addEventListener(TouchEvent.MOUSE_UP, this.gesturePadTouchOff);
			this.view.cnvs_gesturePad.addEventListener(Event.ENTER_FRAME, this.gestureDetector);	
		}
		
		private function showSaveDialog():void
		{
			// Ask the user whether they want to save their gesture
			this.view.lbl_message.text = "No such gesture detected. Do you want to create it?";
		}
		
		private function startDetecting():void
		{
			this.currDetection = new Array();
			this.isDetecting = true;
		}
			
		private function finishDetecting():void
		{
			this.isDetecting = false;
			
			var detectedGesture:Gesture = new Gesture();
			
			for each(var path:Path in this.currDetection) {
				detectedGesture.getPaths().addItem(path);
			}
			
			/*
			//perform analysis on gesture so that can be stored too
			DetectionEngine.prepareGesture(detectedGesture);
			
			var matchedGesture:Gesture = DetectionEngine.matchGesture(detectedGesture);
			*/
			
			var matchedGesture:Gesture = null;
			
			if (matchedGesture != null) {
				// match has been found
				Alert.show("Match successful");
			} else {
				// If no match was found, ask if they want to save the new one
				this.showSaveDialog();
			}	 
		}
		
		private function gestureDetector(e:Event):void
		{

			if (this.isDetecting == true) {
				for(var i:Number=0; i<this.activeBlobIds.length; i++) {
					var blobId:Number = Number(this.activeBlobIds.getItemAt(i));
					
					// get the tuioObject for this blobId
					var tuioObj:TUIOObject = TUIO.getObjectById(blobId);
					
					if (tuioObj != null) {
						// if current blobId does not have a path instantiated
						// in the current detection, make one.
						if (this.currDetection[blobId] == null) {
							this.currDetection[blobId] = new Path();
						}
						
						//create the touchpoint object
						var touchPoint:TouchPoint = new TouchPoint();
						touchPoint.setX(tuioObj.x);
						touchPoint.setY(tuioObj.y);
						touchPoint.setTimestamp(new Date().time);
										
						this.currDetection[blobId].getPoints().addItem(touchPoint);
					}
				}
			}
		}
			
		// triggered when a finger is pressed down onto the 
		// gesture pad.
		private function gesturePadTouchDown(e:TouchEvent):void
		{
			this.activeBlobIds.addItem(e.ID);
			
			// start detecting once a finger has been pressed down
			if (this.isDetecting == false) {
				this.startDetecting();
			}
		}
		
		// triggered when a finger is lifted off the gesture pad
		private function gesturePadTouchOff(e:TouchEvent):void
		{
			this.activeBlobIds.removeItemAt(
				this.activeBlobIds.getItemIndex(e.ID)
			);
			
			// finish detecting when no more fingers are on
			// the gesture pad
			if (this.activeBlobIds.length == 0) {
				this.finishDetecting();
			}
		}
	}
}
