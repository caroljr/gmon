$("sistema").change(function() {
   $("second-choice").load("textdata/" + $(this).val() + ".txt");
});
