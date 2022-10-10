package tests;

using utest.Assert;

class TestAll {
  public static function main() {
    utest.UTest.run([new TestCase(), new TableTests()]);
  }
}

@:structInit
final class TestComponent implements Composite.Component {}

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
}

class TableTests extends utest.Test {
    function testCanInstatiate() {
        var table = new Table(4);
        Assert.isTrue(table != null);
    }
}