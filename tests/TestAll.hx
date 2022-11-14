package tests;

using utest.Assert;

class TestAll {
	public static function main() {
		utest.UTest.run([new ContextTest(), new TableTest()]);
	}
}
