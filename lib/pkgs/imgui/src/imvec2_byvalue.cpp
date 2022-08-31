// https://github.com/ziglang/zig/issues/1481 workaround
#include <imgui.h>

#ifdef __cplusplus
extern "C" {
#endif

void imgui_GetWindowPos(ImVec2 *__ret__)
{
    *__ret__ = ImGui::GetWindowPos();
}

void imgui_GetWindowSize(ImVec2 *__ret__)
{
    *__ret__ = ImGui::GetWindowSize();
}

void imgui_GetContentRegionAvail(ImVec2 *__ret__)
{
    *__ret__ = ImGui::GetContentRegionAvail();
}

void imgui_GetContentRegionMax(ImVec2 *__ret__)
{
    *__ret__ = ImGui::GetContentRegionMax();
}

void imgui_GetWindowContentRegionMin(ImVec2 *__ret__)
{
    *__ret__ = ImGui::GetWindowContentRegionMin();
}

void imgui_GetWindowContentRegionMax(ImVec2 *__ret__)
{
    *__ret__ = ImGui::GetWindowContentRegionMax();
}

void imgui_GetFontTexUvWhitePixel(ImVec2 *__ret__)
{
    *__ret__ = ImGui::GetFontTexUvWhitePixel();
}

void imgui_GetCursorPos(ImVec2 *__ret__)
{
    *__ret__ = ImGui::GetCursorPos();
}

void imgui_GetCursorStartPos(ImVec2 *__ret__)
{
    *__ret__ = ImGui::GetCursorStartPos();
}

void imgui_GetCursorScreenPos(ImVec2 *__ret__)
{
    *__ret__ = ImGui::GetCursorScreenPos();
}

void imgui_GetItemRectMin(ImVec2 *__ret__)
{
    *__ret__ = ImGui::GetItemRectMin();
}

void imgui_GetItemRectMax(ImVec2 *__ret__)
{
    *__ret__ = ImGui::GetItemRectMax();
}

void imgui_GetItemRectSize(ImVec2 *__ret__)
{
    *__ret__ = ImGui::GetItemRectSize();
}

void imgui_CalcTextSize(ImVec2 *__ret__, const char * text, const char * text_end, bool hide_text_after_double_hash, float wrap_width)
{
    *__ret__ = ImGui::CalcTextSize(text, text_end, hide_text_after_double_hash, wrap_width);
}

void imgui_ColorConvertU32ToFloat4(ImVec4 *__ret__, ImU32 _in)
{
    *__ret__ = ImGui::ColorConvertU32ToFloat4(_in);
}

void imgui_GetMousePos(ImVec2 *__ret__)
{
    *__ret__ = ImGui::GetMousePos();
}

void imgui_GetMousePosOnOpeningCurrentPopup(ImVec2 *__ret__)
{
    *__ret__ = ImGui::GetMousePosOnOpeningCurrentPopup();
}

void imgui_GetMouseDragDelta(ImVec2 *__ret__, ImGuiMouseButton button, float lock_threshold)
{
    *__ret__ = ImGui::GetMouseDragDelta(button, lock_threshold);
}

#ifdef __cplusplus
}
#endif        
