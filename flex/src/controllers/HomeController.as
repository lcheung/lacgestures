// ActionScript file
package controllers
{
	import core.DetectionEngine;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TUIO;
	import flash.events.TUIOObject;
	import flash.events.TouchEvent;
	import flash.geom.Point;
	
	import models.Gesture;
	import models.Path;
	import models.TouchPoint;
	
	import mx.collections.ArrayCollection;
	import mx.containers.VBox;
	import mx.controls.Button;
	import mx.controls.Label;
	
	import tools.GraphicsHelper;
	import tools.UIHelper;
	
	import views.HomeView;
	
	public class HomeController
	{
		private var view:HomeView = null;
		
		// helper to draw the graphics onto the gesture pad
		private var graphicsHelper:GraphicsHelper = null;
		
		// possible values are 'idle', 'detecting', 'analyzing'
		private const IDLE_STATE:int = 0;
		private const DETECTING_STATE:int = 1;
		private const ANALYZING_STATE:int = 2;
		private var currentState:int;
		
		// map of blobId to array of paths
		private var currDetection:Array;
		// array of blobIds that are currently touching the surface
		private var activeBlobIds:ArrayCollection = new ArrayCollection();
		
		private var currentGesture:Gesture = null;
		
		public function HomeController():void
		{
			this.view = new HomeView();
			UIHelper.pushView(this.view);
			
			this.currentState = this.IDLE_STATE;
			
			this.graphicsHelper = new GraphicsHelper(this.view.cnvs_gesturePad);
			
			this.showMessageDialog("Use your fingers to create a gesture in the pad below.");
			
			this.attachListeners(); 
		}
		
		private function attachListeners():void
		{
			//attach event listeners
			this.view.cnvs_gesturePad.addEventListener(TouchEvent.MOUSE_DOWN, this.gesturePadTouchDown);
			this.view.cnvs_gesturePad.addEventListener(TouchEvent.MOUSE_UP, this.gesturePadTouchOff);
			this.view.cnvs_gesturePad.addEventListener(Event.ENTER_FRAME, this.gestureDetector);
		}
		
		private function showMessageDialog(text:String):void
		{
			this.view.cnvs_message.removeAllChildren();
			
			var label:Label = new Label();
			label.text = text;
			label.setStyle("fontSize", "14");
			label.setStyle("color","0xFFFFFF");
			
			this.view.cnvs_message.addChild(label);
		}
		
		private function showSaveDialog():void
		{
			this.view.cnvs_message.removeAllChildren();
			
			var vBox:VBox = new VBox();
			
			var label:Label = new Label();
			label.text = "The gesture does not exist. Do you want to create it?";
			label.setStyle("fontSize", "14");
			label.setStyle("color","0xFFFFFF");
			
			var saveButton:Button = new Button();
			saveButton.label = "Save Gesture!";
			saveButton.addEventListener(MouseEvent.CLICK, this.saveGesture);
			saveButton.addEventListener(TouchEvent.CLICK, this.saveGesture);
			
			
			vBox.addChild(label);
			vBox.addChild(saveButton);
			this.view.cnvs_message.addChild(vBox);
		}
		
		private function saveGesture(e:Event):void
		{
			this.currentGesture.storeInDB();
			this.showMessageDialog("Gesture saved!");
			
		}
		
		// Checks whether a point is out of bounds (off the gesture pad)
		private function isGestureBlobOutOfBounds(globalX:int, globalY:int):Boolean
		{
			var local:Point = this.view.cnvs_gesturePad.globalToLocal(new Point(globalX, globalY));
			if (local.x < 0 || local.x > this.view.cnvs_gesturePad.width 
					|| local.y < 0 || local.y > this.view.cnvs_gesturePad.height) {
				return true;	
			}	
			return false;
		}
		
		private function startDetecting():void
		{
			this.currentState = this.DETECTING_STATE;
			
			this.currDetection = new Array();
		
			this.graphicsHelper.clearCanvas();
		
			this.showMessageDialog("Detecting gesture in progress...");
		}
			
		private function finishDetecting():void
		{
			this.currentState = this.ANALYZING_STATE;
			
			this.showMessageDialog("Analyzing gesture...");
			
			var detectedGesture:Gesture = new Gesture();
			this.currentGesture = detectedGesture;
			
			for each(var path:Path in this.currDetection) {
				detectedGesture.getPaths().addItem(path);
			}
			
			//perform analysis on gesture so that can be stored too
			DetectionEngine.prepareGesture(detectedGesture);
			
			var matchedGesture:Gesture = DetectionEngine.matchGesture(detectedGesture);
			
			if (matchedGesture != null) {
				// match has been found
				this.showMessageDialog("Gesture Found!");
				
				// draw the gesture
				this.graphicsHelper.drawGesture(matchedGesture);
			} else {
				// If no match was found, ask if they want to save the new one
				this.showSaveDialog();
			}	 
			
			this.currentState = this.IDLE_STATE;
		}
		
		private function gestureDetector(e:Event):void
		{		
			if (this.currentState == this.DETECTING_STATE) {
				for each(var blobId:Number in this.activeBlobIds) {
					
					// get the tuioObject for this blobId
					var tuioObj:TUIOObject = TUIO.getObjectById(blobId);
					
					if (tuioObj != null) {
						// make sure the gesture is not out of bounds
						if (this.isGestureBlobOutOfBounds(tuioObj.x, tuioObj.y) == true) {
							// gesture has gone out of bounds, handle it
							this.gestureOutOfBounds();								
						} else {
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
							
							// Update the graphics on the gesture pad
							if (this.currDetection[blobId].getPoints().length > 1) {
								// get the previous touch point
								var prevTouchPoint:TouchPoint = this.currDetection[blobId].getPoints().getItemAt(
									this.currDetection[blobId].getPoints().length-2
								);
								
								// create the start and end points, convert the global coordinates to local
								var start:Point = prevTouchPoint.toPoint();
								start = this.graphicsHelper.globalToLocal(start);
								var end:Point = touchPoint.toPoint();
								end = this.graphicsHelper.globalToLocal(end);
								
								this.graphicsHelper.drawLine(start, end, 8, 0xffffff);		
							}
						}
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
			if (this.currentState == this.IDLE_STATE) {
				this.startDetecting();
			}
		}
		
		// triggered when a finger is lifted off the gesture pad
		private function gesturePadTouchOff(e:TouchEvent):void
		{
			if (this.activeBlobIds.contains(e.ID) == true) {
				this.activeBlobIds.removeItemAt(
					this.activeBlobIds.getItemIndex(e.ID)
				);
				
				// finish detecting when no more fingers are on
				// the gesture pad
				if (this.currentState == this.DETECTING_STATE && this.activeBlobIds.length == 0) {
					this.finishDetecting();
				}
			}		
		}
		
		private function gestureOutOfBounds():void
		{
			// when a finger has gone out of bounds, we end the detection.
			this.activeBlobIds.removeAll();
			this.finishDetecting();
		}
	}
}
