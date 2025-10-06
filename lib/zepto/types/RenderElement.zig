//! Used to represent a UI element with a toString method, position, and visibility state.
//! Additionally a cursorContainer can be attatched if the Stringable struct also handles
//! cursor state.
const interfaces = @import("../interfaces.zig");
const Stringable = interfaces.Stringable;
const CursorContainer = interfaces.CursorContainer;
const Vec2 = @import("Vec2.zig");

stringable: Stringable,
cursor_container: ?CursorContainer = null,
position: Vec2,
is_visible: bool,
