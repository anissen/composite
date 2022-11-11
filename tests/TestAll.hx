package tests;

using utest.Assert;

class TestAll {
  public static function main() {
    utest.UTest.run([new TestCase(), new TableTests()]);
  }
}

@:structInit
final class TestComponent implements Composite.Component {}
@:structInit
final class AnotherComponent implements Composite.Component {}

class TestCase extends utest.Test {
    function testFirstEntityId() {
      final context = new Composite.Context();
      final e = context.createEntity();
      Assert.equals(e, 0);
    }

    function testHasComponentAfterAddingComponent() {
      final context = new Composite.Context();
      final e = context.createEntity();
      Assert.isFalse(context.hasComponent(e, TestComponent.ID));
      context.addComponent(e, ({}: TestComponent));
      Assert.isTrue(context.hasComponent(e, TestComponent.ID));
    }

    function testEntitiesWithComponentsInDifferentOrderHasSameArchetype() {
      final context = new Composite.Context();
      final e1 = context.createEntity();
      context.addComponent(e1, ({}: TestComponent));
      context.addComponent(e1, ({}: AnotherComponent));
      final e2 = context.createEntity();
      context.addComponent(e2, ({}: AnotherComponent));
      context.addComponent(e2, ({}: TestComponent));
      final entities = context.getEntitiesWithComponents(Group([Include(TestComponent.ID), Include(AnotherComponent.ID)]));
      Assert.equals(2, entities.length);
    }
}

class TableTests extends utest.Test {
    function testCanInstatiate() {
        var table = new Table(4);
        Assert.isTrue(table != null);
    }
}