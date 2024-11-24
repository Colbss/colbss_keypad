let inputText = ""
const display = document.querySelector('.display');

window.addEventListener('message', function (event) {
    let e = event.data;
    switch (e.action) {
        case "STATE":
            if (!e.value) {
                $('body').css('display', 'none');
            }else {
                $('body').css('display', 'flex');
            }
            break;
        case "INPUT":
                if (!e.value) {
                    display.textContent = 'INVALID'
                } else {
                    display.textContent = 'SUCCESS'
                }
                break;
        case "MOUSE":
            if (!e.value) {
                $('.mouse-container').css('display', 'none');
            } else {
                $('.mouse-container').css('display', 'flex');
            }
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

            // Send input to the client (do not expose the code on the frontend)
            $.post(`https://colbss_keypad/button`, JSON.stringify({ value: label }));

            // Reset the click flag after a short delay
            setTimeout(() => {
                clickInProgress = false;
            }, 200); // Adjust the delay as needed
        });
    });
});


// Get the icon element
const icon = document.getElementById('mouse-icon');

// Update the icon's position on mousemove
document.addEventListener('mousemove', (event) => {
    const mouseX = event.clientX; // Mouse X position
    const mouseY = event.clientY; // Mouse Y position

    // Update icon position
    icon.style.left = `${mouseX}px`;
    icon.style.top = `${mouseY}px`;
});
