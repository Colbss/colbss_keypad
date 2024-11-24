let inputText = ""
const display = document.querySelector('.display');

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
            display.textContent = e.value
            break;
        case "BUTTON":
            HighlightButton(e.value)
            break;
        default: break;
    }
});

document.addEventListener('DOMContentLoaded', () => {
    const buttons = document.querySelectorAll('.btn');
    let clickInProgress = false; // Track if a click is being processed

    buttons.forEach(button => {
        button.addEventListener('click', () => {
            if (clickInProgress) return; // Prevent multiple clicks

            clickInProgress = true; // Set the flag to true
            const label = button.querySelector('.label').textContent; // Get the button label
            const buttonId = button.id;

            if (buttonId) {
                if (buttonId === 'cancel') {
                    inputText = ""
                    display.textContent = inputText;
                } else if (buttonId === 'submit') {
                    $.post(`https://colbss_keypad/submit`, JSON.stringify({ value: inputText }));
                }
            } else {
                // Update input and display
                if (inputText.length < 5) {
                    inputText = inputText + label;
                    display.textContent = inputText;
                }
            }

            $.post(`https://colbss_keypad/button`, JSON.stringify({ value: label }));

            // Reset the click flag after a short delay
            setTimeout(() => {
                clickInProgress = false;
            }, 200); // Adjust the delay as needed
        });
    });
});

let prevBtnID = -1
function HighlightButton(ID) {

    if (prevBtnID > 0 ) { // Ignore first time
        const prevBtn = document.getElementById('btn' + prevBtnID)
        prevBtn.style.backgroundColor = 'transparent'; 
    }
    if (ID > 0 ) {
        const newBtn = document.getElementById('btn' + ID)
        newBtn.style.backgroundColor = '#2321a147'; 
        prevBtnID = ID
    }
}

