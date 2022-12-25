; Created by https://github.com/PolicyPuma4
; Repository https://github.com/PolicyPuma4/Find-Leftovers

#Requires AutoHotkey v2.0-beta
#SingleInstance Force

;@Ahk2Exe-Obey U_bits, = %A_PtrSize% * 8
;@Ahk2Exe-Obey U_type, = "%A_IsUnicode%" ? "Unicode" : "ANSI"
;@Ahk2Exe-ExeName %A_ScriptName~\.[^\.]+$%_%U_type%_%U_bits%

;@Ahk2Exe-SetMainIcon shell32_33.ico

if not A_IsCompiled {
    TraySetIcon("shell32_33.ico")
}

arg := A_Args.Length ? A_Args[1] : ""
if not A_IsAdmin and not arg = "restart" {
    try {
        Run("*RunAs `"" A_ScriptFullPath "`" restart")
        ExitApp()
    } catch as e {
        if not e.Extra = "The operation was canceled by the user.`r`n" {
            throw e
        }
    }
}

my_gui := Gui("Resize", "Find Leftovers")
my_gui.OnEvent("Size", GuiSize)
search_text := my_gui.AddText(,"Search")
search_edit := my_gui.AddEdit("r1")
search_edit.OnEvent("Change", SearchEditChange)
path_text := my_gui.AddText(,"Directories")
path_listbox := my_gui.AddListBox("0x8 0x100")
reg_text := my_gui.AddText(,"Registry keys")
reg_listbox := my_gui.AddListBox("0x8 0x100")
delete_button := my_gui.AddButton(, "Delete")
delete_button.OnEvent("Click", DeleteButtonClick)

my_gui.Show("w640 h480")

program_files := EnvGet("PROGRAMFILES")
program_files_86 := EnvGet("PROGRAMFILES(X86)")
user_profile := EnvGet("USERPROFILE")

dirs := [
    program_files,
    program_files "\Common Files",
    program_files_86,
    program_files_86 "\Common Files",
    A_AppDataCommon,
    user_profile,
    user_profile "\AppData\Local",
    user_profile "\AppData\Local\Programs",
    user_profile "\AppData\LocalLow",
    user_profile "\AppData\Roaming",
]

keys := [
    "HKEY_CURRENT_USER\SOFTWARE",
    "HKEY_LOCAL_MACHINE\SOFTWARE",
    "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node",
]

GuiSize(GuiObj, MinMax, Width, Height) {
    all_control_height := 0
    control_count := 0
    for control in my_gui {
        control.getPos(,,, &control_height)
        all_control_height += control_height
        control_count++
    }

    margin_y := 5
    available_space := Height - all_control_height - (control_count + 1) * margin_y
    previous_y := 0
    previous_h := 0
    for control in my_gui {
        control.GetPos(,,, &control_height)
        weight := control.Type = "ListBox" ? 0.5 : 0
        control.Move(, previous_y + previous_h + margin_y, Width - my_gui.MarginX * 2, control_height + available_space * weight)

        control.GetPos(, &previous_y,, &previous_h)
        control.Redraw()
    }
}

SearchEditChange(*) {
    path_listbox.Delete()
    reg_listbox.Delete()
    input := search_edit.Value
    if not input {
        return
    }

    for leftover_dir in dirs {
        Loop Files, leftover_dir "\*", "DF" {
            if not InStr(A_LoopFileName, input) {
                continue
            }

            path_listbox.Add([A_LoopFileFullPath])
        }
    }

    for leftover_key in keys {
        Loop Reg, leftover_key, "K" {
            if not InStr(A_LoopRegName, input) {
                continue
            }

            reg_listbox.Add([leftover_key "\" A_LoopRegName])
        }
    }
}

DeleteButtonClick(*) {
    paths := path_listbox.Text ? path_listbox.Text : Array()
    keys := reg_listbox.Text ? reg_listbox.Text : Array()
    if not paths.Length and not keys.Length {
        return
    }

    confirm := MsgBox("Are you sure?", "Find Leftovers", "YesNo Owner" my_gui.Hwnd)
    if not confirm = "Yes" {
        return
    }

    failed := Array()
    for path in paths {
        try {
            if InStr(FileExist(path), "D") {
                DirDelete(path, true)
                continue
            }
    
            FileDelete(path)
        } catch as e {
            if not e.Message = "Failed" {
                throw e
            }

            failed.Push(path)
        }
    }

    for key in keys {
        try {
            RegDeleteKey(key)
        } catch as e {
            if not e.Message = "(5) Access is denied." {
                throw e
            }

            failed.Push(key)
        }
    }

    if failed.Length {
        message := "Unable to delete the following due to restricted access.`n`n"
        for fail in failed {
            message := message fail

            if not A_Index = failed.Length {
                message := message "`n"
            }
        }

        MsgBox(message, "Find Leftovers", "Owner" my_gui.Hwnd)
    }

    SearchEditChange()
}
