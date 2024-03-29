package examples.spaceshooter;

import composite.*;
import composite.Composite.Component;
import composite.Composite.EntityId;
#if js
import js.Browser;
import js.Browser.document;
import js.html.CanvasRenderingContext2D;

@:structInit
final class Player implements Component {}

@:structInit
final class Position implements Component {
    public var x: Float;
    public var y: Float;
}

@:structInit
final class Velocity implements Component {
    public var x: Float;
    public var y: Float;
}

@:structInit
final class Color implements Component {
    public var color: String;
}

@:structInit
final class CircleRendering implements Component {
    public var radius: Float;
}

@:structInit
final class SquareRendering implements Component {
    public var size: Float;
    public var turns: Float;
}

@:structInit
final class Tail implements Component {
    public var length: Int;
    public var positions: Array<{x: Float, y: Float}>;
    public var time_left: Float;
}

@:structInit
final class CanShoot implements Component {
    public var shoot_cooldown: Float;
    public var time_left: Float;
    public var auto_shoot: Bool;
}

final context = new Composite.Context();
final width = 600;
final height = 600;
final moveSpeed = 5000.0;
final moveDampening = 0.1;
final turnSpeed = 0.8;
final shootSpeed = 150.0;
final keysPressed = new Map<String, Bool>();
var paused = false;
var delta = 0.0;

// enemy spawn properties
final enemyCoolDown_s = 3.0;
var enemyTimeLeft_s = 1.0;

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
        if (!paused) {
            handleInput();
            update();
            draw(context, ctx);
        }
        Browser.window.requestAnimationFrame(animate);
    }
    Browser.window.requestAnimationFrame(animate);

    Browser.window.onblur = (event -> paused = true);
    Browser.window.onfocus = (event -> paused = false);
    Browser.window.onkeydown = (event -> keysPressed[event.key] = true);
    Browser.window.onkeyup = (event -> keysPressed[event.key] = false);
}

inline function init() {
    // TODO: Initialize timers
    createPlayer({x: width / 2, y: height - 100});
}

function update() {
    enemyTimeLeft_s -= delta;
    if (enemyTimeLeft_s < 0) {
        enemyTimeLeft_s = enemyCoolDown_s;
        createEnemy();
    }

    // reduce shoot timer, shoot if not possible and not the Player
    context.queryEach(Group([Include(CanShoot.ID)]), (entity, components) -> {
        final canShoot: CanShoot = components[0];
        canShoot.time_left -= delta;
        if (canShoot.time_left > 0) return;

        if (canShoot.auto_shoot) {
            shoot(entity);
        }
    });

    // update positions from velocities
    context.queryEach(Group([Include(Position.ID), Include(Velocity.ID)]), (entity, components) -> {
        final pos: Position = components[0];
        final vel: Velocity = components[1];
        pos.x += vel.x * delta;
        pos.y += vel.y * delta;
        var bounced = false;
        if (pos.x < 0 || pos.x > width) {
            vel.x = -vel.x;
            bounced = true;
        }
        if (pos.y < 0 || pos.y > height) {
            vel.y = -vel.y;
            bounced = true;
        }
        if (bounced && context.hasComponent(entity, SquareRendering.ID)) {
            final square: SquareRendering = context.getComponent(entity, SquareRendering.ID);
            square.turns = Math.atan2(vel.y, vel.x) / (Math.PI * 2);
        }
    });

    // dampen player speed
    context.queryEach(Group([Include(Player.ID), Include(Velocity.ID), Include(SquareRendering.ID)]), (entity, components) -> {
        final vel: Velocity = components[1];
        final damp = (1.0 - moveDampening) * (1.0 - delta);
        vel.x *= damp;
        vel.y *= damp;
    });

    // update tail
    context.queryEach(Group([Include(Position.ID), Include(Tail.ID)]), (entity, components) -> {
        final pos: Position = components[0];
        final tail: Tail = components[1];
        tail.time_left -= delta;
        if (tail.time_left <= 0) {
            tail.time_left = 0.025;
            if (tail.positions.length > tail.length) {
                tail.positions.shift();
            }
            tail.positions.push({x: pos.x, y: pos.y});
        }
    });

    // check for bullet vs. ship collisions
    context.queryEach(Group([Include(Position.ID), Include(CircleRendering.ID)]), (entity, components) -> {
        context.queryEach(Group([Include(Position.ID), Include(SquareRendering.ID)]), (entity2, components2) -> {
            final pos1: Position = components[0];
            final circle: CircleRendering = components[1];
            final pos2: Position = components2[0];
            final square: SquareRendering = components2[1];
            if (Math.sqrt(Math.pow(pos1.x - pos2.x, 2) + Math.pow(pos1.y - pos2.y, 2)) < circle.radius + square.size / 2) {
                trace('entity $entity2 is dead!');
                context.destroyEntity(entity2);
                context.destroyEntity(entity);
            }
        });
    });
}

function createPlayer(pos: Position) {
    final player = context.createEntity('Player');
    context.addComponents(player, [
        ({}: Player),
        pos,
        ({x: 0, y: 0}: Velocity),
        ({size: 20, turns: -1 / 4}: SquareRendering),
        ({color: '#' + StringTools.hex(Math.floor(Math.random() * 16777215))}: Color),
        ({shoot_cooldown: 0.5, time_left: 0.0, auto_shoot: false}: CanShoot)
    ]);
}

function createEnemy() {
    final enemy = context.createEntity('Enemy');
    final turns = Math.random();
    final angle = turns * Math.PI * 2;
    context.addComponents(enemy, [
        ({x: Math.random() * width, y: 50}: Position),
        ({size: 40, turns: turns}: SquareRendering),
        ({x: Math.cos(angle) * 50, y: Math.sin(angle) * 50}: Velocity),
        ({color: '#' + StringTools.hex(Math.floor(Math.random() * 16777215))}: Color),
        ({shoot_cooldown: 2.0, time_left: 3.0, auto_shoot: true}: CanShoot)
    ]);
}

function handleInput() {
    for (key => pressed in keysPressed) {
        if (!pressed) continue;
        switch key {
            case 'ArrowUp': move(moveSpeed);
            case 'ArrowDown': move(-moveSpeed);
            case 'ArrowRight': turn(turnSpeed);
            case 'ArrowLeft': turn(-turnSpeed);
            case ' ':
                for (e in context.getEntitiesWithComponents(Group([
                    Include(Player.ID),
                    Include(CanShoot.ID),
                    Include(Position.ID),
                    Include(Velocity.ID),
                    Include(SquareRendering.ID)
                ]))) {
                    shoot(e);
                }
            case 'e': createEnemy();
            case 'r':
                trace('reset');
                keysPressed.clear();
                context.clear();
                init();
            case 's':
                trace('save');
                final save = context.save();
                Browser.window.localStorage.setItem('save', save);
            case 'l':
                trace('load');
                final save = Browser.window.localStorage.getItem('save');
                context.clear();
                context.load(save);
            case 'p': context.printArchetypeGraph(context.rootArchetype);
            case _:
        }
    }
}

function move(speed: Float) {
    context.queryEach(Group([Include(Player.ID), Include(Velocity.ID), Include(SquareRendering.ID)]), (entity, components) -> {
        final vel: Velocity = components[1];
        final square: SquareRendering = components[2];
        final angle = square.turns * Math.PI * 2;
        vel.x += Math.cos(angle) * speed * delta;
        vel.y += Math.sin(angle) * speed * delta;
    });
}

function turn(speed: Float) {
    context.queryEach(Group([Include(Player.ID), Include(SquareRendering.ID)]), (entity, components) -> {
        final square: SquareRendering = components[1];
        square.turns += speed * delta;
    });
}

function shoot(entity: EntityId) {
    final canShoot: CanShoot = context.getComponent(entity, CanShoot.ID);
    if (canShoot.time_left > 0) return;
    canShoot.time_left = canShoot.shoot_cooldown;

    final pos: Position = context.getComponent(entity, Position.ID);
    final entityVel: Velocity = context.getComponent(entity, Velocity.ID);
    final velMagnitude = Math.sqrt(entityVel.x * entityVel.x + entityVel.y * entityVel.y);
    final square: SquareRendering = context.getComponent(entity, SquareRendering.ID);
    final size = square.size;
    final angle = square.turns * Math.PI * 2;

    final shotEntity = context.createEntity('Shot entity');
    context.addComponents(shotEntity, [
        ({
            x: pos.x + Math.cos(angle) * size,
            y: pos.y + Math.sin(angle) * size,
        }: Position),
        ({
            x: Math.cos(angle) * (shootSpeed + Math.max(velMagnitude, 10)),
            y: Math.sin(angle) * (shootSpeed + Math.max(velMagnitude, 10)),
        }: Velocity),
        ({
            color: '#' + StringTools.hex(Math.floor(Math.random() * 16777215))
        }: Color),
        ({
            radius: 5 + Math.random() * 5
        }: CircleRendering),
        ({
            length: 10 + Math.floor(Math.random() * 10),
            positions: [],
            time_left: 0,
        }: Tail)
    ]);
}

function draw(context: composite.Composite.Context, ctx: CanvasRenderingContext2D) {
    ctx.fillStyle = 'white';
    ctx.fillRect(0, 0, ctx.canvas.width, ctx.canvas.height);

    // render tail
    context.queryEach(Group([Include(Tail.ID), Include(Color.ID)]), (entity, components) -> {
        final tail: Tail = components[0];
        final color: Color = components[1];

        ctx.fillStyle = color.color;
        for (pos in tail.positions) {
            ctx.beginPath();
            ctx.arc(pos.x, pos.y, 2, 0, Math.PI * 2);
            ctx.fill();
        }
    });

    // render circles
    context.queryEach(Group([Include(Position.ID), Include(CircleRendering.ID), Include(Color.ID)]), (entity, components) -> {
        final pos: Position = components[0];
        final circle: CircleRendering = components[1];
        final color: Color = components[2];
        ctx.fillStyle = color.color;
        ctx.beginPath();
        ctx.arc(pos.x, pos.y, circle.radius, 0, Math.PI * 2);
        ctx.fill();
    });

    // render squares
    context.queryEach(Group([Include(Position.ID), Include(SquareRendering.ID), Include(Color.ID)]), (entity, components) -> {
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
