; Created by https://github.com/PolicyPuma4
; Repository https://github.com/PolicyPuma4/Find-Leftovers

#Requires AutoHotkey v2.0-beta
#SingleInstance Force

;@Ahk2Exe-Obey U_bits, = %A_PtrSize% * 8
;@Ahk2Exe-Obey U_type, = "%A_IsUnicode%" ? "Unicode" : "ANSI"
;@Ahk2Exe-ExeName %A_ScriptName~\.[^\.]+$%_%U_type%_%U_bits%

;@Ahk2Exe-SetMainIcon shell32_33.ico

;@Ahk2Exe-UpdateManifest 2

if not A_IsCompiled
{
    TraySetIcon("shell32_33.ico")

    arg := A_Args.Length ? A_Args[1] : ""
    if not A_IsAdmin and not arg = "restart"
    {
        try
        {
            Run("*RunAs `"" A_ScriptFullPath "`" restart")
            ExitApp()
        }
        catch as e
        {
            if not e.Extra = "The operation was canceled by the user.`r`n"
            {
                throw e
            }
        }
    }
}

my_gui := Gui(, "Find Leftovers")
my_gui.AddText(,"Search")
search_edit := my_gui.AddEdit("r1 w600")
search_edit.OnEvent("Change", SearchEditChange)
my_gui.AddText(,"Directories")
path_listbox := my_gui.AddListBox("r10 w600 0x8")
my_gui.AddText(,"Registry keys")
reg_listbox := my_gui.AddListBox("r10 w600 0x8")
delete_button := my_gui.AddButton("w600", "Delete")
delete_button.OnEvent("Click", DeleteButtonClick)

my_gui.Show()

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

SearchEditChange(*)
{
    path_listbox.Delete()
    reg_listbox.Delete()
    input := search_edit.Value
    if not input
    {
        return
    }

    for leftover_dir in dirs
    {
        Loop Files, leftover_dir "\*", "DF"
        {
            if not InStr(A_LoopFileName, input)
            {
                continue
            }

            path_listbox.Add([A_LoopFileFullPath])
        }
    }

    for leftover_key in keys
    {
        Loop Reg, leftover_key, "K"
        {
            if not InStr(A_LoopRegName, input)
            {
                continue
            }

            reg_listbox.Add([leftover_key "\" A_LoopRegName])
        }
    }
}

DeleteButtonClick(*)
{
    confirm := MsgBox("Are you sure?", "Find Leftovers", "YesNo Owner" my_gui.Hwnd)
    if not confirm = "Yes"
    {
        return
    }

    failed := Array()

    paths := path_listbox.Text
    if paths
    {
        for path in paths
        {
            try
            {
                if InStr(FileExist(path), "D")
                {
                    DirDelete(path, true)
                    continue
                }
        
                FileDelete(path)
            }
            catch as e
            {
                if not e.Message = "Failed"
                {
                    throw e
                }

                failed.Push(path)
            }
        }
    }

    keys := reg_listbox.Text
    if keys
    {
        for key in keys
        {
            try
            {
                RegDeleteKey(key)
            }
            catch as e
            {
                if not e.Message = "(5) Access is denied."
                {
                    throw e
                }

                failed.Push(key)
            }
        }
    }

    if failed.Length
    {
        message := "Unable to delete the following due to restricted access.`n`n"
        for fail in failed
        {
            message := message fail

            if not A_Index = failed.Length
            {
                message := message "`n"
            }
        }

        MsgBox(message, "Find Leftovers", "Owner" my_gui.Hwnd)
    }

    SearchEditChange()
}
