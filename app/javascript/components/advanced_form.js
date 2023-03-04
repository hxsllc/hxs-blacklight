 /* 

code from SDM 

Invalid query parameters: expected Array (got String) for param `all_fields'

$(document).ready(function() {
    $("form.advanced").submit(function(e) {
        $(".advanced-search-field").each(function (idx, container) {
            if($(container).find("input[type=text]").length == 2) {
                // range search
                var start = $(container).find("input.start").val();
                var end = $(container).find("input.end").val();
                var input_name = ""
                var input_value = "";
                if(start || end) {
                    if (!start) { start = "*"; }
                    if (!end) { end = "*"; }
                    input_name = $(container).find("select").val() + "[]";
                    input_value = "[" + start + " TO " + end + "]";
                }
                $(container).find("input[type=hidden]").attr("name", input_name);
                $(container).find("input[type=hidden]").attr("value", input_value);
            } else {
                // text search
                var input_element = $(container).find("input").first();
                var input_name = "";
                if($(input_element).val()) {
                    input_name = $(container).find("select").val() + "[]";
                }
                $(input_element).attr("name", input_name);
            }
        });
    });
});

*/
/* code from HXS/James */

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
