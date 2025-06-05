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

fn setStateFlags(initial_state: termios, value: bool) termios {
    var new_state = initial_state;

    var lflag = initial_state.lflag;
    var oflag = initial_state.oflag;
    var iflag = initial_state.iflag;

    lflag.ISIG, lflag.ECHO, lflag.ICANON, lflag.IEXTEN = .{value} ** 4;
    oflag.OPOST = value;
    iflag.IXON, iflag.ICRNL, iflag.BRKINT, iflag.INPCK, iflag.ISTRIP = .{value} ** 5;

    new_state.iflag = iflag;
    new_state.lflag = lflag;
    new_state.oflag = oflag;
    return new_state;
}

pub fn setBtyeRead(self: *Terminal, timeout: u8, minimumBtyes: u8) void {
    self.state.cc[@intFromEnum(std.os.linux.V.TIME)] = timeout;
    self.state.cc[@intFromEnum(std.os.linux.V.MIN)] = minimumBtyes;
}

pub fn enableRawMode(self: *Terminal) Error!void {
    self.state = setStateFlags(self.state, false);
    self.setBtyeRead(0, 1);
    if (linux.tcsetattr(linux.STDIN_FILENO, linux.TCSA.FLUSH, &self.state) != 0) {
        return Error.FailedToSetTermios;
    }
}

pub fn disableRawMode(self: *Terminal) Error!void {
    self.state = setStateFlags(self.state, true);

    if (linux.tcsetattr(linux.STDIN_FILENO, linux.TCSA.FLUSH, &self.state) != 0) {
        return error.FailedToSetTermios;
    }
}
