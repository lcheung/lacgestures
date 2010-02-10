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
			this.view.btn_recGestures.addEventListener(TouchEvent.CLICK, recordGesturesPressed);
			this.view.btn_recGestures.addEventListener(MouseEvent.CLICK, recordGesturesPressed);	
		}
		
		private function recordGesturesPressed(e:Event):void
		{
			var recController:RecordController = new RecordController();
		}
	}
}