---@class dreamwork.std
local std = dreamwork.std

---@class dreamwork.std.protobuf
local protobuf = std.protobuf
local protobuf_parse = protobuf.parse

-- Well-known types of Google, the same files every protobuf implementation ships
-- https://github.com/protocolbuffers/protobuf/tree/main/src/google/protobuf

protobuf_parse( [[
    syntax = "proto3";
    package google.protobuf;

    message Struct {
        map<string, Value> fields = 1;
    }

    message Value {
        oneof kind {
            NullValue null_value = 1;
            double number_value = 2;
            string string_value = 3;
            bool bool_value = 4;
            Struct struct_value = 5;
            ListValue list_value = 6;
        }
    }

    enum NullValue {
        NULL_VALUE = 0;
    }

    message ListValue {
        repeated Value values = 1;
    }
]], "google/protobuf/struct.proto" )

protobuf_parse( [[
    syntax = "proto3";
    package google.protobuf;

    message DoubleValue { double value = 1; }
    message FloatValue { float value = 1; }
    message Int64Value { int64 value = 1; }
    message UInt64Value { uint64 value = 1; }
    message Int32Value { int32 value = 1; }
    message UInt32Value { uint32 value = 1; }
    message BoolValue { bool value = 1; }
    message StringValue { string value = 1; }
    message BytesValue { bytes value = 1; }
]], "google/protobuf/wrappers.proto" )

protobuf_parse( [[
    syntax = "proto3";
    package google.protobuf;

    message Any {
        string type_url = 1;
        bytes value = 2;
    }
]], "google/protobuf/any.proto" )

protobuf_parse( [[
    syntax = "proto3";
    package google.protobuf;

    message Timestamp {
        int64 seconds = 1;
        int32 nanos = 2;
    }
]], "google/protobuf/timestamp.proto" )

protobuf_parse( [[
    syntax = "proto3";
    package google.protobuf;

    message Duration {
        int64 seconds = 1;
        int32 nanos = 2;
    }
]], "google/protobuf/duration.proto" )

protobuf_parse( [[
    syntax = "proto3";
    package google.protobuf;

    message Empty {}
]], "google/protobuf/empty.proto" )

protobuf_parse( [[
    syntax = "proto3";
    package google.protobuf;

    message FieldMask {
        repeated string paths = 1;
    }
]], "google/protobuf/field_mask.proto" )

-- dreamwork types

protobuf_parse( [[
    syntax = "proto3";
    package dreamwork;

    message Vector2 {
        double x = 1;
        double y = 2;
    }

    message Vector3 {
        double x = 1;
        double y = 2;
        double z = 3;
    }

    message Angle3 {
        double pitch = 1;
        double yaw = 2;
        double roll = 3;
    }

    message Quaternion {
        double w = 1;
        double x = 2;
        double y = 3;
        double z = 4;
    }

    message VMatrix {
        double m11 = 1; double m12 = 2; double m13 = 3; double m14 = 4;
        double m21 = 5; double m22 = 6; double m23 = 7; double m24 = 8;
        double m31 = 9; double m32 = 10; double m33 = 11; double m34 = 12;
        double m41 = 13; double m42 = 14; double m43 = 15; double m44 = 16;
    }

    // magnitude as little-endian 16-bit limbs, `negative` is kept for -0
    message BigInteger {
        repeated uint32 limbs = 1;
        bool negative = 2;
    }
]], "dreamwork/math.proto" )

protobuf_parse( [[
    syntax = "proto3";
    package dreamwork;

    message Version {
        uint32 major = 1;
        uint32 minor = 2;
        uint32 patch = 3;
        string pre_release = 4;
        string build = 5;
    }
]], "dreamwork/types.proto" )

protobuf_parse( [[
    syntax = "proto3";
    package dreamwork;

    import "google/protobuf/struct.proto";

    message FluentNumber {
        double value = 1;
        google.protobuf.Struct options = 2;
    }

    message FluentDateTime {
        double value = 1;
        google.protobuf.Struct options = 2;
    }
]], "dreamwork/fluent.proto" )

protobuf_parse( [[
    syntax = "proto3";
    package dreamwork;

    // the SteamID64, `{ low, high }`
    message SteamID {
        fixed64 steam_id = 1;
    }

    // the player entity index, `0` if it is not known
    message Client {
        uint32 index = 1;
    }
]], "dreamwork/engine.proto" )
