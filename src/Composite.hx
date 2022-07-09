package;

// TODO: Split into separate local domain files.

// Based on https://ajmmertens.medium.com/building-an-ecs-1-types-hierarchies-and-prefabs-9f07666a1e9d
abstract EntityId(haxe.Int32) from Int to Int {}
// typedef ComponentId = EntityId;
typedef Components = Array<EntityId>;

typedef Expression = Array<EntityId>;

// Type flags
final InstanceOf: EntityId = 1 << 29;
final ChildOf: EntityId = 2 << 28;

// final EcsComponent_id = 1;
// final EcsId_id = 2;

@:autoBuild(macros.Component.buildComponent())
interface Component {
	function getID(): Int;
}


@:structInit
class EcsComponent implements Component {
	public function toString() {
		return 'EcsComponent';
	}
}

@:structInit
class EcsId implements Component {
	public final name: String;
	public function toString() {
		return 'EcsId { name: "$name" }';
	}
}

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
	static var archetypeId: Int = 0;
	public final id: Int = archetypeId++;
	public final type: Components;
	public final entityIds: Array<EntityId>;
	public final components: Array<Array<Any>>;
	// public final length: Int;
	public final edges: Map<EntityId, Edge>;
	public function toString() {
		final edgesString = [for (k => v in edges) '$k\t=> $v'].join("\n\t\t");
		return 'Archetype { \n\ttype: $type, \n\tentityId: $entityIds, \n\tedges: \n\t\t$edgesString} \n}';
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

class Context {
	var nextEntityId = 3;
	final entityIndex = new Map<EntityId, Record>();
	final systems: Array<System> = [];
	public final rootArchetype: Archetype = {
		type: [],
		entityIds: [],
		components: [],
		// length: 0,
		edges: [],
	};
	

	inline public function new() {
		final destinationArchetype = findOrCreateArchetype([EcsComponent.ID, EcsId.ID]);
		destinationArchetype.entityIds.push(EcsComponent.ID);
		destinationArchetype.components[0].push(({}: EcsComponent));
		destinationArchetype.components[1].push(({ name: 'EcsComponent' }: EcsId));
		final componentRecord: Record = {
			archetype: destinationArchetype,
			row: destinationArchetype.entityIds.length - 1,
		};	
		entityIndex.set(EcsComponent.ID, componentRecord);
		
		destinationArchetype.entityIds.push(EcsId.ID);
		destinationArchetype.components[0].push(({}: EcsComponent));
		destinationArchetype.components[1].push(({ name: 'EcsId' }: EcsId));
		final idRecord: Record = {
			archetype: destinationArchetype,
			row: destinationArchetype.entityIds.length - 1,
		};	
		entityIndex.set(EcsId.ID, idRecord);
	}

	public function createEntity(name: String): EntityId {
		final entityId = nextEntityId++;

		final destinationArchetype = findOrCreateArchetype([EcsId.ID]);
		destinationArchetype.components[0].push(({ name: name }: EcsId));
		destinationArchetype.entityIds.push(entityId);
		final record: Record = {
			archetype: destinationArchetype,
			row: destinationArchetype.entityIds.length - 1,
		};
		entityIndex.set(entityId, record);

		return entityId;
	}
	
	public function addComponent(entity: EntityId, componentData: Component) {
		if (!entityIndex.exists(entity)) throw 'entity $entity does not exist';
		final record = entityIndex[entity];
		final archetype = record.archetype;
		final type = archetype.type;
		final componentId = componentData.getID();
		if (type.contains(componentId)) {
			trace('component $componentId already exists on entity $entity');
			return;
		}
		
		// find destination archetype
		final destinationType = type.concat([componentId]);
		destinationType.sort((x, y) -> x - y);
		var destinationArchetype = findOrCreateArchetype(destinationType);

		// insert entity into component array of destination
		destinationArchetype.entityIds.push(entity);
		
		// copy overlapping components from source to destination + insert new component
		var index = 0;
		var newComponentInserted = false;
		for (i => t in type) {
			if (!newComponentInserted && t != destinationArchetype.type[i]) {
				// trace(componentData);
				destinationArchetype.components[i].push(componentData);
				newComponentInserted = true;
				index++;
				if (index >= destinationArchetype.components.length) {
					break;
				}
			}
			destinationArchetype.components[index].push(archetype.components[i][record.row]);
			index++;
		}
		if (!newComponentInserted) {
			destinationArchetype.components[index].push(componentData);
		}
		
		// remove entity from component array of source
		archetype.entityIds.splice(record.row, 1); // TODO: We should probably swap the old entity down to the end of the `active` part of the array instead
		
		// Remove source archetype if it is now empty and is a leaf in the graph
		if (archetype.entityIds.length == 0) {
			// for (t => edge in archetype.edges) {
			// 	// TODO: Remove archetype from the edges of adjacent archetypes
			// 	if (edge.add != null) {
			// 		final adjacentAdd = edge.add;
			// 		for (t2 => adjacentEdge in adjacentAdd.edges) {
			// 			// if (adjacentEdge.remove != null) trace('${adjacentEdge.remove.id} == ${archetype.id}');
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
			// 			// if (adjacentEdge.add != null) trace('${adjacentEdge.add.id} == ${archetype.id}');
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

	function findOrCreateArchetype(type: Components): Archetype {
		// trace('findOrCreateArchetype(${archetype.type}, $type)');
		var node = rootArchetype;
		for (t in type) {
			if (node.type.contains(t)) continue;
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
				// trace('creating new archetype for $typesSoFar');
				final newType = node.type.concat([t]);
				newType.sort((x, y) -> x - y);
				final newArchetype: Archetype = {
					type: newType,
					entityIds: [],
					components: [for (_ in newType) []],
					edges: [t => {
						add: null,
						remove: node,
					}],
				};
				edge.add = newArchetype;
			}
			// trace('${node.type} => ${edge.add.type}');
			node = edge.add; // move to the node that contains the component `t`
		}
		return node;
	}

	public function printEntity(entity: EntityId) {
		trace('entity $entity:');
		final record = entityIndex[entity];
		for (i => component in record.archetype.components) {
			trace('    #$i: ${component[record.row]}');
		}
	}

	public function printArchetypes(node: Archetype) {
		trace('archetype: $node');
		for (edge in node.edges) {
			if (edge != null && edge.add != null) {
				printArchetypes(edge.add);
			}
		}
	}

	public function printArchetypeGraph(node: Archetype) {
		function println(s: String) {
			#if sys Sys.println(s); #else trace(s); #end
		}
		println('"${node.type}${node.id}" [label="${node.type} (entities: ${node.entityIds.length})"];');
		for (t => edge in node.edges) {
			if (edge != null && edge.add != null) {
				println('"${node.type}${node.id}" -> "${edge.add.type}${edge.add.id}" [label="add ${t}"];');
				printArchetypeGraph(edge.add);
			}
			if (edge != null && edge.remove != null) {
				println('"${node.type}${node.id}" -> "${edge.remove.type}${edge.remove.id}" [label="remove ${t}"];');
			}
		}
	}

	// TODO: Inline functions!
	public function getComponent(entity: EntityId, componentId: EntityId): Any {
		final record = entityIndex[entity];
		final archetype = record.archetype;
		final type = archetype.type;
		for (i => t in type) {
			if (t == componentId) return archetype.components[i][record.row];
		}
		return null;
	}
	
	public function getComponentsForEntity(entity: EntityId): Array<Any> {
		final record = entityIndex[entity];
		final archetype = record.archetype;
		final type = archetype.type;
		final components = [];
		for (i => _ in type) {
			components.push(archetype.components[i][record.row]);
		}
		return components;
	}

	function getArchetypesWithComponent(componentId: EntityId): Array<Archetype> {
		final next: Array<Null<Archetype>> = [rootArchetype];
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
	public function queryArchetypes(terms: Array<EntityId>): Array<Archetype> {
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

	public function query(terms: Array<EntityId>, fn: (components: Array<Any>) -> Void) {
		final componentsForTerms = [ for (_ in terms) [] ];
		final archetypes = queryArchetypes(terms);

		for (i => term in terms) {
			for (archetype in archetypes) {
				componentsForTerms[i] = componentsForTerms[i].concat(archetype.components[archetype.type.indexOf(term)]);
			}
		}
		// trace('componentsForTerms: $componentsForTerms');
		fn(componentsForTerms);
	}

	public function getEntitiesWithComponents(terms: Array<EntityId>): Array<EntityId> {
		final archetypes = queryArchetypes(terms);
		return Lambda.flatten([ for (node in archetypes) { node.entityIds; } ]);
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


	
	public function addSystem(expression: Expression, fn: (components: Array<Any>) -> Void, /* phase: OnUpdate, */ name: String) {
		systems.push({ expression: expression, fn: fn, name: name});
	}

	public function step() {
		for (system in systems) {
			query(system.expression, system.fn); // TODO: Query should be cached
		}
	}
}

@:structInit
class System {
	public final expression: Expression;
	public final fn: (components: Array<Any>) -> Void;
	public final name: String;
}