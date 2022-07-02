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
class Health {
	public var value: Int;
	public function toString() {
		return 'Health { value: $value }';
	}
}

@:structInit
class Faction {
	public var color: String;
	public function toString() {
		return 'Faction { color: "$color" }';
	}
}

@:structInit
class Player {}

// TODO: Make enum
final Health_id = 10;
final Position_id = 20;
final Player_id = 30;
final Faction_id: EntityId = 70;

function main() {
	final context = new Context();
	context.addEntity(Player_id, 'Player');
	context.addComponent(Player_id, Health_id, ({ value: 100 }: Health));
	context.addComponent(Player_id, Position_id, ({ x: 3, y: 7 }: Position));

	final x = (ChildOf | Faction_id);
	trace(x);
	context.addComponent(Player_id, x, ({ color: 'red' }: Faction));

	trace('player is child of faction?');
	trace((x & ChildOf > 0) ? 'yes' : 'no');

	context.addEntity(Player_id + 1, 'Player 2');
	context.addComponent(Player_id + 1, Health_id, ({ value: 83 }: Health));
	context.addComponent(Player_id + 1, Position_id, ({ x: 2, y: 2 }: Position));

	context.addEntity(Player_id + 2, 'Player 3');
	context.addComponent(Player_id + 2, Health_id, ({ value: 75 }: Health));
	context.addComponent(Player_id + 2, Position_id, ({ x: 3, y: 3 }: Position));


	context.addEntity(45, 'Blah?');
	context.addComponent(45, Position_id, ({ x: 1, y: 7 }: Position));
	// addComponent(45, Health_id, ({ value: 76 }: Health));

	// trace(entityIndex);
	context.printEntity(Player_id);
	context.printEntity(Player_id + 1);

	trace(context.getComponent(Player_id, Health_id));
	trace(context.getComponentsForEntity(Player_id));

	trace(context.getEntitiesWithComponent(Health_id));
	trace('//////////////////////////////');
	final terms = [Health_id, Position_id];
	context.query(terms, (components) -> {
		final healthComponents: Array<Health> = components[0];
		for (component in healthComponents) {
			component.value -= 10;
			trace(component);
		}
	});

	trace('//////////////////////////////3');
	// TODO: In the following list there should be no archetypes with empty `entityId` (except for `emptyArchetype`)
	context.printArchetypes(context.emptyArchetype);

	trace('//////////////////////////////4');
	context.printArchetypeGraph(context.emptyArchetype);
}