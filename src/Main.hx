import haxe.display.Display.DeterminePackageResult;

// Based on https://ajmmertens.medium.com/building-an-ecs-1-types-hierarchies-and-prefabs-9f07666a1e9d
abstract EntityId(haxe.Int32) from Int to Int {}
// typedef ComponentId = EntityId;
// abstract ComponentId(Int) from Int {}
typedef Components = Array<EntityId>;

// Type flags
final InstanceOf: EntityId = 1 << 29;
final ChildOf: EntityId = 2 << 28;

@:structInit
class EcsComponent {
}

@:structInit
class EcsId {
	public final name: String;
}

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

@:structInit
class Edge {
	public var add: Null<Archetype>;
	public var remove: Null<Archetype>;
}

@:structInit
class Archetype {
	public final type: Components;
	public final entityIds: Array<EntityId>;
	public final components: Array<Array<Any>>;
	// public final length: Int;
	// public final edges: Array<Edge>;
	public final edges: Map<EntityId, Edge>;
	public function toString() {
		return 'Archetype { type: $type, entityId: $entityIds, edges: $edges }';
	}
}

@:structInit
class Record {
	public final archetype: Archetype;
	public final row: Int;
	public function toString() {
		return 'Record { archetype: $archetype, row: $row }';
	}
}

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

	final entityIndex = new Map<EntityId, Record>();
	final emptyArchetype: Archetype = {
		type: [],
		entityIds: [],
		components: [],
		// length: 0,
		edges: [],
	};

	inline public function new() {
		final destinationArchetype = findOrCreateArchetype(emptyArchetype, [EcsComponent_id, EcsId_id]);
		// trace(destinationArchetype);
		// trace(destinationArchetype.entityIds);
		// trace(destinationArchetype.components);
		destinationArchetype.entityIds.push(EcsComponent_id);
		// trace(destinationArchetype.components);
		destinationArchetype.components[0].push(({}: EcsComponent));
		destinationArchetype.components[1].push(({ name: 'EcsComponent' }: EcsId));
		final componentRecord: Record = {
			archetype: destinationArchetype,
			row: destinationArchetype.entityIds.length - 1,
		};	
		entityIndex.set(EcsComponent_id, componentRecord);
		
		destinationArchetype.entityIds.push(EcsId_id);
		destinationArchetype.components[0].push(({}: EcsComponent));
		destinationArchetype.components[1].push(({ name: 'EcsId' }: EcsId));
		final idRecord: Record = {
			archetype: destinationArchetype,
			row: destinationArchetype.entityIds.length - 1,
		};	
		entityIndex.set(EcsId_id, idRecord);
		testEcs();	
	}

	inline public function testEcs() {
		addEntity(Player_id);
		addComponent(Player_id, Health_id);
		addComponent(Player_id, Position_id);
		// final x = (ChildOf | Faction_id);
		// trace(x);
		// addComponent(Player_id, x);

		// trace('player is child of faction?');
		// trace((x & ChildOf > 0) ? 'yes' : 'no');

		// trace(entityIndex);
		trace('entities and components in entityIndex:');
		for (entity => components in entityIndex) {
			trace('$entity: $components');
		}
	}

	inline function addEntity(entity: EntityId) {
		final destinationArchetype = findOrCreateArchetype(emptyArchetype, [EcsId_id]);
		// destinationArchetype.components.push({})
		destinationArchetype.entityIds.push(entity);
		final record: Record = {
			archetype: destinationArchetype,
			row: destinationArchetype.entityIds.length - 1,
		};
		entityIndex.set(entity, record);
	}
	
	inline function addComponent(entity: EntityId, componentId: EntityId) {
		if (!entityIndex.exists(entity)) throw 'entity $entity does not exist';
		// if (!entityIndex.exists(componentId)) {
		// 	entityIndex.set(componentId, [EcsComponent_id, EcsId_id]);
		// }
		final archetype = entityIndex[entity].archetype;
		final type = archetype.type;
		if (type.contains(componentId)) {
			trace('component $componentId already exists on entity $entity');
			return;
		}
		
		// find destination archetype
		var node = archetype;
		for (t in archetype.type) {
			trace(t);
			var edge = node.edges[t];
			trace(edge);
			if (edge == null) { // TODO: this is wrong? or a hack at least
				edge = {
					add: null,
					remove: null,
				};
			}
			if (edge.add == null) {
				edge.add = createArchetype(node, t);
			}
			// if (edge.add.type.contains(componentId)) {
			// 	node = edge.add;
			// 	break;
			// }
			node = edge.add;
		}
		
		// insert entity into component array of destination
		// TODO: Implement!
		
		// copy overlapping components from source to destination
		// TODO: Implement!
		
		// remove entity from component array of source
		// TODO: Implement!
	}

	inline function findOrCreateArchetype(archetype: Archetype, type: Components): Archetype {
		// find destination archetype
		var node = archetype;
		for (t in type) {
			trace(t);
			var edge = node.edges[t];
			trace(edge);
			if (edge == null) { // TODO: this is wrong? or a hack at least
				edge = {
					add: null,
					remove: null,
				};
			}
			if (edge.add == null) {
				edge.add = createArchetype(node, t);
			}
			// if (edge.add.type.contains(componentId)) {
			// 	node = edge.add;
			// 	break;
			// }
			node = edge.add;
		}
		return node;
	}

	inline function createNewArchetype(componentIds: Components) {
		return {
			type: componentIds,
			entityIds: [],
			components: [],
			length: 0,
			edges: [], // TODO: create edges
		};
	}

	inline function createArchetype(archetype: Archetype, addComponentId: EntityId): Archetype {
		trace('createArchetype');
		final type = archetype.type.concat([addComponentId]);
		return {
			type: type,
			entityIds: [],
			components: [for (_ in type) []],
			edges: [
				addComponentId => {
					add: null,
					remove: archetype
				}
			], // TODO: create correct edges
		};
		// final type = archetype.type;
		// final entityIds = archetype.entityIds;
		// final components = archetype.components;
		// final length = archetype.length;
		// final edges = archetype.edges;
		// final newArchetype = new Archetype();
		// newArchetype.type = type.concat(componentId);
		// newArchetype.entityIds = entityIds;
		// newArchetype.components = components;
		// newArchetype.length = length;
		// newArchetype.edges = edges;
		// return newArchetype;
	}

	inline function getComponent(entity: EntityId, componentId: EntityId): Any {
		final record = entityIndex[entity];
		final archetype = record.archetype;
		final type = archetype.type;
		for (t in type) {
			if (t == componentId) return archetype.components[record.row];
		}
		return null;
	}

	inline function hasComponent(entity: EntityId, componentId: EntityId) {
		final record = entityIndex[entity];
		final archetype = record.archetype;
		final type = archetype.type;
		for (t in type) {
			if (t == componentId) return true;
		}
		return false;
	}
}