//! Used to represent a UI element with a toString method, position, and visibility state.
//! Additionally a cursorContainer can be attatched if the Stringable struct also handles 
//! cursor state.
const lib = @import("lib");
const Stringable = lib.interfaces.Stringable;
const CursorContainer = lib.interfaces.CursorContainer;
const Vec2 = lib.types.Vec2;

stringable: Stringable,
cursorContainer: ?CursorContainer = null,
position: Vec2,
is_visible: bool,
