const std = @import("std");
const WINAPI = std.os.windows.WINAPI;

const canvas_width = 300;
const canvas_height = 300;

pub fn main() void {
    const hInstance = win32.GetModuleHandleA(null) orelse return;
    const atom = win32.RegisterClassExA(&.{
        .lpfnWndProc = myWndProc,
        .hInstance = hInstance,
        .hCursor = win32.LoadCursorA(null, @ptrFromInt(32512)),
        .hbrBackground = @as(*anyopaque, @ptrFromInt(7 + 1)),
        .lpszClassName = "MyWindowClass",
    });

    if (atom == 0) return;

    const style = win32.WS_VISIBLE | win32.WS_SYSMENU | win32.WS_CAPTION;
    var rect = std.os.windows.RECT{
        .left = 0,
        .top = 0,
        .right = canvas_width,
        .bottom = canvas_height,
    };

    _ = win32.AdjustWindowRect(&rect, style, 0);

    const hwnd = win32.CreateWindowExA(
        0,
        @ptrFromInt(@as(usize, @intCast(atom))),
        "MyWindow",
        style,
        win32.CW_USEDEFAULT,
        win32.CW_USEDEFAULT,
        rect.right - rect.left,
        rect.bottom - rect.top,
        null,
        null,
        null,
        null,
    );

    while (hwnd) |_| {
        var msg: win32.MSG = undefined;
        switch (win32.GetMessageA(&msg, null, 0, 0)) {
            0 => break,
            -1 => break,
            else => {
                _ = win32.DispatchMessageA(&msg);
            },
        }
    }
}

fn myWndProc(hwnd: *anyopaque, uMsg: u32, wParam: usize, lParam: isize) callconv(WINAPI) isize {
    switch (uMsg) {
        0x0010 => { // WM_CLOSE
            _ = win32.PostQuitMessage(0);
        },
        0x000F => { // WM_PAINT
            myPaintFn(hwnd);
        },
        else => {},
    }
    return win32.DefWindowProcA(hwnd, uMsg, wParam, lParam);
}

fn myPaintFn(hwnd: *anyopaque) void {
    var info: win32.PAINTSTRUCT = undefined;
    const hDC = win32.BeginPaint(hwnd, &info) orelse return;

    const brushes = [_]i32{ 3, 2, 1, 0 };
    inline for (brushes, 0..) |brush, n| {
        _ = win32.FillRect(hDC, &.{
            .left = (n + 1) * 10,
            .top = (n + 1) * 10,
            .right = canvas_width - (n + 1) * 10,
            .bottom = canvas_height - (n + 1) * 10,
        }, win32.GetStockObject(brush));
    }

    _ = win32.EndPaint(hwnd, &info);
}

const win32 = struct {
    // WinAPI constants
    const CW_USEDEFAULT: i32 = @bitCast(@as(u32, 0x80000000)); // sign bit of an i32
    const WS_VISIBLE = 0x10000000;
    const WS_SYSMENU = 0x00080000;
    const WS_CAPTION = 0x00C00000;

    // WinAPI typedefs
    const POINT = std.os.windows.POINT;
    const RECT = std.os.windows.RECT;
    const MSG = extern struct { hWnd: ?*anyopaque, message: u32, wParam: usize, lParam: isize, time: u32, pt: POINT, lPrivate: u32 };
    const WNDCLASSEXA = extern struct {
        cbSize: u32 = @sizeOf(@This()),
        style: u32 = 0,
        lpfnWndProc: *const fn (*anyopaque, u32, usize, isize) callconv(WINAPI) isize,
        cbClsExtra: i32 = 0,
        cbWndExtra: i32 = 0,
        hInstance: *anyopaque,
        hIcon: ?*anyopaque = null,
        hCursor: ?*anyopaque = null,
        hbrBackground: ?*anyopaque = null,
        lpszMenuName: ?[*:0]const u8 = null,
        lpszClassName: [*:0]const u8,
        hIconSm: ?*anyopaque = null,
    };
    const PAINTSTRUCT = extern struct {
        hdc: *anyopaque,
        fErase: i32,
        rcPaint: RECT,
        fRestore: i32,
        fIncUpdate: i32,
        rgbReserved: [32]u8,
    };

    // WinAPI DLL functions
    extern "kernel32" fn GetModuleHandleA(?[*:0]const u8) callconv(WINAPI) ?*anyopaque;
    extern "user32" fn GetMessageA(*MSG, ?*anyopaque, u32, u32) callconv(WINAPI) i32;
    extern "user32" fn DispatchMessageA(*MSG) callconv(WINAPI) isize;
    extern "user32" fn DefWindowProcA(*anyopaque, u32, usize, isize) callconv(WINAPI) isize;
    extern "user32" fn PostQuitMessage(i32) callconv(WINAPI) void;
    extern "user32" fn LoadCursorA(?*anyopaque, ?*anyopaque) callconv(WINAPI) ?*anyopaque;
    extern "user32" fn RegisterClassExA(*const WNDCLASSEXA) callconv(WINAPI) u16;
    extern "user32" fn AdjustWindowRect(*std.os.windows.RECT, u32, i32) callconv(WINAPI) i32;
    extern "user32" fn CreateWindowExA(
        u32, // extended style
        ?*anyopaque, // class name/class atom
        ?[*:0]const u8, // window name
        u32, // basic style
        i32,i32,i32,i32, // x,y,w,h
        ?*anyopaque, // parent
        ?*anyopaque, // menu
        ?*anyopaque, // hInstance
        ?*anyopaque, // info to pass to WM_CREATE callback inside wndproc
    ) callconv(WINAPI) ?*anyopaque;
    extern "user32" fn BeginPaint(*anyopaque, *PAINTSTRUCT) callconv(WINAPI) ?*anyopaque;
    extern "user32" fn EndPaint(*anyopaque, *const PAINTSTRUCT) callconv(WINAPI) i32;
    extern "user32" fn FillRect(*anyopaque, *const std.os.windows.RECT, *anyopaque) callconv(WINAPI) i32;
    extern "gdi32" fn GetStockObject(i32) callconv(WINAPI) *anyopaque;
};
