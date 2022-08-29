from typing import Optional
import logging
import pathlib
import coloredlogs
from rawtypes.parser.header import Header, StructConfiguration
from rawtypes.parser.type_context import ParamContext
from rawtypes.interpreted_types.basetype import BaseType
from rawtypes.interpreted_types import ReferenceType
from rawtypes.generator.zig_generator import ZigGenerator

LOGGER = logging.getLogger(__name__)
HERE = pathlib.Path(__file__).absolute().parent
WORKSPACE = HERE.parent


def generate_glfw():
    GLFW_HEADER = WORKSPACE / 'pkgs/glfw/pkgs/glfw/include/GLFW/glfw3.h'
    GLFW_ZIG = WORKSPACE / 'pkgs/glfw/src/main.zig'
    LOGGER.debug(f'{GLFW_HEADER.name} => {GLFW_ZIG}')
    generator = ZigGenerator(Header(GLFW_HEADER))
    generator.generate(GLFW_ZIG)


def generate_nanovg():
    NANOVG_HEADER = WORKSPACE / 'pkgs/nanovg/pkgs/picovg/src/nanovg.h'
    NANOVG_ZIG = WORKSPACE / 'pkgs/nanovg/src/main.zig'
    LOGGER.debug(f'{NANOVG_HEADER.name} => {NANOVG_ZIG}')
    generator = ZigGenerator(Header(NANOVG_HEADER))
    generator.generate(NANOVG_ZIG)


def generate_imgui():
    IMGUI_HEADER = WORKSPACE / '_external/imgui/imgui.h'
    # IMGUI_HEADER_INTERNAL = WORKSPACE / '_external/imgui/pkgs/imgui/imgui_internal.h'
    # IMGUI_IMPL_GLFW = WORKSPACE / '_external/imgui/pkgs/imgui/backends/imgui_impl_glfw.h'
    # IMGUI_IMPL_OPENGL3 = WORKSPACE / \
    #     '_external/imgui/pkgs/imgui/backends/imgui_impl_opengl3.h'
    IMGUI_ZIG = WORKSPACE / 'pkgs/imgui/src/main.zig'
    LOGGER.debug(f'{IMGUI_HEADER.name} => {IMGUI_ZIG}')

    headers = [
        Header(IMGUI_HEADER, include_dirs=[IMGUI_HEADER.parent],
               structs=[
                   StructConfiguration('ImFontAtlas', methods=True),
                   StructConfiguration('ImDrawList', methods=True),
        ],
            begin='''
pub const ImVector = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: *anyopaque,
};

const STB_TEXTEDIT_UNDOSTATECOUNT = 99;
const STB_TEXTEDIT_UNDOCHARCOUNT = 999;
const STB_TEXTEDIT_POSITIONTYPE = c_int;
const STB_TEXTEDIT_CHARTYPE = u16;
const ImWchar = u16;
const ImGuiTableColumnIdx = i8;
const ImGuiTableDrawChannelIdx = u8;
const ImTextureID = *anyopaque;
const ImFileHandle = *anyopaque;
const ImGuiKey_NamedKey_BEGIN         = 512;
const ImGuiKey_NamedKey_END           = 0x285; //ImGuiKey_COUNT;
const ImGuiKey_NamedKey_COUNT         = ImGuiKey_NamedKey_END - ImGuiKey_NamedKey_BEGIN;

pub const ImSpan = extern struct {
    Data: *anyopaque,
    DataEnd: *anyopaque,
};

pub const ImChunkStream = extern struct {
    Buf: ImVector,
};

pub const ImPool = extern struct {
    Buf: ImVector,
    Map: ImGuiStorage,
    FreeIdx: i32,
    AliveCount: i32,
};

pub const ImBitArray = extern struct {
    Storage: [(ImGuiKey_NamedKey_COUNT + 31) >> 5]u32,
};
pub const ImBitArrayForNamedKeys = ImBitArray;

pub const StbUndoRecord = extern struct {
    where: STB_TEXTEDIT_POSITIONTYPE,
    insert_length: STB_TEXTEDIT_POSITIONTYPE,
    delete_length: STB_TEXTEDIT_POSITIONTYPE,
    char_storage: c_int,
};

pub const StbUndoState = extern struct {
    undo_rec: [STB_TEXTEDIT_UNDOSTATECOUNT]StbUndoRecord,
    undo_char: [STB_TEXTEDIT_UNDOCHARCOUNT]STB_TEXTEDIT_CHARTYPE,
    undo_point: c_short,
    redo_point: c_short,
    undo_char_point: c_int,
    redo_char_point: c_int,
};

pub const STB_TexteditState = extern struct {
   cursor: c_int,
   select_start: c_int,
   select_end: c_int,
   insert_mode: u8,
   row_count_per_page: c_int,
   cursor_at_end_of_line: u8,
   initialized: u8,
   has_preferred_x: u8,
   single_line: u8,
   padding1: u8,
   padding2: u8,
   padding3: u8,
   preferred_x: f32,
   undostate: StbUndoState,
};

pub extern fn Custom_ButtonBehaviorMiddleRight() void;
'''),
        # Header(IMGUI_HEADER_INTERNAL,
        #        if_include=lambda f_name: f_name == 'ButtonBehavior'),
        # Header(IMGUI_IMPL_GLFW),
        # Header(IMGUI_IMPL_OPENGL3),
    ]

    generator = ZigGenerator(*headers)

    def custom(t: BaseType) -> Optional[str]:
        for template in ('ImVector', 'ImSpan', 'ImChunkStream', 'ImPool', 'ImBitArray'):
            if t.name.startswith(f'{template}<'):
                return template

        if t.name == 'ImStb::STB_TexteditState':
            return 'STB_TexteditState'

    workarounds = generator.generate(
        IMGUI_ZIG, custom=custom, return_byvalue_workaround=True)

    #
    # return byvalue to pointer
    #
    IMGUI_CPP_WORKAROUND = IMGUI_ZIG.parent / 'imvec2_byvalue.cpp'
    with IMGUI_CPP_WORKAROUND.open('w') as w:
        w.write(f'''// https://github.com/ziglang/zig/issues/1481 workaround
#include <imgui.h>

#ifdef __cplusplus
extern "C" {{
#endif
{"".join([w.code for w in workarounds if w.f.path == IMGUI_HEADER])}
#ifdef __cplusplus
}}
#endif        
''')


def generate_imnodes():
    IMNODES_HEADER = WORKSPACE / 'pkgs/imnodes/pkgs/imnodes/imnodes.h'
    IMNODES_ZIG = WORKSPACE / 'pkgs/imnodes/src/main.zig'
    LOGGER.debug(f'{IMNODES_HEADER.name} => {IMNODES_ZIG}')
    generator = ZigGenerator(Header(IMNODES_HEADER))
    generator.generate(IMNODES_ZIG)


def main():
    coloredlogs.install(level='DEBUG')
    logging.basicConfig(level=logging.DEBUG)
    # generate_glfw()
    generate_imgui()
    # generate_nanovg()
    # generate_imnodes()


if __name__ == '__main__':
    main()
