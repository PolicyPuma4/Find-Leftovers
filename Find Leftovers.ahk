; Created by https://github.com/PolicyPuma4
; Repository https://github.com/PolicyPuma4/Find-Leftovers

;@Ahk2Exe-Obey U_bits, = %A_PtrSize% * 8
;@Ahk2Exe-Obey U_type, = "%A_IsUnicode%" ? "Unicode" : "ANSI"
;@Ahk2Exe-ExeName %A_ScriptName~\.[^\.]+$%_%U_type%_%U_bits%

;@Ahk2Exe-SetMainIcon shell32_33.ico

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

input := InputBox().value
if not input
    ExitApp

for leftover_dir in dirs
{
    Loop Files, leftover_dir "\*", "DF"
    {
        if not InStr(A_LoopFileName, input)
            continue

        result := MsgBox(A_LoopFileFullPath,, 3)

        if result = "Yes"
        {
            Run "explorer.exe /select,`"" A_LoopFileFullPath "`""
            continue
        }

        if result = "No"
            continue

        if result = "Cancel"
            ExitApp
    }
}

for leftover_key in keys
{
    Loop Reg, leftover_key, "KV"
    {
        if not InStr(A_LoopRegName, input)
            continue

        path := leftover_key "\" A_LoopRegName
        result := MsgBox(path,, 3)

        if result = "Yes"
        {
            RegWrite path, "REG_SZ", "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Regedit", "LastKey"
            try
            {
                Run "regedit.exe /m"
            }
            catch as e
            {
                if not e.Extra = "The operation was canceled by the user.`r`n"
                    throw e
            }
            continue
        }

        if result = "No"
            continue

        if result = "Cancel"
            ExitApp
    }
}

MsgBox "No more results 👍"
