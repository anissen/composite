package examples;

import Composite;

@:structInit
class Position {
	public var x: Float;
	public var y: Float;
	public function toString() {
		return 'Position { x: $x, y: $y }';
	}
}

@:structInit
class Velocity {
	public var x: Float;
	public var y: Float;
	public function toString() {
		return 'Position { x: $x, y: $y }';
	}
}

final Velocity_id = 10;
final Position_id = 20;
final Player_id = 30;

function main() {
	final context = new Context();
	context.addEntity(Player_id, 'Player');
	context.addComponent(Player_id, Velocity_id, ({ x: 1, y: 0 }: Velocity));
	context.addComponent(Player_id, Position_id, ({ x: 3, y: 7 }: Position));

	context.addEntity(Player_id + 1, 'Player 2');
	context.addComponent(Player_id + 1, Position_id, ({ x: 2, y: 2 }: Position));
	context.addComponent(Player_id + 1, Velocity_id, ({ x: 1, y: 7 }: Velocity));

	context.addEntity(Player_id + 2, 'Player 3');
	context.addComponent(Player_id + 2, Velocity_id, ({ x: 1, y: 0 }: Velocity));
	context.addComponent(Player_id + 2, Position_id, ({ x: 3, y: 3 }: Position));

	context.addSystem([Position_id, Velocity_id], (components) -> {
		final position: Array<Position> = components[0];
		final velocity: Array<Velocity> = components[1];
		for (i in 0...position.length) {
			position[i].x += velocity[i].x;
			position[i].y += velocity[i].y;
		}
	}, 'MoveSystem');

	context.query([Position_id], (components) -> {
		final position: Array<Position> = components[0];
		for (pos in position) {
			trace(pos);
		}
	});
	
	context.step();

	context.query([Position_id], (components) -> {
		final position: Array<Position> = components[0];
		for (pos in position) {
			trace(pos);
		}
	});
}