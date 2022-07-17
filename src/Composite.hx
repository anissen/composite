package;

import haxe.Json;

// TODO: Split into separate local domain files.

// Based on https://ajmmertens.medium.com/building-an-ecs-1-types-hierarchies-and-prefabs-9f07666a1e9d
abstract EntityId(haxe.Int32) from Int to Int {}
// typedef ComponentId = EntityId;
typedef Components = Array<EntityId>;

// typedef Expression = Array<EntityId>;

// Type flags
final InstanceOf: EntityId = 1 << 29;
final ChildOf: EntityId = 2 << 28;

// final EcsComponent_id = 1;
// final EcsId_id = 2;

@:autoBuild(macros.Component.buildComponent())
extern interface Component {
	function getID(): Int;
}

// @:structInit
// class EcsComponent implements Component {
// 	public function toString() {
// 		return 'EcsComponent';
// 	}
// }

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

/*
See: https://flecs.docsforge.com/master/query-manual/#query-concepts
Health, Position => Health AND Position
Health, !Position => Health AND (NOT Position)
Health or Position => Health OR Position
Health, (Position or Color) => Health AND (Position OR Color)

Health, Changed(Position)
Health, Added(Position)
*/

enum Expression {
	Include(componentId: EntityId); // 'and'
	Exclude(componentId: EntityId); // 'not'
	// And(expression: Expression);
	// Or(expression: Expression);
	Group(expressions: Array<Expression>);
	// Added(componentId: EntityId);
	// Changed(componentId: EntityId);
	// Removed(componentId: EntityId);
}

typedef ParsedExpression = {
	var includes: Array<EntityId>;
	var excludes: Array<EntityId>;
};

class Context {
	var nextEntityId = 0;
	final entityIndex = new Map<EntityId, Record>();
	public var rootArchetype: Archetype;
	final queryArchetypeCache: Map<String, Array<Archetype>> = new Map();


	inline public function new() {
		clear();
	}

	public function clear() {
		nextEntityId = 0;
		entityIndex.clear();
		rootArchetype = {
			type: [],
			entityIds: [],
			components: [],
			// length: 0,
			edges: [],
		};
		queryArchetypeCache.clear();
	}

	public function createEntity(?name: String): EntityId {
		final entityId = nextEntityId++;

		final destinationArchetype = findOrCreateArchetype(name != null ? [EcsId.ID] : []);
		if (name != null) {
			destinationArchetype.components[0].push(({ name: name }: EcsId));
		}
		destinationArchetype.entityIds.push(entityId);
		final record: Record = {
			archetype: destinationArchetype,
			row: destinationArchetype.entityIds.length - 1,
		};
		entityIndex.set(entityId, record);

		return entityId;
	}
	
	public function addComponent(entity: EntityId, componentData: Component, componentId: Null<EntityId> = null) {
		if (!entityIndex.exists(entity)) throw 'entity $entity does not exist';
		final record = entityIndex[entity];
		final archetype = record.archetype;
		final type = archetype.type;
		final componentId = componentId ?? componentData.getID();
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
				queryArchetypeCache.clear(); // clear the archetype cache
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
	public function queryArchetypes(includes: Array<EntityId>, excludes: Array<EntityId>): Array<Archetype> {
		final queryKey = includes.join(',') + '-' + excludes.join(',');
		if (queryArchetypeCache.exists(queryKey)) {
			return queryArchetypeCache[queryKey];
		}

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
		if (includes.length == 0 && excludes.length != 0) throw 'Cannot query with only exclude terms';
		if (includes.length == 0) return [];
		final firstTerm = includes[0];
		final archetypes = [];
		final archetypeProspects = getArchetypesWithComponent(firstTerm);
		// TODO: Also find the component arrays here???
		for (archetype in archetypeProspects) {
			var match = true;
			for (i in 1...includes.length) {
				if (!archetype.type.contains(includes[i])) {
					match = false;
					break;
				}
			}
			if (!match) continue;

			var disqualified = false;
			for (exclude in excludes) {
				if (archetype.type.contains(exclude)) {
					disqualified = true;
					break;
				}
			}
			if (disqualified) continue;

			archetypes.push(archetype);
		}
		queryArchetypeCache[queryKey] = archetypes;
		return archetypes;
	}

	function parseExpression(expression: Expression): ParsedExpression {
		var result: ParsedExpression = {
			includes: [],
			excludes: [],
		};
		switch expression {
			case Include(t): result.includes.push(t);
			case Exclude(t): result.excludes.push(t);
			case Group(exps):
				for (e in exps) {
					final tmp = parseExpression(e);
					result.includes = result.includes.concat(tmp.includes);
					result.excludes = result.excludes.concat(tmp.excludes);
				}
		}
		return result;
	}

	public function query(expression: Expression, fn: (components: Array<Any>) -> Void) {
		final parsed = parseExpression(expression);
		final componentsForTerms = [ for (_ in parsed.includes) [] ];
		final archetypes = queryArchetypes(parsed.includes, parsed.excludes);

		for (i => term in parsed.includes) {
			for (archetype in archetypes) {
				// TODO: Could we avoid creating and copying arrays here? Maybe allow `fn` to index into the component arrays of the different archetypes?
				componentsForTerms[i] = componentsForTerms[i].concat(archetype.components[archetype.type.indexOf(term)]);
			}
		}
		// trace('componentsForTerms: $componentsForTerms');
		fn(componentsForTerms);
	}

	public function getEntitiesWithComponents(expression: Expression): Array<EntityId> {
		final parsed = parseExpression(expression);
		final archetypes = queryArchetypes(parsed.includes, parsed.excludes);
		return Lambda.flatten([ for (node in archetypes) { node.entityIds; } ]);
	}

	public function save() {
		final data = [];
		var queue = [rootArchetype];
		while (queue.length != 0) {
			final node = queue.pop();
			if (node.entityIds.length != 0) {
				final entityData = [];
				final type = node.type;
				for (e in 0...node.entityIds.length) {
					final componentData = [];
					for (t => _ in type) {
						componentData.push(node.components[t][e]);
					}
					entityData.push(componentData);
				}
				data.push({
					type: type,
					components: entityData,
				});
			}
			for (edge in node.edges) {
				if (edge != null && edge.add != null) {
					queue.push(edge.add);
				}
			}
		}
		return haxe.Json.stringify(data);
	}

	public function load(data: String) {
		final data: Array<Dynamic> = haxe.Json.parse(data);
		for (archetypeData in data) {
			final type: Array<Int> = archetypeData.type;
			final components: Array<Array<Any>> = archetypeData.components;
			for (entityComponentsList in components) {
				final entity = createEntity();
				for (i => componentData in entityComponentsList) {
					addComponent(entity, componentData, type[i]);
				}
			}
		}
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
	
	// public function addSystem(expression: Expression, fn: (components: Array<Any>) -> Void, /* phase: OnUpdate, */ name: String) {
	// 	systems.push({ expression: expression, fn: fn, name: name});
	// }

	// public function addSystemEx<T:{final ID: Int;}>(expression: Array<T>, fn: (components: Array<Any>) -> Void) {
	// 	systems.push({ expression: expression.map(c -> c.ID), fn: fn, name: ''});
	// }

	// public function step() {
	// 	for (system in systems) {
	// 		query(system.expression, system.fn); // TODO: Query should be cached
	// 	}
	// }
}

@:structInit
class System {
	public final expression: Expression;
	public final fn: (components: Array<Any>) -> Void;
	public final name: String;
}