.386

.model flat,stdcall
option casemap:none

include		windows.inc
include		gdi32.inc
includelib	gdi32.lib
include		user32.inc
includelib	user32.lib
include		kernel32.inc
includelib	kernel32.lib

includelib msvcrt.lib

.data

.const

str_main_caption byte '������', 0
str_class_name byte 'main_window_class', 0


.data?

h_instance dword ?
h_main_window dword ?

.code

_init PROC
    ret
_init ENDP

_proc_main_window PROC uses ebx edi esi, h_window, u_msg, wParam, lParam

    mov eax, u_msg

    .if eax == WM_CREATE
        push h_window
        pop h_main_window
        call _init
    
    .elseif eax == WM_COMMAND
        mov eax, wParam
        mov ecx, wParam
        shl eax, 16

    .elseif eax == WM_CLOSE
        invoke DestroyWindow, h_window
        invoke PostQuitMessage, NULL
    
    .else
        invoke DefWindowProc, h_window, u_msg, wParam, lParam
        ret
    .endif

    xor eax, eax

    ret
_proc_main_window ENDP

_main_window PROC 
    LOCAL st_window_class:WNDCLASSEX
    LOCAL st_msg:MSG
    LOCAL h_edit:dword

    invoke LoadCursor, 0, IDC_ARROW
    mov st_window_class.hCursor, eax
    push h_instance
    pop st_window_class.hInstance
    mov st_window_class.cbSize, sizeof WNDCLASSEX
    mov st_window_class.style, CS_HREDRAW or CS_VREDRAW
    mov st_window_class.lpfnWndProc, offset _proc_main_window
    mov st_window_class.hbrBackground, COLOR_WINDOW+1
    mov st_window_class.lpszClassName, offset str_class_name
    invoke RegisterClassEx, addr st_window_class

    invoke CreateWindowEx, WS_EX_CLIENTEDGE, offset str_class_name, offset str_main_caption, WS_OVERLAPPEDWINDOW xor WS_SIZEBOX, CW_USEDEFAULT, CW_USEDEFAULT, 515, 500, NULL, NULL, h_instance, NULL
    mov h_main_window, eax
    invoke ShowWindow, h_main_window, SW_SHOWNORMAL
    invoke UpdateWindow, h_main_window

    .while TRUE
        invoke GetMessage, addr st_msg, NULL, 0, 0
        .break .if eax == 0
        invoke TranslateMessage, addr st_msg
        invoke DispatchMessage, addr st_msg
    .endw

    ret
_main_window ENDP


start:
    call _main_window 
    invoke ExitProcess, NULL
    ret
end start