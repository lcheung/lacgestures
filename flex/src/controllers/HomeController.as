package controllers
{
	import tools.UIHelper;
	import views.HomeView;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TouchEvent;
	
	public class HomeController
	{
		private var view:HomeView = null;
		
		public function HomeController():void
		{
			this.view = new HomeView();
			UIHelper.pushView(this.view);
			
			this.attachListeners();	
		}
		
		private function attachListeners():void
		{
			this.view.btn_recordGestures.addEventListener(TouchEvent.CLICK, recordGesturesPressed);
			this.view.btn_recordGestures.addEventListener(MouseEvent.CLICK, recordGesturesPressed);
			this.view.btn_detectGestures.addEventListener(TouchEvent.CLICK, detectGesturesPressed);
			this.view.btn_detectGestures.addEventListener(MouseEvent.CLICK, detectGesturesPressed);	
		}
		
		private function recordGesturesPressed(e:Event):void
		{
			var recordController:RecordController = new RecordController();
		}
		
		private function detectGesturesPressed(e:Event):void
		{
			var detectController:DetectController = new DetectController();
		}
	}
}