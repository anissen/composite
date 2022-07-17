package examples;

#if js
import js.Browser;
import js.Browser.document;
import js.html.CanvasRenderingContext2D;

@:structInit
final class Position implements Composite.Component {
    public var x: Float;
    public var y: Float;
}

@:structInit
final class Velocity implements Composite.Component {
    public var x: Float;
    public var y: Float;
}

@:structInit
final class Color implements Composite.Component {
    public var color: String;
}

@:structInit
final class CircleRendering implements Composite.Component {
    public var radius: Float;
}

@:structInit
final class SquareRendering implements Composite.Component {
    public var size: Float;
    public var rotation: Float;
}

inline function main() {
    final canvas = document.createCanvasElement();
    canvas.width = 800;
    canvas.height = 800;
    document.body.appendChild(canvas);

    init();
    
    final context = new Composite.Context();

    final ctx = canvas.getContext2d();
    function animate(time: Float) {
        draw(context, ctx);
        Browser.window.requestAnimationFrame(animate);
    }
    Browser.window.requestAnimationFrame(animate);

    // -------------------------------------------------------------------------
    // Setup ECS
    // -------------------------------------------------------------------------

    canvas.onclick = (event -> {
        final e = context.createEntity('Entity');
        final square = Math.random() < 0.5;
        final speed = square ? 1.0 : 3.0;
        context.addComponent(e, ({ x: -speed + 2 * speed * Math.random(), y: -speed + 2 * speed * Math.random() }: Velocity));
        context.addComponent(e, ({ x: event.clientX, y: event.clientY }: Position));
        context.addComponent(e, ({ color: '#' + StringTools.hex(Math.floor(Math.random() * 16777215)) }: Color));
        if (square) {
            context.addComponent(e, ({ size: 10 + Math.random() * 10, rotation: Math.PI * 2 * Math.random() }: SquareRendering));
        } else {
            context.addComponent(e, ({ radius: 5 + Math.random() * 5 }: CircleRendering));
        }
    });

    Browser.window.onkeydown = (event -> {
        switch event.key {
            case 'r':
                trace('reset');
                //context.clear();
            case 's':
                trace('save');
                final save = context.save();
                trace(save);
                Browser.window.localStorage.setItem('save', save);
            case 'l':
                trace('load');
                final save = Browser.window.localStorage.getItem('save');
                trace(save);
                context.load(save);
            case 'p':
                trace('print');
                context.printArchetypeGraph(context.rootArchetype);
            case _:
        }
    });
}

inline function init() {
    // placeholder
    
}

function draw(context: Composite.Context, ctx: CanvasRenderingContext2D) {
    ctx.fillStyle = 'rgb(75, 220, 255)';
    ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height);

    context.query(Group([Include(Position.ID), Include(Velocity.ID)]), (components) -> {
        final position: Array<Position> = components[0];
        final velocity: Array<Velocity> = components[1];
        for (i in 0...position.length) {
            position[i].x += velocity[i].x;
            position[i].y += velocity[i].y;
            if (position[i].x < 0 || position[i].x > ctx.canvas.width) {
                velocity[i].x = -velocity[i].x;
            }
            if (position[i].y < 0 || position[i].y > ctx.canvas.height) {
                velocity[i].y = -velocity[i].y;
            }
        }
    });
    
    context.query(Group([Include(Position.ID), Include(CircleRendering.ID), Include(Color.ID)]), (components) -> {
        final position: Array<Position> = components[0];
        final circle: Array<CircleRendering> = components[1];
        final colors: Array<Color> = components[2];
        for (i in 0...position.length) {
            final pos = position[i];
            final radius = circle[i].radius;
            final color = colors[i].color;
            ctx.fillStyle = color;
            ctx.beginPath();
            ctx.arc(pos.x, pos.y, radius, 0, Math.PI * 2);
            ctx.fill();
        }
    });
    
    context.query(Group([Include(Position.ID), Include(SquareRendering.ID), Include(Color.ID)]), (components) -> {
        final position: Array<Position> = components[0];
        final square: Array<SquareRendering> = components[1];
        final colors: Array<Color> = components[2];
        for (i in 0...position.length) {
            final pos = position[i];
            final size = square[i].size;
            final rotation = square[i].rotation;
            final color = colors[i].color;

            ctx.save();
            ctx.translate(pos.x + size / 2, pos.y + size / 2);
            ctx.rotate(rotation);
            ctx.translate(-(pos.x + size / 2), -(pos.y + size / 2));
            
            ctx.fillStyle = color;
            ctx.beginPath();
            ctx.rect(pos.x, pos.y, size, size);
            ctx.fill();

            ctx.restore();
        }
    });
}
#end