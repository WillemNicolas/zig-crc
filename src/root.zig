const std = @import("std");

const CRC_POLYNOMIAL = 0x04C11DB7;
const CRC_REVERSED_POLYNOMIAL = 0xEDB88320;

const LOOKUP_TABLE = blk : {
    @setEvalBranchQuota(2500);
    var table : [256]u32 = undefined;
    for (&table,0..) |*e, i| {
        var j: usize = 0;
        var crc: u32 = i;
        while (j < 8) : (j += 1) {
            crc = (crc >> 1) ^ ((crc & 1) * CRC_REVERSED_POLYNOMIAL);
        }
        e.* = crc;
    }

    break :blk table;
};

pub fn compute_crc(bytes: []const u8) u32 {
    var crc: u32 = 0xFFFFFFFF;
    
    for (LOOKUP_TABLE) |byte| {
        std.debug.print("{x}\n", .{byte});
    }
    for (bytes) |byte| {
        crc ^= byte;
        crc = (LOOKUP_TABLE[crc & 0xFF]) ^ (crc >> 8);
    }

    return ~crc;
}

pub fn check_crc(bytes: []const u8, crc: u32) bool {
    const crc_computed = compute_crc(bytes);
    return crc_computed == crc;
}


test "Compute CRC" {

    const TestData = struct {
        data : []const u8,
    };

    const data = TestData {
        .data = "Hello World",
    };

    const crc_computed = compute_crc(data.data);
    const crc_expected = std.hash.Crc32.hash(data.data);
    try std.testing.expect(crc_computed == crc_expected);
}



test "Check CRC" {

    const TestData = struct {
        data : []const u8,
    };

    const data = TestData {
        .data = "Hello World",
    };

    const crc_computed = compute_crc(data.data);
    try std.testing.expect(check_crc(data.data, crc_computed));
    try std.testing.expect(!check_crc(data.data, 0x12345678));
}
