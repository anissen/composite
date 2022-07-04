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

final Health_id = 10;
final Position_id = 20;
// final Faction_id: EntityId = 70;

function main() {
	final context = new Context();
	final player1 = context.createEntity('Player');
	context.addComponent(player1, Health_id, ({ value: 100 }: Health));
	context.addComponent(player1, Position_id, ({ x: 3, y: 7 }: Position));

	// final x = (ChildOf | Faction_id);
	// trace(x);
	// context.addComponent(Player_id, x, ({ color: 'red' }: Faction));

	// trace('player is child of faction?');
	// trace((x & ChildOf > 0) ? 'yes' : 'no');

	final player2 = context.createEntity('Player 2');
	context.addComponent(player2, Position_id, ({ x: 2, y: 2 }: Position));
	context.addComponent(player2, Health_id, ({ value: 83 }: Health));

	final player3 = context.createEntity('Player 3');
	context.addComponent(player3, Health_id, ({ value: 75 }: Health));
	context.addComponent(player3, Position_id, ({ x: 3, y: 3 }: Position));

	final blah = context.createEntity('Blah?');
	context.addComponent(blah, Position_id, ({ x: 1, y: 7 }: Position));

	context.printEntity(player1);
	context.printEntity(player2);

	trace(context.getComponent(player1, Health_id));
	trace(context.getComponentsForEntity(player1));
	trace(context.getEntitiesWithComponents([Health_id]));
	
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
	context.printArchetypes(context.rootArchetype);

	trace('//////////////////////////////4');
	context.printArchetypeGraph(context.rootArchetype);
}