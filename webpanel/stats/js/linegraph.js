$(document).ready(function(){
	$.ajax({
		url : "data.php",
		type : "GET",
		success : function(data){
			console.log(data);

			var time = [];
			var users = [];
			var online = [];

			for(var i in data) {
				time.push(data[i].time);
				users.push(data[i].users);
				online.push(data[i].online);
			}

			var chartdata = {
				labels: time,
				datasets: [
					{
						label: "total users",
						fill: false,
						lineTension: 0.1,
						backgroundColor: "rgba(59, 89, 152, 0.75)",
						borderColor: "rgba(59, 89, 152, 1)",
						pointHoverBackgroundColor: "rgba(59, 89, 152, 1)",
						pointHoverBorderColor: "rgba(59, 89, 152, 1)",
						data: users
					},
					{
						label: "online users",
						fill: false,
						lineTension: 0.1,
						backgroundColor: "rgba(90, 230, 30, 0.75)",
						borderColor: "rgba(90, 230, 30, 1)",
						pointHoverBackgroundColor: "rgba(90, 230, 30,, 1)",
						pointHoverBorderColor: "rgba(90, 230, 30, 1)",
						data: online
					}
				]
			};

			var ctx = $("#mycanvas");

			var LineGraph = new Chart(ctx, {
				type: 'line',
				data: chartdata
			});
		},
		error : function(data) {

		}
	});
});