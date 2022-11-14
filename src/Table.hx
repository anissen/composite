package;

import Composite.EntityId;

/* Handle table of colums. Each column has the same number of rows. The first column is the entity id, the rest are the components. */
class Table {
    public final ids: Array<EntityId>; // TODO: Make this private maybe?

    final columns: Array<Array<Any>>;

    public function new(numberOfColumns: Int) {
        ids = [];
        columns = [for (_ in 0...numberOfColumns) []];
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
        if (row < 0 || row >= ids.length) throw 'row $row is out of bounds';
        final rowData = columns[row];
        if (column < 0 || column >= rowData.length) throw 'column $column is out of bounds';
        return rowData[column];
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
}