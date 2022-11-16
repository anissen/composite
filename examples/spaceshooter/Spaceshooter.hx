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

@:structInit
final class CanShoot implements Composite.Component {
    public var shoot_cooldown: Float;
    public var time_left: Float;
}

final context = new Composite.Context();
var entityCount = 0;
final width = 600;
final height = 600;
final moveSpeed = 500.0;
final turnSpeed = 1.0;
final shootSpeed = 250.0;
final keysPressed = new Map<String, Bool>();
var delta = 0.0;

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
        delta = (time - timeAtLastUpdate) / 1000.0;
        timeAtLastUpdate = time;
        handleInput();
        update();
        draw(context, ctx);
        Browser.window.requestAnimationFrame(animate);
    }
    Browser.window.requestAnimationFrame(animate);

    // -------------------------------------------------------------------------
    // Setup ECS
    // -------------------------------------------------------------------------

    createPlayer({x: width / 2, y: height - 100});
    // createPlayer({x: width / 2 + 100, y: height - 200});

    Browser.window.setInterval(() -> {
        createEnemy();
    }, 3000);

    Browser.window.onkeydown = (event -> {
        keysPressed[event.key] = true;
        // event.preventDefault();
    });
    Browser.window.onkeyup = (event -> {
        keysPressed[event.key] = false;
        // event.preventDefault();
    });
}

inline function init() {
    // placeholder
}

function update() {
    shootX(context.getEntitiesWithComponents(Group([Include(CanShoot.ID), Exclude(Player.ID)])));

    // update positions from velocities
    context.query(Group([Include(Position.ID), Include(Velocity.ID), Include(SquareRendering.ID)]), (components) -> {
        final position: Array<Position> = components[0];
        final velocity: Array<Velocity> = components[1];
        final square: Array<SquareRendering> = components[2];
        for (i in 0...position.length) {
            position[i].x += velocity[i].x * delta;
            position[i].y += velocity[i].y * delta;
            if (position[i].x < 0 || position[i].x > width) {
                velocity[i].x = -velocity[i].x;
                square[i].turns = Math.atan2(velocity[i].y, velocity[i].x) / (Math.PI * 2);
            }
            if (position[i].y < 0 || position[i].y > height) {
                velocity[i].y = -velocity[i].y;
                square[i].turns = Math.atan2(velocity[i].y, velocity[i].x) / (Math.PI * 2);
            }
        }
    });
    context.query(Group([Include(Position.ID), Include(Velocity.ID), Exclude(SquareRendering.ID)]), (components) -> {
        final position: Array<Position> = components[0];
        final velocity: Array<Velocity> = components[1];
        for (i in 0...position.length) {
            position[i].x += velocity[i].x * delta;
            position[i].y += velocity[i].y * delta;
            if (position[i].x < 0 || position[i].x > width) {
                velocity[i].x = -velocity[i].x;
            }
            if (position[i].y < 0 || position[i].y > height) {
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
            tail.time_left -= delta;
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

    // check for bullet vs. ship collisions
    // context.queryEach(Group([Include(Position.ID), Include(CircleRendering.ID)]), (components) -> {
    //     context.queryEach(Group([Include(Position.ID), Include(SquareRendering.ID)]), (components2) -> {
    //         final pos1: Position = components[0];
    //         final circle: CircleRendering = components[1];
    //         final pos2: Position = components2[0];
    //         final square: SquareRendering = components2[1];
    //         if (Math.sqrt(Math.pow(pos1.x - pos2.x, 2) + Math.pow(pos1.y - pos2.y, 2)) < circle.radius + square.size / 2) {
    //             trace('dead!');
    //         }
    //     });
    // });
}

function createPlayer(pos: Position) {
    final player = context.createEntity('Player');
    context.addComponent(player, ({}: Player));
    context.addComponent(player, pos);
    context.addComponent(player, ({size: 20, turns: -1 / 4}: SquareRendering));
    context.addComponent(player, ({color: '#' + StringTools.hex(Math.floor(Math.random() * 16777215))}: Color));
    context.addComponent(player, ({shoot_cooldown: 0.01, time_left: 0.2}: CanShoot));
}

function createEnemy() {
    final enemy = context.createEntity('Enemy');
    context.addComponent(enemy, ({x: Math.random() * width, y: 50}: Position));
    final turns = Math.random();
    final angle = turns * Math.PI * 2;
    context.addComponent(enemy, ({size: 40, turns: turns}: SquareRendering));
    context.addComponent(enemy, ({x: Math.cos(angle) * 50, y: Math.sin(angle) * 50}: Velocity));
    context.addComponent(enemy, ({color: '#' + StringTools.hex(Math.floor(Math.random() * 16777215))}: Color));
    context.addComponent(enemy, ({shoot_cooldown: 2.0, time_left: 5.0}: CanShoot));

    // Browser.window.setInterval(() -> {
    //     shootX([enemy]);
    // }, 3000);
}

function handleInput() {
    for (key => pressed in keysPressed) {
        if (!pressed) continue;
        switch key {
            case 'ArrowUp': move(moveSpeed);
            case 'ArrowDown': move(-moveSpeed);
            case 'ArrowRight': turn(turnSpeed);
            case 'ArrowLeft': turn(-turnSpeed);
            case ' ': shoot();
            case 'r':
                trace('reset');
                keysPressed.clear();
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
            case _:
        }
    }
}

function move(speed: Float) {
    context.queryEach(Group([Include(Player.ID), Include(Position.ID), Include(SquareRendering.ID)]), (components) -> {
        final pos: Position = components[1];
        final square: SquareRendering = components[2];
        final size = square.size;
        final angle = square.turns * Math.PI * 2;
        pos.x += Math.cos(angle) * speed * delta;
        pos.y += Math.sin(angle) * speed * delta;
        if (pos.x < size / 2) pos.x = size / 2;
        if (pos.x > width - size / 2) pos.x = width - size / 2;
        if (pos.y < size / 2) pos.y = size / 2;
        if (pos.y > height - size / 2) pos.y = height - size / 2;
    });
}

function turn(speed: Float) {
    context.queryEach(Group([Include(Player.ID), Include(SquareRendering.ID)]), (components) -> {
        final square: SquareRendering = components[1];
        square.turns += speed * delta;
    });
}

function shoot() {
    shootX(context.getEntitiesWithComponents(Group([Include(Player.ID), Include(CanShoot.ID)])));
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
        final canShoot: CanShoot = context.getComponent(e, CanShoot.ID);
        canShoot.time_left -= delta;
        if (canShoot.time_left > 0) continue;

        canShoot.time_left = canShoot.shoot_cooldown;

        final pos: Position = context.getComponent(e, Position.ID);
        final square: SquareRendering = context.getComponent(e, SquareRendering.ID);
        final size = square.size;
        final angle = square.turns * Math.PI * 2;

        final e = context.createEntity('shot entity ' + entityCount++);
        context.addComponent(e, ({x: pos.x + Math.cos(angle) * size, y: pos.y + Math.sin(angle) * size}: Position));
        context.addComponent(e, ({x: Math.cos(angle) * shootSpeed, y: Math.sin(angle) * shootSpeed}: Velocity));
        context.addComponent(e, ({color: '#' + StringTools.hex(Math.floor(Math.random() * 16777215))}: Color));
        context.addComponent(e, ({radius: 5 + Math.random() * 5}: CircleRendering));
        context.addComponent(e, ({length: 10 + Math.floor(Math.random() * 10), positions: [], time_left: 0}: Tail));
    }
}

function draw(context: Composite.Context, ctx: CanvasRenderingContext2D) {
    ctx.fillStyle = 'white';
    ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height);

    // render tail
    context.queryEach(Group([Include(Tail.ID), Include(Color.ID)]), (components) -> {
        final tail: Tail = components[0];
        final color: Color = components[1];

        ctx.fillStyle = color.color;
        for (pos in tail.positions) {
            ctx.beginPath();
            ctx.arc(pos.x, pos.y, 2, 0, Math.PI * 2);
            ctx.fill();
        }
    });

    context.queryEach(Group([Include(Position.ID), Include(CircleRendering.ID), Include(Color.ID)]), (components) -> {
        final pos: Position = components[0];
        final circle: CircleRendering = components[1];
        final color: Color = components[2];
        ctx.fillStyle = color.color;
        ctx.beginPath();
        ctx.arc(pos.x, pos.y, circle.radius, 0, Math.PI * 2);
        ctx.fill();
    });

    context.queryEach(Group([Include(Position.ID), Include(SquareRendering.ID), Include(Color.ID)]), (components) -> {
        final pos: Position = components[0];
        final square: SquareRendering = components[1];
        final color: Color = components[2];
        final size = square.size;
        final rotation = square.turns * Math.PI * 2;

        // draw line
        ctx.strokeStyle = 'black';
        ctx.beginPath();
        ctx.moveTo(pos.x, pos.y);
        ctx.lineTo(pos.x + Math.cos(rotation) * (size / 2 + 20), pos.y + Math.sin(rotation) * (size / 2 + 20));
        ctx.stroke();

        // draw square
        ctx.save();
        ctx.translate(pos.x, pos.y);
        ctx.rotate(rotation);
        ctx.translate(-pos.x, -pos.y);

        ctx.fillStyle = color.color;
        ctx.strokeStyle = 'black';
        ctx.beginPath();
        ctx.rect(pos.x - size / 2, pos.y - size / 2, size, size);
        ctx.fill();
        ctx.stroke();

        ctx.restore();
    });
}
#end
