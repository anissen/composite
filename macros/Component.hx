package macros;

#if macro

import haxe.macro.Context;

var componentID = 0;

function buildComponent() {
    final componentTypeId = componentID++;

    final pos = Context.currentPos();
    var fields = Context.getBuildFields();
    fields.push({
        name: "ID",
        access: [APublic, AStatic, AFinal, AInline],
        kind: FieldType.FVar(macro: Int, macro $v{componentTypeId}),
        pos: pos,
    });
    fields.push({
        name: "getID",
        access: [APublic],
        kind: FFun({
            args: [],
            expr: macro return $v{componentTypeId}
        }),
        pos: pos,
    });
    return fields;
}

#end