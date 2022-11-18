package;

import haxe.Json;

// TODO: Split into separate local domain files.
// Based on https://ajmmertens.medium.com/building-an-ecs-2-archetypes-and-vectorization-fe21690805f9
abstract EntityId(haxe.Int32) from Int to Int {}
typedef Components = Array<EntityId>;

@:autoBuild(macros.Component.buildComponent())
extern interface Component {
    function getID(): Int;
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

class Archetype {
    static var archetypeId: Int = 0;

    // TODO: Make as many of the following private as possible
    public final id: Int = archetypeId++;
    public final type: Components; // array of component ID's

    // public final length: Int;
    public var edges: Map<EntityId, Edge>;
    public final ids: Array<EntityId>;

    final columns: Array<Array<Any>>;

    public function new(type: Components) {
        this.type = type;
        ids = [];
        edges = [];
        columns = [for (_ in type) []];
    }

    public function addRow(id: EntityId, data: Array<Any>) {
        if (data.length != columns.length)
            throw 'data length does not match column count';

        ids.push(id);
        for (i => d in data) {
            columns[i].push(d);
        }
    }

    static inline function swapRemove<T>(arr: Array<T>, index: Int) {
        arr[index] = arr[arr.length - 1];
        arr.pop();
    }

    public function deleteRow(row: Int) {
        if (row < 0 || row >= ids.length) throw 'row $row is out of bounds';

        // TODO: We should probably swap the old entity down to the end of the `active` part of the array instead.
        swapRemove(ids, row);
        for (c in columns) {
            swapRemove(c, row);
        }
    }

    public function getColumnCount(): Int {
        return columns.length;
    }

    public function getId(index: Int): EntityId {
        if (index < 0 || index >= ids.length) throw 'row $index is out of bounds';
        return ids[index];
    }

    public function getCell(row: Int, column: Int): Any {
        if (column < 0 || column >= columns.length) throw 'column $column is out of bounds';
        final rowData = columns[column];
        if (row < 0 || row >= rowData.length) throw 'row $row is out of bounds';
        return rowData[row];
    }

    public function getColumn(index: Int): Array<Any> {
        if (index < 0 || index >= columns.length) throw 'column $index is out of bounds';
        return columns[index];
    }

    public function getRow(index: Int): Array<Any> {
        if (index < 0 || index >= ids.length) throw 'row $index is out of bounds';
        return [for (c in columns) c[index]];
    }

    public function getRowCount(): Int {
        return ids.length;
    }

    public function print() {
        trace('| id | ${[for (i => _ in columns) "data" + (i + 1)].join(" | ")} |');
        trace('-----------------------');
        for (i => id in ids) {
            final rowStr = [for (c in columns) c[i]].join(' | ');
            trace('| $id | $rowStr |');
        }
    }

    public function toString() {
        final edgesString = [for (k => v in edges) '$k\t=> $v'].join("\n\t\t");
        return 'Archetype { \n\ttype: $type, \n\tentityId: $ids, \n\tedges: \n\t\t$edgesString} \n}';
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

    inline public function clear() {
        nextEntityId = 0;
        entityIndex.clear();
        rootArchetype = new Archetype([]);
        queryArchetypeCache.clear();
    }

    public function createEntity(?name: String): EntityId {
        final entityId = nextEntityId++;

        var destArchetype: Archetype;
        if (name != null) {
            destArchetype = findOrCreateArchetype([EcsId.ID]);
            destArchetype.addRow(entityId, [({name: name}: EcsId)]);
        } else {
            destArchetype = findOrCreateArchetype([]);
            destArchetype.addRow(entityId, []);
        }
        final record: Record = {
            archetype: destArchetype,
            row: destArchetype.getRowCount() - 1,
        };
        entityIndex.set(entityId, record);

        return entityId;
    }

    public function destroyEntity(entity: EntityId) {
        final record = entityIndex[entity];
        final archetype = record.archetype;
        archetype.deleteRow(record.row);
        // HACK: This is slow! We want to avoid this by simply marking the removed entity as inactive.
        for (i => e in archetype.ids) {
            if (i < record.row)
                continue;
            entityIndex.set(e, {
                archetype: archetype,
                row: i
            });
        }
    }

    // public function addComponents(entity: EntityId, ...components: Component) {
    public function addComponents(entity: EntityId, components: Array<Component>) {
        for (c in components) {
            addComponent(entity, c);
        }
    }

    // TODO: Should probably be `setComponent`
    public function addComponent(entity: EntityId, componentData: Component, componentId: Null<EntityId> = null) {
        if (!entityIndex.exists(entity))
            throw 'entity $entity does not exist';

        final record = entityIndex[entity];
        final archetype = record.archetype;
        final type = archetype.type;
        final componentId = componentId ?? componentData.getID();
        if (type.contains(componentId)) {
            trace('component $componentId already exists on entity $entity');
            return;
        }

        // find destination archetype
        final destType = type.concat([componentId]);
        destType.sort((x, y) -> x - y); // TODO: It would be better to use a sorted data structure
        var destArchetype = findOrCreateArchetype(destType);

        // copy overlapping components from source to destination + insert new component
        final sourceRow = archetype.getRow(record.row);
        var sourceRowIndex = 0;
        final destRow = [];
        for (t in destArchetype.type) { // e.g. [A, C] + B => [A, B, C]
            if (type.contains(t)) {
                destRow.push(sourceRow[sourceRowIndex++]);
            } else {
                destRow.push(componentData);
            }
        }

        destArchetype.addRow(entity, destRow);

        // remove entity and components from source archetype
        archetype.deleteRow(record.row);

        // HACK: This is slow! We want to avoid this by simply marking the removed entity as inactive.
        for (i => e in archetype.ids) {
            if (i < record.row)
                continue;
            entityIndex.set(e, {
                archetype: archetype,
                row: i
            });
        }

        // Remove source archetype if it is now empty and is a leaf in the graph
        if (archetype.getRowCount() == 0) {
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

        // point the entity record to the new archetype
        var newRecord: Record = {
            archetype: destArchetype,
            row: destArchetype.getRowCount() - 1
        };
        entityIndex.set(entity, newRecord);
    }

    public function removeComponent(entity: EntityId, componentId: EntityId) {
        if (!entityIndex.exists(entity))
            throw 'entity $entity does not exist';
        final record = entityIndex[entity];
        final archetype = record.archetype;
        final type = archetype.type;
        if (!type.contains(componentId)) {
            trace('component $componentId does not exist on entity $entity');
            return;
        }

        // find destination archetype
        final destType = type.copy();
        final typeIndex = type.indexOf(componentId);
        // swap-remove
        destType[typeIndex] = destType[destType.length - 1];
        destType.pop();
        // destType.splice(type.indexOf(componentId), 1); // TODO: Ought to use swap-remove
        destType.sort((x, y) -> x - y);
        var destArchetype = findOrCreateArchetype(destType);

        // copy overlapping components from source to destination, e.g. [A, B, C] - B => [A, C]
        final sourceRow = archetype.getRow(record.row);
        final destRow = [];
        var index = 0;
        for (i => t in type) {
            if (!destType.contains(t)) {
                index++;
                continue;
            }
            destRow.push(sourceRow[index++]);
        }
        // insert entity and components into destination archetype
        destArchetype.addRow(entity, destRow);

        // remove entity and components from source archetype
        archetype.deleteRow(record.row); // TODO: We should probably swap the old entity down to the end of the `active` part of the array instead.

        // HACK: This is slow! We want to avoid this by simply marking the removed entity as inactive.
        for (i => e in archetype.ids) {
            if (i < record.row)
                continue;
            entityIndex.set(e, {
                archetype: archetype,
                row: i
            });
        }

        // Remove source archetype if it is now empty and is a leaf in the graph
        if (archetype.getRowCount() == 0) {
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

        // point the entity record to the new archetype
        var newRecord: Record = {
            archetype: destArchetype,
            row: destArchetype.getRowCount() - 1
        };
        entityIndex.set(entity, newRecord);
    }

    function findOrCreateArchetype(type: Components): Archetype {
        // trace('findOrCreateArchetype(${archetype.type}, $type)');
        // [A, C] => [A, B, C] (add B)
        // [A, B, C] => [A, C] (remove B)
        // TODO: We assume that components are either added or removed in this function, never both (e.g. [A, B] => [B, C]) and never changed (e.g. [A, B] => [A, C] is not supported)
        var node = rootArchetype;
        for (t in type) {
            if (node.type.contains(t))
                continue;
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
                final newArchetype = new Archetype(newType);
                newArchetype.edges = [
                    t => {
                        add: null,
                        remove: node,
                    }
                ];
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
        final archetype = record.archetype;
        final row = record.row;
        for (i => component in archetype.getRow(row)) {
            trace('    #$i: $component');
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
        println('"${node.type}${node.id}" [label="${node.type} (entities: ${node.getRowCount()})"];');
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
            if (t == componentId)
                return archetype.getCell(record.row, i);
        }
        return null;
    }

    public function getComponentsForEntity(entity: EntityId): Array<Any> {
        final record = entityIndex[entity];
        final archetype = record.archetype;
        return archetype.getRow(record.row);
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
        if (includes.length == 0 && excludes.length != 0)
            throw 'Cannot query with only exclude terms';
        if (includes.length == 0)
            return [];
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
            if (!match)
                continue;

            var disqualified = false;
            for (exclude in excludes) {
                if (archetype.type.contains(exclude)) {
                    disqualified = true;
                    break;
                }
            }
            if (disqualified)
                continue;

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

    public function query(expression: Expression, fn: (entities: Array<EntityId>, components: Array<Any>) -> Void) {
        final parsed = parseExpression(expression);
        final componentsForTerms = [for (_ in parsed.includes) []];
        final archetypes = queryArchetypes(parsed.includes, parsed.excludes);
        var entities = [];

        for (archetype in archetypes) {
            entities = entities.concat(archetype.ids); // TODO: Not very elegant!
        }
        for (i => term in parsed.includes) {
            for (archetype in archetypes) {
                // TODO: Could we avoid creating and copying arrays here? Maybe allow `fn` to index into the component arrays of the different archetypes?
                final termData = archetype.getColumn(archetype.type.indexOf(term));
                componentsForTerms[i] = componentsForTerms[i].concat(termData);
            }
        }
        // trace('componentsForTerms: $componentsForTerms');
        fn(entities, componentsForTerms);
    }

    public function queryEach(expression: Expression, fn: (entity: EntityId, components: Array<Any>) -> Void) {
        query(expression, (entities, components) -> {
            if (entities.length == 0) return;
            final rows = entities.length;
            for (rowIndex in 0...rows) {
                final row = [];
                for (c in components) {
                    final column: Array<Any> = c;
                    row.push(column[rowIndex]);
                }
                fn(entities[rowIndex], row);
            }
        });
    }

    public function getEntitiesWithComponents(expression: Expression): Array<EntityId> {
        final parsed = parseExpression(expression);
        final archetypes = queryArchetypes(parsed.includes, parsed.excludes);
        return Lambda.flatten([
            for (node in archetypes) {
                node.ids;
            }
        ]);
    }

    public function hasComponent(entity: EntityId, componentId: EntityId): Bool {
        // TODO: This can be improved (and some other code may be simplified) by using a component index, see https://ajmmertens.medium.com/building-an-ecs-1-where-are-my-entities-and-components-63d07c7da742 and https://ajmmertens.medium.com/building-an-ecs-2-archetypes-and-vectorization-fe21690805f9
        return entityIndex[entity].archetype.type.contains(componentId);
    }

    public function save() {
        final data = [];
        var queue = [rootArchetype];
        while (queue.length != 0) {
            final node = queue.pop();
            if (node.getRowCount() != 0) {
                final entityData = [
                    for (i in 0...node.getRowCount()) {
                        node.getRow(i);
                    }
                ];
                data.push({
                    type: node.type,
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
}
