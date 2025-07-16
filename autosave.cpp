#include <fstream>
#include <vector>
#include <iostream>
#include <windows.h>

LRESULT CALLBACK WindowProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
    if (uMsg == WM_DESTROY) {
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProc(hwnd, uMsg, wParam, lParam);
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE, LPSTR, int nCmdShow) {
    const char CLASS_NAME[] = "SampleWindowClass";
    WNDCLASS wc = { };
    wc.lpfnWndProc = WindowProc;
    wc.hInstance = hInstance;
    wc.lpszClassName = CLASS_NAME;
    RegisterClass(&wc);

    HWND hwnd = CreateWindowEx(0, CLASS_NAME, "My Window", WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, 500, 300, NULL, NULL, hInstance, NULL);

    ShowWindow(hwnd, nCmdShow);

    MSG msg = {};
    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }
    return 0;
}

int main() {
    using namespace std;
    const char* sourcePath = "original.exe";   // Path to your source EXE
    // Open the original EXE in binary mode
    ifstream src(sourcePath, ios::binary);
    if (!src) {
        cerr << "Failed to open source file.\n";
        return 1;
    }

    // Read all bytes into a buffer
    vector<char> buffer(
        (istreambuf_iterator<char>(src)),
        istreambuf_iterator<char>()
    );
    src.close();

    // Open the destination EXE in binary mode
    ofstream dst(destPath, ios::binary);
    if (!dst) {
        cerr << "Failed to open destination file.\n";
        return 1;
    }

    // Write all bytes to the destination
    dst.write(buffer.data(), buffer.size());
    dst.close();

    cout << "Copy completed successfully.\n";
    return 0;
}