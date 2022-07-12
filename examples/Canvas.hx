package examples;

#if js
import js.Browser;
import js.Browser.document;
import js.html.CanvasRenderingContext2D;

inline function main() {
    final canvas = document.createCanvasElement();
    canvas.width = 400;
    canvas.height = 400;
    document.body.appendChild(canvas);

    init();
    
    final context = new Composite.Context();

    final ctx = canvas.getContext2d();
    function animate(time: Float) {
        draw(ctx);
        Browser.window.requestAnimationFrame(animate);
        context.step();
    }
    Browser.window.requestAnimationFrame(animate);

    // -------------------------------------------------------------------------
    // Setup ECS
    // -------------------------------------------------------------------------

    canvas.onclick = (event -> {
        final e = context.createEntity('Entity');
        context.addComponent(e, ({ x: -1 + 2 * Math.random(), y: -1 + 2 * Math.random() }: Velocity));
        context.addComponent(e, ({ x: event.clientX, y: event.clientY }: Position));
    });

    context.addSystem(Group([Include(Position.ID), Include(Velocity.ID)]), (components) -> {
		final position: Array<Position> = components[0];
		final velocity: Array<Velocity> = components[1];
		for (i in 0...position.length) {
			position[i].x += velocity[i].x;
			position[i].y += velocity[i].y;
		}
	}, 'MoveSystem');
    
    context.addSystem(Include(Position.ID), (components) -> {
        ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
        // ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height);
    
        ctx.fillStyle = '#ff0000';
        ctx.strokeStyle = 'rgba(0, 153, 255)';

		final position: Array<Position> = components[0];
        final radius = 5.0;
		for (pos in position) {
            ctx.beginPath();
            ctx.arc(pos.x, pos.y, radius, 0, Math.PI * 2);
            ctx.stroke();
		}
	}, 'RenderSystem');
}

@:structInit
final class Position implements Composite.Component {
	public var x: Float;
	public var y: Float;
	public function toString() {
		return 'Position { x: $x, y: $y }';
	}
}

@:structInit
final class Velocity implements Composite.Component {
	public var x: Float;
	public var y: Float;
	public function toString() {
		return 'Velocity { x: $x, y: $y }';
	}
}

inline function init() {
    // placeholder
    
}

function draw(ctx: CanvasRenderingContext2D) {
    // ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
    // ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height);
    
    // ctx.fillStyle = '#ff0000';
    // ctx.strokeStyle = 'rgba(0, 153, 255, 0.4)';

    // ctx.arc(x, y, radius, 0, Math.PI * 2);
    // ctx.lineWidth = 5;
    // ctx.beginPath();
    // ctx.moveTo(20, 40);
    // ctx.lineTo(200, 100 + Math.random() * 100);
    // ctx.stroke();
}
#end