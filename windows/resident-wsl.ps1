$scr= New-Object -ComObject Shell.Application
$scr.ShellExecute("wsl","bash -c 'read'","E:\Windows\System32","",0)