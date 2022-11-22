package examples;

import composite.Composite.Context;
import composite.Composite.Component;

@:structInit
final class Position implements Component {
    public var x: Float;
    public var y: Float;

    public function toString() {
        return 'Position { x: $x, y: $y }';
    }
}

@:structInit
final class Velocity implements Component {
    public var x: Float;
    public var y: Float;

    public function toString() {
        return 'Velocity { x: $x, y: $y }';
    }
}

function main() {
    final context = new Context();
    final e1 = context.createEntity('Entity 1');
    context.addComponent(e1, ({x: 1, y: 0}: Velocity));
    context.addComponent(e1, ({x: 3, y: 7}: Position));

    final e2 = context.createEntity('Entity 2');
    context.addComponent(e2, ({x: 2, y: 2}: Position));
    context.addComponent(e2, ({x: 1, y: 7}: Velocity));

    final e3 = context.createEntity('Entity 3');
    context.addComponent(e3, ({x: 1, y: 0}: Velocity));
    context.addComponent(e3, ({x: 3, y: 3}: Position));

    context.queryEach(Include(Position.ID), (entities, components) -> {
        final pos: Position = components[0];
        trace(pos);
    });

    context.queryEach(Group([Include(Position.ID), Include(Velocity.ID)]), (entities, components) -> {
        final pos: Position = components[0];
        final vel: Velocity = components[1];
        pos.x += vel.x;
        pos.y += vel.y;
    });

    trace('----------------------------------------');

    context.queryEach(Group([Include(Position.ID), Include(Velocity.ID)]), (entities, components) -> {
        final pos: Position = components[0];
        trace(pos);
    });
}
