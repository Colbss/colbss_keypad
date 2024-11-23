

window.addEventListener('message', function (event) {
    let e = event.data;
    switch (e.action) {
        case "STATE":
            if (!e.value) {
                console.log('Hide Body')
                $('body').css('display', 'none');
            }else {
                console.log('Show Body')
                $('body').css('display', 'flex');
            }
            break;
        case "MOUSE":
            if (!e.value) {
                $('.mouse-container').css('display', 'flex');
            } else {
                $('.mouse-container').css('display', 'flex');
            }
        default: break;
    }
});

document.addEventListener('DOMContentLoaded', () => {
    const buttons = document.querySelectorAll('.btn');
    buttons.forEach(button => {
        button.addEventListener('click', () => {
            const label = button.querySelector('.label').textContent; // Get the button label

            console.log('Pressed Button : ' + label)

            // Dont send code to front end as player can see it, send input to client to process there

            //$.post(`https://${GetParentResourceName()}/button`, JSON.stringify({ value: label }));
            
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
