# Composite

A tiny [entity component system](https://en.wikipedia.org/wiki/Entity_component_system) library.

Composite is not meant to be used directly but instead to be integrated into other libraries, frameworks or game engines.

I am using Composite in some of my own projects; [Cosy](https://github.com/anissen/cosy) (a programming language) and [Crafty](https://github.com/anissen/crafty) (a game engine).

---

:warning: **This project is a pre-alpha work-in-progress.**

Also, Composite will probably never have broad applicability as I'm making this library to fit my own purposes.

---

## Example usage in regular Haxe code
```haxe
@:structInit
final class Position implements Component {
    public var x: Float;
    public var y: Float;
}

@:structInit
final class Velocity implements Component {
    public var x: Float;
    public var y: Float;
}

final context = new Composite.Context();

// create entity
final e = context.createEntity('Player');
context.addComponents(e, [
    ({x: 200, y: 200}: Position),
    ({x: 1.2, y: -3.4}: Velocity),
]);

// query entities
context.queryEach(Group([Include(Position.ID), Include(Velocity.ID)]), (entity, components) -> {
    final pos: Position = components[0];
    final vel: Velocity = components[1];
    pos.x += vel.x * delta;
    pos.y += vel.y * delta;
});
```

## Example usage in [Cosy](https://github.com/anissen/cosy)
```rust
struct Position {
    mut x Num
    mut y Num
}
struct Velocity {
    mut x Num
    mut y Num
}

// create entity
spawn(
    Position { x = 200, y = 200 }, 
    Velocity { x = 1.2, y = -3.4 }
)

// query entities
query mut Position p, Velocity v {
    p.x += v.x * delta
    p.y += v.y * delta
}
``` 