package tools
{
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import models.Gesture;
	import models.Path;
	
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
		
		public function drawLine(startPoint:Point, endPoint:Point, thickness:int=8, color:uint=0x000000, alpha:int=1):void
		{
			var line:Sprite = new Sprite();
			
			line.graphics.lineStyle(thickness,color,alpha);
			line.graphics.moveTo(startPoint.x, startPoint.y);
			line.graphics.lineTo(endPoint.x, endPoint.y);
			
			this.addSpriteToCanvas(line);
		}
		
		public function drawGesture(gesture:Gesture):void
		{
				// draw the gesture
				for each(var path:Path in gesture.getPaths()) {
					for (var i:int=0; i<path.getPoints().length; i++) {
						
						// first point, we simply draw a circle. After that
						// we begin drawing a line
						if (i==0) {
							var point:Point = path.getPoints().getItemAt(i).toPoint();
							point = this.globalToLocal(point);
							this.drawCircle(point, 16, 0xFF0000);
						} else {
							var prevPoint:Point = path.getPoints().getItemAt(i-1).toPoint();
							prevPoint = this.globalToLocal(prevPoint);
							var currPoint:Point = path.getPoints().getItemAt(i).toPoint();
							currPoint = this.globalToLocal(currPoint);
							
							this.drawLine(prevPoint, currPoint, 8, 0xFF0000, 1);	
						} 
					}
				} 
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