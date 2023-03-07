
/*
Copy Clipboard
 */
$(document).ready(function() {
    $('[data-toggle=clipboard]').tooltip({
        placement: 'top',
        trigger: 'manual',
        title: 'Copied'
    })

    $('[data-toggle=clipboard]').on('click', function(e) {
        e.preventDefault();

        const $this = $(this)
        const value = $this.data('value')

        navigator.clipboard.writeText(value).then(function() {
            $this.tooltip('show')

            setTimeout(function() { $this.tooltip('hide') }, 2000)
        }, function(err) {
            console.error('Async: Could not copy text: ', err);
            alert('Unable to copy to clipboard at this time.')
        });
    })
})
