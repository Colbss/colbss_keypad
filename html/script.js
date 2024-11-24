
window.addEventListener('message', function (event) {
    let e = event.data;
    switch (e.action) {
        case "KEYPAD":
            if (!e.value) {
                $('.keypad').css('display', 'none');
            }else {
                $('.keypad').css('display', 'flex');
            }
            break;
        case "MOUSE":
            if (!e.value) {
                $('.mouse').css('display', 'none');
            }else {
                $('.mouse').css('display', 'flex');
            }
            break;
        case "DISPLAY":
            $('.display').text(e.value);
            break;
        case "BUTTON":
            HighlightButton(e.value)
            break;
        default: break;
    }
});

let prevBtnID = -1
function HighlightButton(ID) {
    if (prevBtnID > 0 ) {
        $('#btn' + prevBtnID).css('background-color', 'transparent');
    }
    if (ID > 0 ) {
        $('#btn' + ID).css('background-color', '#2321a147');
        prevBtnID = ID
    }
}

