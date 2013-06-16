$(function(){

    $("#create-form").validate({
        rules : {
            subject: {
                required: true
            },
            deadline: {
                required: true
            },
            body: {
                required: true
            }
        },
        messages: {
            subject: {
                required: "件名を入力して下さい"
            },
            deadline: {
                required: "期限を入力して下さい"
            },
            body: {
                required: "本文を入力して下さい"
            }
        }
    });

    $('.datepicker').datepicker({
        changeMonth: true,
        changeYear: true,
        dateFormat: 'yy/mm/dd',
        yearRange: '2010:2030',
    });
});
