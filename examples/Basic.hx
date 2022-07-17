package examples;

import Composite;

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
	context.addComponent(e1, ({ x: 1, y: 0 }: Velocity));
	context.addComponent(e1, ({ x: 3, y: 7 }: Position));

	final e2 = context.createEntity('Entity 2');
	context.addComponent(e2, ({ x: 2, y: 2 }: Position));
	context.addComponent(e2, ({ x: 1, y: 7 }: Velocity));

	final e3 = context.createEntity('Entity 3');
	context.addComponent(e3, ({ x: 1, y: 0 }: Velocity));
	context.addComponent(e3, ({ x: 3, y: 3 }: Position));


	// TODO: I would like to be able to do this:
	/*
	context.addSystem([Position_id, Velocity_id], (position, velocity) -> {
		position.x += velocity.x;
		position.y += velocity.y;
	});
	*/

	// context.addSystemEx([Velocity], (components) -> {
	// 	trace(components);
	// });

	context.query(Include(Position.ID), (components) -> {
		final position: Array<Position> = components[0];
		for (pos in position) {
			trace(pos);
		}
	});
	
	context.query(Group([Include(Position.ID), Include(Velocity.ID)]), (components) -> {
		final position: Array<Position> = components[0];
		final velocity: Array<Velocity> = components[1];
		for (i in 0...position.length) {
			position[i].x += velocity[i].x;
			position[i].y += velocity[i].y;
		}
	});
	
	trace('----------------------------------------');

	context.query(Group([Include(Position.ID), Include(Velocity.ID)]), (components) -> {
		final position: Array<Position> = components[0];
		for (pos in position) {
			trace(pos);
		}
	});
}