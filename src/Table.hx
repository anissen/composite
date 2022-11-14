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
    final type: Components; // array of component ID's
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

    public function deleteRow(row: Int) {
        if (row < 0 || row >= ids.length)
            throw 'row $row is out of bounds';

        // TODO: Implement a better row deletion (swap and mark dead?)
        ids.splice(row, 1);
        for (c in columns) {
            c.splice(row, 1);
        }
    }

    public function getColumnCount(): Int {
        return type.length;
    }

    public function getRow(row: Int): Array<Any> {
        return [for (c in columns) c[row]];
    }

    public function getRowCount(): Int {
        return ids.length;
    }

    public function getLiveRowCount() {
        throw new NotImplementedException();
    }

    public function moveRow(row: Int, dest: Table) {
        if (row < 0 || row >= ids.length)
            throw 'row $row is out of bounds';
        if (dest.getColumnCount() != getColumnCount()) throw 'destination table column count does not match source table column count';

        final id = ids[row];
        dest.addRow(id, getRow(row));
        deleteRow(row);
    }

    public function print() {
        trace('| id | ${[for (i => c in columns) "data" + (i + 1)].join(" | ")} |');
        trace('-----------------------');
        for (i => id in ids) {
            final rowStr = [for (c in columns) c[i]].join(' | ');
            trace('| $id | $rowStr |');
        }
    }
}
