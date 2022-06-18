
// Based on https://ajmmertens.medium.com/building-an-ecs-1-types-hierarchies-and-prefabs-9f07666a1e9d
abstract EntityId(haxe.Int32) from Int to Int {}
// typedef ComponentId = EntityId;
// abstract ComponentId(Int) from Int {}
typedef Components = Array<EntityId>;

// Type flags
final InstanceOf: EntityId = 1 << 29;
final ChildOf: EntityId = 2 << 28;

// @:structInit
// class EcsComponent {
// }

// @:structInit
// class EcsId {
// 	public final name: String;
// }

// @:structInit
// class Position {
// 	public var x: Float;
// 	public var y: Float;
// }

// @:structInit
// class Health {
// 	public var value: Int;
// }

// @:structInit
// class Player {}

// TODO: Make enum
final EcsComponent_id = 1;
final EcsId_id = 2;
final Health_id = 10;
final Position_id = 20;
final Player_id = 30;
final Faction_id: EntityId = 70;

class Main {
	static function main() {
		final c = new Main();
	}

	final entityIndex = new Map<EntityId, Components>();

	inline public function new() {
		entityIndex.set(EcsComponent_id, [EcsComponent_id, EcsId_id]);
		entityIndex.set(EcsId_id, [EcsComponent_id, EcsId_id]);
		testEcs();	
	}

	inline public function testEcs() {
		addEntity(Player_id);
		addComponent(Player_id, Health_id);
		addComponent(Player_id, Position_id);
		// trace((2: haxe.Int64) | (8: haxe.Int64));
		final x = (ChildOf | Faction_id);
		trace(x);
		addComponent(Player_id, x);

		trace('player is child of faction?');
		trace((x & ChildOf > 0) ? 'yes' : 'no');

		// trace(entityIndex);
		for (entity => components in entityIndex) {
			trace('$entity: $components');
		}
	}

	inline function addEntity(entity: EntityId) {
		entityIndex.set(entity, [EcsId_id]);
	}
	
	inline function addComponent(entity: EntityId, componentId: EntityId) {
		if (!entityIndex.exists(entity)) throw 'entity $entity does not exist';
		if (!entityIndex.exists(componentId)) {
			entityIndex.set(componentId, [EcsComponent_id, EcsId_id]);
		}
		entityIndex[entity].push(componentId);
	}

	inline function hasComponent(entity: EntityId, component: EntityId) {
		return entityIndex[entity].contains(component);
	}
}