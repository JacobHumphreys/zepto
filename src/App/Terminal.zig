const std = @import("std");
const linux = std.os.linux;
const termios = linux.termios;
const Terminal = @This();

state: termios,

pub const Error = error{
    FailedToGetTermios,
    FailedToSetTermios,
};

pub fn init() Error!Terminal {
    var og_termios: termios = undefined;

    if (linux.tcgetattr(linux.STDIN_FILENO, &og_termios) != 0) {
        return Error.FailedToGetTermios;
    }
    return Terminal{
        .state = og_termios,
    };
}

pub fn enableRawMode(self: *Terminal) Error!void {
    self.state.lflag.ISIG, self.state.lflag.ECHO, self.state.lflag.ICANON = .{false} ** 3;
    if (linux.tcsetattr(linux.STDIN_FILENO, linux.TCSA.FLUSH, &self.state) != 0) {
        return Error.FailedToSetTermios;
    }
}

pub fn disableRawMode(self: *Terminal) Error!void {
    self.state.lflag.ISIG, self.state.lflag.ECHO, self.state.lflag.ICANON = .{true} ** 3;

    if (linux.tcsetattr(linux.STDIN_FILENO, linux.TCSA.FLUSH, &self.state) != 0) {
        return error.FailedToSetTermios;
    }
}
