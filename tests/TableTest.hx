package tests;

import utest.Assert;

@:structInit
final class TestPositionComponent implements Composite.Component {
    public final x: Float;
    public final y: Float;
}

@:structInit
final class TestColorComponent implements Composite.Component {
    public final color: String;
}

class TableTest extends utest.Test {
    function testInstatiate() {
        final table = new Table([]);
        Assert.isTrue(table != null);
        Assert.equals(0, table.getRowCount());
    }

    function testInsertTypedRow() {
        final table = new Table([TestPositionComponent.ID, TestColorComponent.ID]);
        table.addRow(0, [
            ({x: 23, y: 45.7}: TestPositionComponent),
            ({color: 'blue'}: TestColorComponent),
        ]);
        Assert.equals(1, table.getRowCount());
    }

    function testInsertGetRow() {
        final table = new Table([TestPositionComponent.ID, TestColorComponent.ID]);
        table.addRow(0, [
            ({x: 23, y: 45.7}: TestPositionComponent),
            ({color: 'blue'}: TestColorComponent),
        ]);
        final row = table.getRow(0);
        Assert.equals(2, row.length);
        final pos: TestPositionComponent = row[0];
        Assert.equals(23, pos.x);
        Assert.equals(45.7, pos.y);
        final color: TestColorComponent = row[1];
        Assert.equals('blue', color.color);
    }

    function testInsertRowWithInvalidColumnLength() {
        final table = new Table([TestPositionComponent.ID, TestColorComponent.ID]);
        Assert.raises(table.addRow.bind(42, [{x: 4, y: 3}]));
        Assert.raises(table.addRow.bind(42, [{x: 4, y: 3}, {color: 'red'}, {z: 3}]));
    }

    function testDeleteRow() {
        final table = new Table([]);
        Assert.equals(0, table.getRowCount());
        Assert.raises(table.deleteRow.bind(0));
        Assert.raises(table.deleteRow.bind(-1));
        table.addRow(42, []);
        Assert.equals(1, table.getRowCount());
        Assert.raises(table.deleteRow.bind(1));
        table.deleteRow(0);
        Assert.equals(0, table.getRowCount());
    }

    function testMoveRow() {
        final table = new Table([TestPositionComponent.ID, TestColorComponent.ID]);
        table.addRow(0, [
            ({x: 23, y: 45.7}: TestPositionComponent),
            ({color: 'blue'}: TestColorComponent),
        ]);
        final table2 = new Table([TestPositionComponent.ID, TestColorComponent.ID]);
        table.moveRow(0, table2);
        Assert.equals(0, table.getRowCount());
        Assert.equals(1, table2.getRowCount());
        final row = table2.getRow(0);
        final color = (row[1]: TestColorComponent);
        Assert.equals('blue', color.color);
    }
}
