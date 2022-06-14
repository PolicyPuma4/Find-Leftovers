#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

directories := []

EnvGet, program_files, PROGRAMFILES
EnvGet, program_files_86, PROGRAMFILES(X86)
EnvGet, user_profile, USERPROFILE

directories.Push(program_files)
directories.Push(program_files "\Common Files")
directories.Push(program_files_86)
directories.Push(program_files_86 "\Common Files")
directories.Push(A_AppDataCommon)
directories.Push(user_profile)
directories.Push(user_profile "\AppData\Local")
directories.Push(user_profile "\AppData\Local\Programs")
directories.Push(user_profile "\AppData\LocalLow")
directories.Push(user_profile "\AppData\Roaming")

keys := []

keys.Push("HKEY_CURRENT_USER\SOFTWARE")
keys.Push("HKEY_LOCAL_MACHINE\SOFTWARE")
keys.Push("HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node")

InputBox, query
if ErrorLevel
{
  ExitApp
}

Loop, % directories.Length()
{
  Loop, Files, % directories[A_Index] "\*", DF
  {
    if (!InStr(A_LoopFileName, query))
    {
      continue
    }

    MsgBox, 3,, % A_LoopFileFullPath
    
    IfMsgBox, Yes
    {
      Run, % "explorer.exe /select,""" A_LoopFileFullPath """"
      continue
    }

    IfMsgBox, No
    {
      continue
    }

    IfMsgBox, Cancel
    {
      ExitApp
    }
  }
}

Loop, % keys.Length()
{
  search_key := keys[A_Index]

  Loop, Reg, % search_key, KV
  {
    if (!InStr(A_LoopRegName, query))
    {
      continue
    }

    path := % search_key "\" A_LoopRegName

    MsgBox, 3,, % path

    IfMsgBox, Yes
    {
      RegWrite, REG_SZ, HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Regedit, LastKey, % path
      try
      {
        Run, % "regedit.exe /m"
      }
      catch e
      {
        if (e["Extra"] != "The operation was canceled by the user.`r`n")
        {
          throw e
        }
      }
      continue
    }

    IfMsgBox, No
    {
      continue
    }

    IfMsgBox, Cancel
    {
      ExitApp
    }
  }
}

MsgBox, % "No more results"
