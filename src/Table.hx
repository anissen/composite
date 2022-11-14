package;

import Composite.Components;
import Composite.EntityId;
import haxe.exceptions.NotImplementedException;

class Table {
    /*
        TODO:
        Handle table of colums. Each column has the same number of rows. The first column is the entity id, the rest are the components.

        Must support the following actions:
        - Add a new row (could be reusing an deleted row)
        - Delete a row (i.e. mark it as deleted by moving it to the end)
        - Get the live number of rows
        - Move a row from one table to another (potentially with more or fewer columns)
     */
    final ids: Array<EntityId>;

    public final type: Components; // array of component ID's

    // final edges: Map<EntityId, Composite.Edge>;
    final columns: Array<Array<Any>>;

    public function new(type: Components) {
        ids = [];
        this.type = type;
        // edges = [];
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

        // TODO: We should probably swap the old entity down to the end of the `active` part of the array instead. Or at least to a swap-remove
        // ids.splice(row, 1);
        swapRemove(ids, row);
        for (c in columns) {
            // c.splice(row, 1);
            swapRemove(c, row);
        }
    }

    public function getColumnCount(): Int {
        return type.length;
    }

    public function getId(row: Int): EntityId {
        if (row < 0 || row >= ids.length) throw 'row $row is out of bounds';
        return ids[row];
    }

    public function getRow(row: Int): Array<Any> {
        if (row < 0 || row >= ids.length) throw 'row $row is out of bounds';
        return [for (c in columns) c[row]];
    }

    public function getRowCount(): Int {
        return ids.length;
    }

    public function getLiveRowCount() {
        throw new NotImplementedException();
    }

    // TODO: We need specific function to handling moving when adding and moving when deleting a component
    // public function moveRow(row: Int, dest: Table) {
    //     if (row < 0 || row >= ids.length)
    //         throw 'row $row is out of bounds';
    //     if (dest.type.length == type.length)
    //         throw 'both tables have the same type length -- we expect rows to be move due to adding/removing a single component';
    //     // TODO: Handle moving to dest with more of fewer columns
    //     final sourceRow = getRow(row);
    //     final destRow = [];
    //     // move and remove a component ([A, B] => [B])
    //     if (dest.type.length < type.length) {
    //         for (i => t in type) {
    //             if (dest.type.contains(t)) {
    //                 destRow.push(sourceRow[i]);
    //             }
    //         }
    //     } else { // move and add a component ([A] => [A, B])
    //         for (i => t in dest.type) {
    //             if (type.contains(t)) {
    //                 destRow.push(sourceRow[i]);
    //             }
    //         }
    //     }
    //     // copy overlapping components from source to destination
    //     // HACK: This is slow! We want to avoid this by simply marking the removed entity as inactive.
    //     for (i => e in archetype.entityIds) {
    //         if (i < record.row)
    //             continue;
    //         entityIndex.set(e, {
    //             archetype: archetype,
    //             row: i
    //         });
    //     }
    //     final id = ids[row];
    //     dest.addRow(id, getRow(row));
    //     deleteRow(row);
    // }

    public function print() {
        trace('| id | ${[for (i => _ in columns) "data" + (i + 1)].join(" | ")} |');
        trace('-----------------------');
        for (i => id in ids) {
            final rowStr = [for (c in columns) c[i]].join(' | ');
            trace('| $id | $rowStr |');
        }
    }
}
