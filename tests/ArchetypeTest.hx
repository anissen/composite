package tests;

import utest.Assert;
import composite.*;
import composite.Composite.Archetype;

@:structInit
final class TestPositionComponent implements Composite.Component {
    public final x: Float;
    public final y: Float;
}

@:structInit
final class TestColorComponent implements Composite.Component {
    public final color: String;
}

class ArchetypeTest extends utest.Test {
    function testInstatiate() {
        final archetype = new Archetype([]);
        Assert.isTrue(archetype != null);
        Assert.equals(0, archetype.getRowCount());
    }

    function testInsertTypedRow() {
        final archetype = new Archetype([TestPositionComponent.ID, TestColorComponent.ID]);
        archetype.addRow(0, [
            ({x: 23, y: 45.7}: TestPositionComponent),
            ({color: 'blue'}: TestColorComponent),
        ]);
        Assert.equals(1, archetype.getRowCount());
    }

    function testInsertGetRow() {
        final archetype = new Archetype([TestPositionComponent.ID, TestColorComponent.ID]);
        archetype.addRow(0, [
            ({x: 23, y: 45.7}: TestPositionComponent),
            ({color: 'blue'}: TestColorComponent),
        ]);
        final row = archetype.getRow(0);
        Assert.equals(2, row.length);
        final pos: TestPositionComponent = row[0];
        Assert.equals(23, pos.x);
        Assert.equals(45.7, pos.y);
        final color: TestColorComponent = row[1];
        Assert.equals('blue', color.color);
    }

    function testInsertRowWithInvalidColumnLength() {
        final archetype = new Archetype([TestPositionComponent.ID, TestColorComponent.ID]);
        Assert.raises(archetype.addRow.bind(42, [{x: 4, y: 3}]));
        Assert.raises(archetype.addRow.bind(42, [{x: 4, y: 3}, {color: 'red'}, {z: 3}]));
    }

    function testDeleteRowOutOfBounds() {
        final archetype = new Archetype([]);
        Assert.raises(archetype.deleteRow.bind(0));
        Assert.raises(archetype.deleteRow.bind(-1));
        archetype.addRow(42, []);
        Assert.raises(archetype.deleteRow.bind(1));
        archetype.deleteRow(0);
        Assert.equals(0, archetype.getRowCount());
    }

    function testDeleteRow() {
        final archetype = new Archetype([TestPositionComponent.ID]);
        archetype.addRow(42, [0]);
        archetype.deleteRow(0);
        Assert.equals(0, archetype.getRowCount());

        archetype.addRow(42, [0]);
        archetype.addRow(43, [1]);
        archetype.addRow(44, [2]);
        Assert.equals(3, archetype.getRowCount());
        Assert.equals(0, archetype.getRow(0)[0]);
        Assert.equals(1, archetype.getRow(1)[0]);
        Assert.equals(2, archetype.getRow(2)[0]);
        archetype.deleteRow(1);
        Assert.equals(0, archetype.getRow(0)[0]);
        Assert.equals(2, archetype.getRow(1)[0]);
    }
}
