// ActionScript file
package controllers
{
	import core.DetectionEngine;
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
	import views.RecordView;
	
	public class RecordController
	{
		private var view:RecordView = null;
		
		private var isRecording:Boolean;	
		// map of blobId to array of paths
		private var currRecording:Array;
		// array of blobIds that are currently touching the surface
		private var activeBlobIds:ArrayCollection = new ArrayCollection();
		
		public function RecordController():void
		{
			this.view = new RecordView();
			UIHelper.pushView(this.view);
			
			this.attachListeners(); 
		}
		
		private function attachListeners():void
		{
			//attach event listeners
			this.view.cnvs_gesturePad.addEventListener(TouchEvent.MOUSE_DOWN, gesturePadTouchDown);
			this.view.cnvs_gesturePad.addEventListener(TouchEvent.MOUSE_UP, gesturePadTouchOff);
			this.view.cnvs_gesturePad.addEventListener(Event.ENTER_FRAME, gestureRecorder);	
		}
		
		private function startRecording():void
		{
			this.currRecording = new Array();
			this.isRecording = true;
		}
			
		private function finishRecording():void
		{
			this.isRecording = false;
			
			var gesture:Gesture = new Gesture();
			
			// traverse the currRecording to get the paths and move
			// them to the gesture model
			for each(var path:Path in this.currRecording) {
				gesture.getPaths().addItem(path);
			}
			
			//perform analysis on gesture so that can be stored too
			DetectionEngine.prepareGesture(gesture);
			
			// persist to database
			gesture.storeInDB();
			
			Alert.show("Gesture Saved!","Gesture Saved"); 
		}
		
		private function gestureRecorder(e:Event):void
		{

			if (this.isRecording == true) {
				for(var i:Number=0; i<this.activeBlobIds.length; i++) {
					var blobId:Number = Number(this.activeBlobIds.getItemAt(i));
					
					// get the tuioObject for this blobId
					var tuioObj:TUIOObject = TUIO.getObjectById(blobId);
					
					if (tuioObj != null) {
						// if current blobId does not have a path instantiated
						// in the current recording, make one.
						if (this.currRecording[blobId] == null) {
							this.currRecording[blobId] = new Path();
						}
						
						//create the touchpoint object
						var touchPoint:TouchPoint = new TouchPoint();
						touchPoint.setX(tuioObj.x);
						touchPoint.setY(tuioObj.y);
						touchPoint.setTimestamp(new Date().time);
										
						this.currRecording[blobId].getPoints().addItem(touchPoint);
					}
				}
			}
		}
			
		// triggered when a finger is pressed down onto the 
		// gesture pad.
		private function gesturePadTouchDown(e:TouchEvent):void
		{
			this.activeBlobIds.addItem(e.ID);
			
			// start recording once a finger has been pressed down
			if (this.isRecording == false) {
				this.startRecording();
			}
		}
		
		// triggered when a finger is lifted off the gesture pad
		private function gesturePadTouchOff(e:TouchEvent):void
		{
			this.activeBlobIds.removeItemAt(
				this.activeBlobIds.getItemIndex(e.ID)
			);
			
			// finish recording when no more fingers are on
			// the gesture pad
			if (this.activeBlobIds.length == 0) {
				this.finishRecording();
			}
		}
	}
}
