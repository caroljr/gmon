$("#sistema").change(function() {
	var $dropdown = $(this);
	$.getJSON("tmp/data.json", function(data) {
		var key = $dropdown.val();
		var vals = [];				
		switch(key) {
			case '4':
				vals = data.mobile.split(",");
				break;
			case '29':
				vals = data.autorizador.split(",");
				break;
			case 'base':
				vals = ['Please choose from above'];
		}
		var $secondChoice = $("#second-choice");
		$secondChoice.empty();
		$.each(vals, function(index, value) {
			$secondChoice.append("<option>" + value + "</option>");
		});
	});
});
