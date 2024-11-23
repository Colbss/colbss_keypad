

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
        default: break;
    }
});

