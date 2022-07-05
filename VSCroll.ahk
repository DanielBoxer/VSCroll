; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful, but
; WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
; General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program. If not, see <https://www.gnu.org/licenses/>.

; modify these constants to change behaviour of script
; slow scroll: sleep > 1 ms, from start position to SLOW_SCROLL_DISTANCE
; fast scroll: sleep < 1 ms, SLOW_SCROLL_DISTANCE and above
SYMBOL := Chr(10021) ; html code for four direction arrow symbol
FAST_SCROLL_SPEED := 75 ; higher values will increase fast scroll speed
SLOW_SCROLL_DISTANCE := 50 ; distance until fast scroll starts
SLOW_SCROLL_SLEEP := 50 ; higher values will decrease slow scroll speed
SCROLL_AMOUNT := 2 ; slow and fast scroll delta (int, > 1)
END_SCROLL_RANGE := 450 ; end of scroll range, affects fast scroll
INITIAL_POSITION := 0 ; initial scroll and tooltip position
; to fix incorrect tooltip position:
; 1. if the tooltip is on the far right of the screen:
; comment out the first CoordMode command (line 40)
; 2. if the tooltip is slightly off:
; change INITIAL_POSITION until the tooltip is in the right place

convertRange(value, min1, max1, min2, max2) {
    ; linear conversion of an input value
    Return ((value - min1) / (max1 - min1)) * (max2 - min2) + min2
}

#IfWinActive ahk_exe Code.exe
    MButton::
        hasScrollingStarted := False
        If (A_Cursor = "IBeam") {
            ; CoordMode makes the code work on connected displays
            CoordMode Mouse, Screen
            MouseGetPos x1, y1
            ToolTip %SYMBOL%, x1 - INITIAL_POSITION, y1 - INITIAL_POSITION
            sleepCount := 0
            isScrolling := True
            While (isScrolling) {
                CoordMode Mouse, Screen
                MouseGetPos x2, y2
                direction := 0
                scrollDistance := 0
                If (GetKeyState("Shift")) {
                    ; 0x20E: hex code for horizontal scroll
                    direction := 0x20E
                    scrollDistance := x2 - x1 + INITIAL_POSITION
                } Else {
                    ; 0x20A: vertical scroll
                    direction := 0x20A
                    scrollDistance := y2 - y1 + INITIAL_POSITION
                }
                delta := SCROLL_AMOUNT
                ; get up/down or left/right direction
                If (direction = 0x20A) {
                    If (scrollDistance > 0)
                        delta := delta * -1
                } Else If (scrollDistance < 0) {
                    ; direction is reversed for horizontal scroll
                    delta := delta * -1
                }

                scrollDistance := Abs(scrollDistance)
                If (scrollDistance > 12) {
                    ; send scroll command
                    PostMessage direction, delta << 16, y2 << 16 | x2, , A
                    hasScrollingStarted := True

                    If (scrollDistance < SLOW_SCROLL_DISTANCE) {
                        ; slow scroll
                        ; map (min distance to max distance) to
                        ; (min sleep to max sleep)
                        sleepTime := convertRange(scrollDistance, 12
                        , SLOW_SCROLL_DISTANCE, SLOW_SCROLL_SLEEP, 1)
                        Sleep sleepTime
                    } Else {
                        ; fast scroll
                        ; since the fastest sleep is 1 ms, to make a faster
                        ; sleep, most fast scroll iterations skip sleep
                        sleepCycle := convertRange(scrollDistance
                            , SLOW_SCROLL_DISTANCE
                            , END_SCROLL_RANGE - SLOW_SCROLL_DISTANCE
                            , 1
                        , FAST_SCROLL_SPEED)
                        If (++sleepCount > sleepCycle) {
                            ; sleep cycle has ended
                            sleepCount := 0
                            Sleep 1
                        }
                    }
                }
            }
        } Else {
            SendInput {MButton}
        }
    Return

    MButton Up::
        If (hasScrollingStarted) {
            isScrolling := False
            ToolTip
            hasScrollingStarted := False
            ; the code below is to fix a bug with vscode smooth scrolling
            ; without it, when you stop scrolling, the next 4 mouse wheel
            ; scrolls won't use smooth scroll
            ; this code simulates 4 small scrolls quickly so it's not noticable
            ; there also needs to be a sleep between scrolls or it won't work
            ; if you don't use vscode smooth scroll, remove the next 6 lines
            CoordMode Mouse, Screen
            MouseGetPos x, y
            Loop 4 {
                Sleep 1
                PostMessage 0x20A, 1 << 16, y << 16 | x, , A
            }
        } Else {
            hasScrollingStarted := True
        }
    Return
#IfWinActive
