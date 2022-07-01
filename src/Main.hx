// Based on https://ajmmertens.medium.com/building-an-ecs-1-types-hierarchies-and-prefabs-9f07666a1e9d
abstract EntityId(haxe.Int32) from Int to Int {}
// typedef ComponentId = EntityId;
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
	public final edges: Map<EntityId, Edge>;
	public function toString() {
		return 'Archetype { \n\ttype: $type, \n\tentityId: $entityIds, \n\tedges: $edges \n}';
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
		new Main();
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
		addComponent(Player_id, Health_id, ({ value: 100 }: Health));
		addComponent(Player_id, Position_id, ({ x: 3, y: 7 }: Position));

		final x = (ChildOf | Faction_id);
		trace(x);
		addComponent(Player_id, x, ({ color: 'red' }: Faction));
		
		trace('player is child of faction?');
		trace((x & ChildOf > 0) ? 'yes' : 'no');

		addEntity(Player_id + 1, 'Player 2');
		addComponent(Player_id + 1, Health_id, ({ value: 83 }: Health));
		addComponent(Player_id + 1, Position_id, ({ x: 2, y: 2 }: Position));
		
		addEntity(Player_id + 2, 'Player 3');
		addComponent(Player_id + 2, Health_id, ({ value: 75 }: Health));
		addComponent(Player_id + 2, Position_id, ({ x: 3, y: 3 }: Position));


		addEntity(45, 'Blah?');
		addComponent(45, Position_id, ({ x: 1, y: 7 }: Position));
		// addComponent(45, Health_id, ({ value: 76 }: Health));

		// trace(entityIndex);
		printEntity(Player_id);
		printEntity(Player_id + 1);

		trace(getComponent(Player_id, Health_id));
		trace(getComponentsForEntity(Player_id));

		trace(getEntitiesWithComponent(Health_id));
		trace('//////////////////////////////');
		final terms = [Health_id, Position_id];
		for (archetype in queryArchetypes(terms)) {
			for (i => term in terms) {
				trace(archetype.components[archetype.type.indexOf(term)]);
			}
		}
		trace('//////////////////////////////2');
		query(terms, (components) -> {
			final healthComponents: Array<Health> = components[0];
			for (component in healthComponents) {
				component.value -= 10;
				trace(component);
			}
		});

		trace('//////////////////////////////3');
		// TODO: In the following list there should be no archetypes with empty `entityId` (except for `emptyArchetype`) and no two archetypes with same `type`
		printArchetypes(emptyArchetype);

		trace('//////////////////////////////4');
		printArchetypeGraph(emptyArchetype);
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
		destinationArchetype.entityIds.push(entity);
		
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
		
		// Remove source archetype if it is now empty
		if (archetype.entityIds.length == 0) {
			// for (t => edge in archetype.edges) {
			// 	// TODO: Remove archetype from the edges of adjacent archetypes
			// 	if (edge.add != null) {
			// 		final adjacentAdd = edge.add;
			// 		for (t2 => adjacentEdge in adjacentAdd.edges) {
			// 			if (adjacentEdge.remove != null) trace('${adjacentEdge.remove.id} == ${archetype.id}');
			// 			if (t2 == t && adjacentEdge.remove == archetype) {
			// 				trace('removing `remove` edge: ' + t + ' -> ' + t2);
			// 				trace(adjacentEdge.remove);
			// 				adjacentEdge.remove = null;
			// 			}
			// 		} 
			// 	}
			// 	if (edge.remove != null) {
			// 		final adjacentRemove = edge.remove;
			// 		for (t2 => adjacentEdge in adjacentRemove.edges) {
			// 			if (adjacentEdge.add != null) trace('${adjacentEdge.add.id} == ${archetype.id}');
			// 			if (t2 == t && adjacentEdge.add == archetype) {
			// 				trace('removing `add` edge: ' + t + ' -> ' + t2);
			// 				trace(adjacentEdge.add);
			// 				adjacentEdge.add = null;
			// 			}
			// 		} 
			// 	}
			// }
		}
		// remove components from source archetype
		for (i => t in type) {
			archetype.components[i].splice(record.row, 1);
		}

		// point the entity record to the new archetype
		var newRecord: Record = {
			archetype: destinationArchetype,
			row: destinationArchetype.entityIds.length - 1
		};
		entityIndex.set(entity, newRecord);
	}

	function findOrCreateArchetype(archetype: Archetype, type: Components): Archetype {
		trace('findOrCreateArchetype(${archetype.type}, $type)');
		var node = archetype;
		var typesSoFar = [];
		for (t in type) {
			typesSoFar.push(t);
			if (archetype.type.contains(t)) continue;
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
				trace('creating new archetype for $typesSoFar');
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

	function printEntity(entity: EntityId) {
		trace('entity $entity:');
		final record = entityIndex[entity];
		for (i => component in record.archetype.components) {
			trace('    #$i: ${component[record.row]}');
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

	function printArchetypeGraph(node: Archetype) {
		Sys.println('"${node.type}";');
		for (t => edge in node.edges) {
			if (edge != null && edge.add != null) {
				Sys.println('"${node.type}" -> "${edge.add.type}" [label="add ${t}"];');
				printArchetypeGraph(edge.add);
			}
			if (edge != null && edge.remove != null) {
				Sys.println('"${node.type}" -> "${edge.remove.type}" [label="remove ${t}"];');
			}
		}
	}

	// TODO: Inline functions!
	function getComponent(entity: EntityId, componentId: EntityId): Any {
		final record = entityIndex[entity];
		final archetype = record.archetype;
		final type = archetype.type;
		for (i => t in type) {
			if (t == componentId) return archetype.components[i][record.row];
		}
		return null;
	}
	
	function getComponentsForEntity(entity: EntityId): Array<Any> {
		final record = entityIndex[entity];
		final archetype = record.archetype;
		final type = archetype.type;
		final components = [];
		for (i => _ in type) {
			components.push(archetype.components[i][record.row]);
		}
		return components;
	}

	static final componentLookupCache: Map<EntityId, Array<Archetype>> = [];
	function getEntitiesWithComponent(componentId: EntityId): Array<EntityId> {
		// TODO: Invalidate (some) caches when new archetypes are created
		final cache = componentLookupCache[componentId];
		if (cache != null) {
			trace('cache hit');
			return Lambda.flatten(cache.map(archetype -> archetype.entityIds));
		}
		
		final next: Array<Null<Archetype>> = [emptyArchetype];
		var archetypes: Array<Archetype> = [];
		var entities: Array<EntityId> = [];
		while (next.length != 0) {
			final node = next.pop();
			if (node.type.contains(componentId)) {
				archetypes.push(node);
				entities = entities.concat(node.entityIds);
			}
			for (edge in node.edges) {
				if (edge != null && edge.add != null) {
					next.push(edge.add);
				}
			}
		}
		trace('cache miss');
		componentLookupCache[componentId] = archetypes;
		return entities;
	}

	function getArchetypesWithComponent(componentId: EntityId): Array<Archetype> {
		final next: Array<Null<Archetype>> = [emptyArchetype];
		var archetypes: Array<Archetype> = [];
		while (next.length != 0) {
			final node = next.pop();
			if (node.type.contains(componentId)) {
				archetypes.push(node);
			}
			for (edge in node.edges) {
				if (edge != null && edge.add != null) {
					next.push(edge.add);
				}
			}
		}
		return archetypes;
	}

	// TODO: Make proper terms (e.g. Component, !Component, OR, ...)
	function queryArchetypes(terms: Array<EntityId>): Array<Archetype> {
		// Pseudo code (see https://flecs.docsforge.com/master/query-manual/#query-kinds):
		// Archetype archetypes[] = filter.get_archetypes_for_first_term();
		// for archetype in archetypes:
		// 		bool match = true;
		// 		for each term in filter.range(1, filter.length):
		// 			if !archetype.match(term):
		// 				match = false;
		// 				break;
		// 		if match:
		// 			yield archetype;
		if (terms.length == 0) return [];
		final firstTerm = terms[0];
		final archetypes = [];
		final archetypeProspects = getArchetypesWithComponent(firstTerm);
		// TODO: Also find the component arrays here???
		for (archetype in archetypeProspects) {
			var match = true;
			for (i in 1...terms.length) {
				if (!archetype.type.contains(terms[i])) {
					match = false;
					break;
				}
			}
			if (match) {
				archetypes.push(archetype);
			}
		}
		return archetypes;
	}

	function query(terms: Array<EntityId>, fn: (components: Array<Any>) -> Void) {
		final componentsForTerms = [ for (term in terms) [] ];
		final archetypes = queryArchetypes(terms);

		for (i => term in terms) {
			for (archetype in archetypes) {
				componentsForTerms[i] = componentsForTerms[i].concat(archetype.components[archetype.type.indexOf(term)]);
			}
		}
		trace('componentsForTerms: $componentsForTerms');
		fn(componentsForTerms);
	}

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