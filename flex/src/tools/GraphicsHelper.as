package tools
{
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import mx.containers.Canvas;
	import mx.core.UIComponent;
	
	public class GraphicsHelper
	{
		private var canvas:Canvas;
		
		public function GraphicsHelper(canvas:Canvas):void
		{
			this.canvas = canvas;	
		}
		
		public function clearCanvas():void
		{
			this.canvas.removeAllChildren();
		}
		
		public function drawCircle(centerPoint:Point, radius:int):void
		{	
			var circle:Sprite = new Sprite(); 
        
        	circle.graphics.beginFill(0xCCCCCC, 1);
        	circle.graphics.drawCircle(centerPoint.x, centerPoint.y, radius);
        	
        	var regularObject:UIComponent;
            regularObject = new UIComponent();
            regularObject.addChild(circle);
        	
			this.canvas.addChild(regularObject);	
		}
		
		public function globalToLocal(point:Point):Point
		{
			var pt:Point = this.canvas.globalToLocal(new Point(point.x, point.y));
			return pt;
		}
	}
}