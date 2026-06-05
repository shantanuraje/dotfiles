final: prev:

# Workaround for awesome-4.3 build failure on nixpkgs 26.11+ (glib 2.88).
#
# The WM binary compiles fine, but the `generate-examples` CMake target
# runs Lua scripts that import cairo via `lgi`. glib 2.87 changed enum
# introspection so the `values` field is delivered as a Lua table instead
# of a GLib array; lgi 0.9.2's `load_enum` still calls `core.record.fromarray`
# and crashes with:
#
#     lgi/ffi.lua:87: bad argument #1 to 'fromarray' (lgi.record expected, got table)
#
# Upstream fix is lgi-devs/lgi PR #352 ("ffi: Adapt load_enum to glib 2.87
# changes") — still open as of 2026-05. The PR form doesn't apply on top
# of nixpkgs' existing arch glib-2.86.0 patch (which already removed the
# trailing type_class:unref()), so we ship a hand-rebased version at
# ./lgi-glib-2.87.patch.
#
# Remove this overlay once nixpkgs ships an lgi with PR #352 merged.

let
  patchedLua = prev.lua.override {
    packageOverrides = luaFinal: luaPrev: {
      lgi = luaPrev.lgi.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./lgi-glib-2.87.patch ];
      });
    };
  };
in
{
  awesome = prev.awesome.override { lua = patchedLua; };
}
