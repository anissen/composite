package examples.spaceshooter;

import haxe.macro.Context;
import Composite.EntityId;
#if js
import js.Browser;
import js.Browser.document;
import js.html.CanvasRenderingContext2D;

@:structInit
final class Player implements Composite.Component {}

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
    public var turns: Float;
}

@:structInit
final class Tail implements Composite.Component {
    public var length: Int;
    public var positions: Array<{x: Float, y: Float}>;
    public var time_left: Float;
}

final context = new Composite.Context();
var entityCount = 0;
final width = 600;
final height = 600;

inline function main() {
    var timeAtLastUpdate = 0.0;
    final canvas = document.createCanvasElement();
    canvas.width = width;
    canvas.height = height;
    canvas.style.border = "1px solid #4C4E52";
    document.body.appendChild(canvas);

    init();

    final ctx = canvas.getContext2d();
    function animate(time: Float) {
        final delta = (time - timeAtLastUpdate) / 1000.0;
        timeAtLastUpdate = time;
        draw(context, ctx, delta);
        Browser.window.requestAnimationFrame(animate);
    }
    Browser.window.requestAnimationFrame(animate);

    // -------------------------------------------------------------------------
    // Setup ECS
    // -------------------------------------------------------------------------

    createPlayer({x: width / 2, y: height - 100});
    // createPlayer({x: width / 2 + 100, y: height - 200});

    Browser.window.setTimeout(() -> {
        createEnemy();
    }, 3000);

    final moveSpeed = 10;
    final turnSpeed = 0.01;
    Browser.window.onkeydown = (event -> {
        switch event.key {
            case 'ArrowUp': move(moveSpeed);
            case 'ArrowDown': move(-moveSpeed);
            case 'ArrowRight': turn(turnSpeed);
            case 'ArrowLeft': turn(-turnSpeed);
            case ' ': shoot();
            case 'r':
                trace('reset');
                context.clear();
            case 's':
                trace('save');
                final save = context.save();
                // trace(save);
                Browser.window.localStorage.setItem('save', save);
            case 'l':
                trace('load');
                final save = Browser.window.localStorage.getItem('save');
                // trace(save);
                context.clear();
                context.load(save);
            case 'p':
                trace('print');
                context.printArchetypeGraph(context.rootArchetype);
            case _: trace(event);
        }
    });
}

inline function init() {
    // placeholder
}

function createPlayer(pos: Position) {
    final player = context.createEntity('Player');
    context.addComponent(player, ({}: Player));
    context.addComponent(player, pos);
    context.addComponent(player, ({size: 20, turns: -1 / 4}: SquareRendering));
    context.addComponent(player, ({color: '#' + StringTools.hex(Math.floor(Math.random() * 16777215))}: Color));
}

function createEnemy() {
    // trace('create enemy!');
    final enemy = context.createEntity('Enemy');
    context.addComponent(enemy, ({x: Math.random() * width, y: 50}: Position));
    context.addComponent(enemy, ({x: 0, y: 0.5}: Velocity));
    context.addComponent(enemy, ({size: 40, turns: 1 / 4}: SquareRendering));
    context.addComponent(enemy, ({color: '#' + StringTools.hex(Math.floor(Math.random() * 16777215))}: Color));

    Browser.window.setTimeout(() -> {
        shootX([enemy]);
    }, 3000);
}

function move(speed: Float) {
    context.queryEach(Group([Include(Player.ID), Include(Position.ID), Include(SquareRendering.ID)]), (components) -> {
        final pos: Position = components[1];
        final square: SquareRendering = components[2];
        final size = square.size;
        final angle = square.turns * Math.PI * 2;
        // TODO: delta is missing
        pos.x += Math.cos(angle) * speed;
        pos.y += Math.sin(angle) * speed;
        if (pos.x < size / 2) pos.x = size / 2;
        if (pos.x > width - size / 2) pos.x = width - size / 2;
        if (pos.y < size / 2) pos.y = size / 2;
        if (pos.y > height - size / 2) pos.y = height - size / 2;
    });
}

function turn(speed: Float) {
    context.queryEach(Group([Include(Player.ID), Include(SquareRendering.ID)]), (components) -> {
        final square: SquareRendering = components[1];
        square.turns += speed; // TODO: delta is missing
    });
}

function shoot() {
    shootX(context.getEntitiesWithComponents(Include(Player.ID)));
    // context.queryEach(Group([Include(Player.ID), Include(Position.ID), Include(SquareRendering.ID)]), (components) -> {
    //     final e = context.createEntity('shot entity ' + entityCount++);
    //     final pos: Position = components[1];
    //     final square: SquareRendering = components[2];
    //     final size = square.size;
    //     final angle = square.turns * Math.PI * 2;
    //     context.addComponent(e, ({x: pos.x + Math.cos(angle) * size / 2, y: pos.y + Math.sin(angle) * size / 2}: Position));

    //     context.addComponent(e, ({x: Math.cos(angle), y: Math.sin(angle)}: Velocity));
    //     context.addComponent(e, ({color: '#' + StringTools.hex(Math.floor(Math.random() * 16777215))}: Color));
    //     context.addComponent(e, ({radius: 5 + Math.random() * 5}: CircleRendering));
    //     context.addComponent(e, ({length: 10 + Math.floor(Math.random() * 10), positions: [], time_left: 0}: Tail));
    // });
}

function shootX(entities: Array<EntityId>) {
    for (e in entities) {
        final pos: Position = context.getComponent(e, Position.ID);
        final square: SquareRendering = context.getComponent(e, SquareRendering.ID);
        final size = square.size;
        final angle = square.turns * Math.PI * 2;

        final e = context.createEntity('shot entity ' + entityCount++);
        context.addComponent(e, ({x: pos.x + Math.cos(angle) * size / 2, y: pos.y + Math.sin(angle) * size / 2}: Position));
        context.addComponent(e, ({x: Math.cos(angle), y: Math.sin(angle)}: Velocity));
        context.addComponent(e, ({color: '#' + StringTools.hex(Math.floor(Math.random() * 16777215))}: Color));
        context.addComponent(e, ({radius: 5 + Math.random() * 5}: CircleRendering));
        context.addComponent(e, ({length: 10 + Math.floor(Math.random() * 10), positions: [], time_left: 0}: Tail));
    }
}

function draw(context: Composite.Context, ctx: CanvasRenderingContext2D, dt: Float) {
    ctx.fillStyle = 'white';
    ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height);

    // update positions from velocities
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

    // update tail
    context.query(Group([Include(Position.ID), Include(Tail.ID)]), (components) -> {
        final positions: Array<Position> = components[0];
        final tails: Array<Tail> = components[1];
        for (i in 0...positions.length) {
            final tail = tails[i];
            tail.time_left -= dt;
            if (tail.time_left <= 0) {
                tail.time_left = 0.025;
                if (tail.positions.length > tail.length) {
                    tail.positions.shift();
                }
                final pos = positions[i];
                tail.positions.push({x: pos.x, y: pos.y});
            }
        }
    });

    // render tail
    context.query(Group([Include(Tail.ID), Include(Color.ID)]), (components) -> {
        final tails: Array<Tail> = components[0];
        final colors: Array<Color> = components[1];
        for (i in 0...tails.length) {
            final tail = tails[i];
            final color = colors[i].color;

            ctx.fillStyle = color;
            for (tailPos in tail.positions) {
                ctx.beginPath();
                ctx.arc(tailPos.x, tailPos.y, 2, 0, Math.PI * 2);
                ctx.fill();
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
            final rotation = square[i].turns * Math.PI * 2;
            final color = colors[i].color;

            // draw line
            ctx.beginPath();
            ctx.moveTo(pos.x, pos.y);
            ctx.lineTo(pos.x + Math.cos(rotation) * 50, pos.y + Math.sin(rotation) * 50);
            ctx.stroke();

            // draw square
            ctx.save();
            ctx.translate(pos.x, pos.y);
            ctx.rotate(rotation);
            ctx.translate(-pos.x, -pos.y);

            ctx.fillStyle = color;
            ctx.beginPath();
            ctx.rect(pos.x - size / 2, pos.y - size / 2, size, size);
            ctx.fill();

            ctx.restore();

            // ctx.fillStyle = color;
            // ctx.beginPath();
            // ctx.rect(pos.x - size / 2, pos.y - size / 2, size, size);
            // ctx.fill();
        }
    });
}
#end