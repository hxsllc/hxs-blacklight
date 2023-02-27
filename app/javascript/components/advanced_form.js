$(document).ready(function() {
    $("form.advanced").submit(function(e) {
        var $form = $(this)
        var op = $(this).find('select[name=op]').val()

        $form.find('input.advanced-search-field-value[type=hidden]').val('')

        $(".advanced-search-field").each(function (i, container) {
            var $input = $(container).find('input[type=text]')
            var searchValue = $input.val() || ''

            if (searchValue.trim() !== '') {
                var fieldName = $(container).find('select').val()
                var $hiddenSearchField = $form.find('input[type=hidden][name=' + fieldName + ']')
                var currentValue = $hiddenSearchField.val() || ''

                if (currentValue.trim() !== '') {
                    $hiddenSearchField.val(currentValue + ' ' + op + ' ' + searchValue)
                } else {
                    $hiddenSearchField.val(searchValue)
                }
            }
        });
    });
});
