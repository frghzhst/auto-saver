#include <windows.h>
#include <string>

#define ID_LISTBOX 101

// Forward declaration
LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam);

// Example functions for each item
void Function1() { MessageBoxA(NULL, "Function 1 called!", "Info", MB_OK); }
void Function2() { MessageBoxA(NULL, "Function 2 called!", "Info", MB_OK); }
void Function3() { MessageBoxA(NULL, "Function 3 called!", "Info", MB_OK); }

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE, LPSTR, int nCmdShow) {
    const char CLASS_NAME[] = "SampleWindowClass";
    WNDCLASS wc = { };
    wc.lpfnWndProc = WindowProc;
    wc.hInstance = hInstance;
    wc.lpszClassName = CLASS_NAME;
    RegisterClass(&wc);

    HWND hwnd = CreateWindowEx(
        0, CLASS_NAME, "WinAPI List Box Example", WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, 400, 300,
        NULL, NULL, hInstance, NULL);

    ShowWindow(hwnd, nCmdShow);

    MSG msg = {};
    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    return 0;
}

LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    static HWND hList = NULL;
    switch (uMsg) {
    case WM_CREATE:
        // Create the list box
        hList = CreateWindowEx(
            0, "LISTBOX", NULL,
            WS_CHILD | WS_VISIBLE | LBS_NOTIFY | WS_BORDER | WS_VSCROLL,
            20, 20, 200, 150,
            hwnd, (HMENU)ID_LISTBOX, GetModuleHandle(NULL), NULL);

        // Add items
        SendMessage(hList, LB_ADDSTRING, 0, (LPARAM)"Call Function 1");
        SendMessage(hList, LB_ADDSTRING, 0, (LPARAM)"Call Function 2");
        SendMessage(hList, LB_ADDSTRING, 0, (LPARAM)"Call Function 3");
        break;

    case WM_COMMAND:
        if (LOWORD(wParam) == ID_LISTBOX && HIWORD(wParam) == LBN_SELCHANGE) {
            int sel = (int)SendMessage(hList, LB_GETCURSEL, 0, 0);
            // Call a different function for each selection
            switch (sel) {
                case 0: Function1(); break;
                case 1: Function2(); break;
                case 2: Function3(); break;
            }
        }
        break;

    case WM_DESTROY:
        PostQuitMessage(0);
        break;

    default:
        return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }
    return 0;
}