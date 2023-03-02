
if (typeof window.sessionStorage !== 'undefined') {
    const KEY = 'hideBetaNotice'

    $(document).ready(function() {

        if (window.sessionStorage.getItem(KEY) === 'true') {
            $('#beta-notice').remove()
        } else {
            $('#beta-notice').removeClass('hide')
                .addClass('show')
                .on('closed.bs.alert', function() { window.sessionStorage.setItem(KEY, 'true') });

            $('#beta-notice [data-dismiss=alert]').on('click', function() { $('#beta-notice').alert('close') })
        }
    });
}
