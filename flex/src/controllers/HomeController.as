// ActionScript file
package controllers
{
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TUIO;
	import flash.events.TUIOObject;
	import flash.events.TouchEvent;
	
	import models.Gesture;
	import models.Path;
	import models.TouchPoint;
	
	import mx.collections.ArrayCollection;
	import mx.containers.VBox;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.Label;
	
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
			Alert.show("saved");
		}
		
		private function startDetecting():void
		{
			this.currDetection = new Array();
			this.isDetecting = true;
			
			this.showMessageDialog("Detecting gesture in progress...");
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
				this.showMessageDialog("Gesture Found!");
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
			
			var curPt:Point = this.view.cnvs_gesturePad.globalToLocal(new Point(e.stageX, e.stageY));
			var circle:Sprite = new Sprite(); 
        
        	circle.graphics.beginFill(0xFFFFFF);
        	circle.graphics.drawCircle(curPt.x, curPt.y, 40);
        	
			this.view.cnvs_gesturePad.addChild(circle);
			
			
			
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
