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
		
		public function drawCircle(centerPoint:Point, radius:int, color:uint=0x000000, alpha:int=1):void
		{	
			var circle:Sprite = new Sprite(); 
        
        	circle.graphics.beginFill(color, alpha);
        	circle.graphics.drawCircle(centerPoint.x, centerPoint.y, radius);
        	
        	this.addSpriteToCanvas(circle);
		}
		
		public function drawLine(startPoint:Point, endPoint:Point):void
		{
			var line:Sprite = new Sprite();
			
			line.graphics.lineStyle(1,0xFFFFFF,1);
			line.graphics.moveTo(startPoint.x, endPoint.y);
			line.graphics.lineTo(endPoint.x, endPoint.y);
		}
		
		public function globalToLocal(point:Point):Point
		{
			var pt:Point = this.canvas.globalToLocal(new Point(point.x, point.y));
			return pt;
		}
		
		private function addSpriteToCanvas(sprite:Sprite):void
		{
			var regularObject:UIComponent;
            regularObject = new UIComponent();
            regularObject.addChild(sprite);
        	
			this.canvas.addChild(regularObject);
		}
	}
}