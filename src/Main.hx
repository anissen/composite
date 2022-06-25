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
	public function toString() {
		return 'EcsComponent';
	}
}

@:structInit
class EcsId {
	public final name: String;
	public function toString() {
		return 'EcsId { name: "$name" }';
	}
}

@:structInit
class Position {
	public var x: Float;
	public var y: Float;
}

@:structInit
class Health {
	public var value: Int;
}

@:structInit
class Player {}

@:structInit
class Edge {
	public var add: Null<Archetype>;
	public var remove: Null<Archetype>;
	public function toString() {
		return 'Edge { add: ${add != null ? add.type : null}, remove: ${remove != null ? remove.type : null} }';
	}
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
		destinationArchetype.entityIds.push(EcsComponent_id);
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

	public function testEcs() {
		addEntity(Player_id, 'Player');
		printArchetypes(emptyArchetype);
		printEntity(Player_id);
		addComponent(Player_id, Health_id, ({ value: 100 }: Health));
		printEntity(Player_id);
		addComponent(Player_id, Position_id, ({ x: 3, y: 7 }: Position));
		// final x = (ChildOf | Faction_id);
		// trace(x);
		// addComponent(Player_id, x);

		// trace('player is child of faction?');
		// trace((x & ChildOf > 0) ? 'yes' : 'no');

		// trace(entityIndex);
		printEntity(Player_id);
	}

	function addEntity(entity: EntityId, name: String) {
		final destinationArchetype = findOrCreateArchetype(emptyArchetype, [EcsId_id]);
		destinationArchetype.components[0].push(({ name: name }: EcsId));
		destinationArchetype.entityIds.push(entity);
		final record: Record = {
			archetype: destinationArchetype,
			row: destinationArchetype.entityIds.length - 1,
		};
		entityIndex.set(entity, record);
	}
	
	function addComponent(entity: EntityId, componentId: EntityId, componentData: Any) {
		if (!entityIndex.exists(entity)) throw 'entity $entity does not exist';
		// if (!entityIndex.exists(componentId)) {
		// 	entityIndex.set(componentId, [EcsComponent_id, EcsId_id]);
		// }
		final record = entityIndex[entity];
		final archetype = record.archetype;
		final type = archetype.type;
		if (type.contains(componentId)) {
			trace('component $componentId already exists on entity $entity');
			return;
		}
		
		// find destination archetype
		final destinationType = type.concat([componentId]);
		destinationType.sort((x, y) -> x - y);
		var destinationArchetype = findOrCreateArchetype(archetype, destinationType);
		
		// insert entity into component array of destination
		destinationArchetype.entityIds.push(entity); // TODO: Is this what is meant by the above comment?
		
		// copy overlapping components from source to destination + insert new component
		var index = 0;
		var newComponentInserted = false;
		for (i => t in type) {
			if (!newComponentInserted && t != destinationArchetype.type[i]) {
				trace(componentData);
				destinationArchetype.components[i].push(componentData);
				newComponentInserted = true;
				index++;
			}
			destinationArchetype.components[index].push(archetype.components[i][record.row]);
			index++;
		}
		if (!newComponentInserted) {
			destinationArchetype.components[index].push(componentData);
		}
		
		// remove entity from component array of source
		archetype.entityIds.splice(record.row, 1); // TODO: We should probably swap the old entity down to the end of the `active` part of the array instead
		for (i => t in type) {
			archetype.components[i].splice(record.row, 1);
		}

		// point the entity record to the new archetype
		var newRecord: Record = {
			archetype: destinationArchetype,
			row: destinationArchetype.entityIds.length - 1
		};
		entityIndex[entity] = newRecord;
	}

	function findOrCreateArchetype(archetype: Archetype, type: Components): Archetype {
		var node = archetype;
		var typesSoFar = [];
		for (t in type) {
			typesSoFar.push(t);
			// final edgeExists = node.edges.exists(t);
			var edge = node.edges[t];
			if (edge == null) {
				edge = {
					add: null,
					remove: null,
				};
				node.edges[t] = edge;
			}
			// TODO: Also handle the case where we want to remove a component from an entity.
			if (edge.add == null) {
				final newArchetype: Archetype = {
					type: typesSoFar.copy(),
					entityIds: [],
					components: [for (_ in typesSoFar) []],
					edges: [t => {
						add: null,
						remove: node,
					}],
				};
				edge.add = newArchetype;
			}
			node = edge.add; // move to the node that contains the component `t`
		}
		return node;
	}

	// inline function createArchetype(archetype: Archetype, addComponentId: EntityId): Archetype {
	// 	// trace('createArchetype');
	// 	final type = archetype.type.concat([addComponentId]);
	// 	return {
	// 		type: type,
	// 		entityIds: [],
	// 		components: [for (_ in type) []],
	// 		edges: [
	// 			addComponentId => {
	// 				add: null,
	// 				remove: archetype
	// 			}
	// 		], // TODO: create correct edges
	// 	};
	// }

	function printEntity(entity: EntityId) {
		trace('entity $entity:');
		final record = entityIndex[entity];
		for (i => component in record.archetype.components) {
			trace('    #$i: $component');
		}
	}

	function printArchetypes(node: Archetype) {
		trace('archetype: $node');
		for (edge in node.edges) {
			if (edge != null && edge.add != null) {
				printArchetypes(edge.add);
			}
		}
	}

	// inline function getComponent(entity: EntityId, componentId: EntityId): Any {
	// 	final record = entityIndex[entity];
	// 	final archetype = record.archetype;
	// 	final type = archetype.type;
	// 	for (i => t in type) {
	// 		if (t == componentId) return archetype.components[i][record.row];
	// 	}
	// 	return null;
	// }

	// inline function hasComponent(entity: EntityId, componentId: EntityId) {
	// 	final record = entityIndex[entity];
	// 	final archetype = record.archetype;
	// 	final type = archetype.type;
	// 	for (t in type) {
	// 		if (t == componentId) return true;
	// 	}
	// 	return false;
	// }
}