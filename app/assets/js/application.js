// setInterval(get_notification, 10000);

function complain_check(index){
  var qty = $("#quantity"+index).val();
  var complain = $("#complain"+index).val();
  var replace = $("#replace"+index).val();
  if(complain > qty){
    $("#complain"+index).val($("#quantity"+index).val());
    complain = qty;
  }
  if(replace > complain){
    $("#replace"+index).val($("#complain"+index).val());
    replace = complain;
  }

  total_complain();
}

function total_complain(){
  var item_total = $("#item_total").val();
  var new_total = 0;

  for (var i = 0; i < item_total; i++) {
    var complain = $("#complain"+i).val();
    var replace = $("#replace"+i).val();
    var price = $("#price"+i).val();

    new_total-= (complain - replace) * price
  }

  var table = document.getElementById("myTable");
  var table_length = table.rows.length;
  for (var i = 1; i < table_length; i++) {
    var price = table.rows[i].cells[4].childNodes[0].value;
    var qty = table.rows[i].cells[3].childNodes[0].value;
    var discount = table.rows[i].cells[5].childNodes[0].value;
    new_total+= (price * qty)-(discount*qty);
  } 

  var total_text = document.getElementById("total_text");
  $("#total").val(new_total);
  if(new_total > 0){
    total_text.style.color = "green";
    total_text.innerHTML = "BAYAR : Rp. "+formatangka_titik(new_total);
  }else if (new_total==0){
    total_text.style.color = "black";
    total_text.innerHTML = "TIDAK ADA TAMBAHAN";
  }else{
    total_text.style.color = "red";
    total_text.innerHTML = "GANTI : Rp. "+formatangka_titik(new_total);
  }
}

function formatangka_titik(total) {
  var a = (total+"").replace(/[^\d]/g, "");

  var a = +a; // converts 'a' from a string to an int

  return formatNum(a);
}

function formatNum(rawNum) {
  rawNum = "" + rawNum; // converts the given number back to a string
  var retNum = "";
  var j = 0;
  for (var i = rawNum.length; i > 0; i--) {
    j++;
    if (((j % 3) == 1) && (j != 1))
      retNum = rawNum.substr(i - 1, 1) + "." + retNum;
    else
      retNum = rawNum.substr(i - 1, 1) + retNum;
  }
  return retNum;
}


function addNewRowComplain(result_arr, qty){
   var table = document.getElementById("myTable");
   var result = result_arr[0];
   var total = parseFloat(qty) * (parseFloat(result[3]) - parseFloat(result[4]));
   
   var row = table.insertRow(-1);
   var cell1 = row.insertCell(0);
   var cell2 = row.insertCell(1);
   var cell3 = row.insertCell(2);
   var cell4 = row.insertCell(3);
   var cell5 = row.insertCell(4);
   var cell6 = row.insertCell(5);
   var cell7 = row.insertCell(6);

   let id = "<input style='display: none;' type='text' class='md-form form-control' value='"+result[5]+"' readonly name='complain[new_complain_items]["+add_counter+"][item_id]'/>";
   let code = id+"<input type='text' class='md-form form-control' value='"+result[0]+"' readonly />";
   let name = "<input type='text' class='md-form form-control' value='"+result[1]+"' readonly />";
   let cat = "<input type='text' class='md-form form-control' value='"+result[2]+"' readonly />";
   let price = "<input readonly type='number' class='md-form form-control' value="+result[3]+"  name='complain[new_complain_items]["+add_counter+"][price]'/>";
   let discount = "<input readonly type='number' class='md-form form-control' value="+result[4]+"  name='complain[new_complain_items]["+add_counter+"][discount]'/>";
   let quantity = "<input type='number' readonly min=1 class='md-form form-control' value='"+qty+"' name='complain[new_complain_items]["+add_counter+"][quantity]'/>"
   let remove = "<i class='fa fa-trash text-danger' onclick='removeRowComplain(this)'></i>"; 
   cell1.innerHTML = code;
   cell2.innerHTML = name;
   cell3.innerHTML = cat;
   cell4.innerHTML = quantity;
   cell5.innerHTML = price;
   cell6.innerHTML = discount;
   cell7.innerHTML = remove;
   add_counter++;
   document.getElementById("itemId").value = "";

   total_complain();
}

function removeRowComplain(params){
  var row_idx = params.parentNode.parentNode.rowIndex;
  var table = document.getElementById("myTable");
  if(table.rows.length > 1){
    table.deleteRow(row_idx);
  }
  total_complain();
}


$(document).keypress(
  function(event){
    if (event.which == '13') {
      event.preventDefault();
    }
});

function update_notification(){
  $.ajax({ 
    type: 'GET', 
    url: '/api/update_notification', 
    success: function (result) {
      refresh_notification_list(result);
    }
  });
}

function get_notification(){
  $.ajax({ 
    type: 'GET', 
    url: '/api/get_notification', 
    success: function (result) { 
      refresh_notification_list(result);
    }
  });
}

function refresh_notification_list(result){
  data_length = result.length;
    types = ["primary", "warning", "danger", "success", "info"];
    icons = ["star", "exclamation-triangle", "times", "success", "info"];
    number_new_notif = result[0][1];
    if (number_new_notif > 0){
      document.getElementById("notif_number_badge").innerHTML = number_new_notif;
      document.getElementById("notif_number_badge").style.display = "inline";
    }else{
      document.getElementById("notif_number_badge").style.display = "none";
    }
    if (data_length > 1) {
      document.getElementById("notification_list").innerHTML = "";
      for(i = 1; i < data_length; i++){
        data = result[i];
        from = data[0];
        date = data[1];
        message = data[2];
        m_type = data[3];
        url = data[4];
        read = data[5];
        icon = icons[types.indexOf(m_type)];

        time = ""
        curr_date = new Date();
        notif_date = new Date(date);
        diff_date = (curr_date-notif_date)
        diffMs = (curr_date-notif_date);
        diffDays = Math.floor(diffMs / 86400000); // days
        diffHrs = Math.floor((diffMs % 86400000) / 3600000); // hours
        diffMins = Math.round(((diffMs % 86400000) % 3600000) / 60000); // minutes
        diffSecs = Math.round(((diffMs % 86400000) % 3600000) / 60000 / 60000); // seconds

        if(diffDays > 0){
          if (diffDays > 1){
            time+= diffDays+" day"
          }else{
            time+= diffDays+" days"
          }
        }else if(diffHrs > 0){
          if (diffHrs > 1){
            time+= diffHrs+" hour"
          }else{
            time+= diffHrs+" hours"
          }
        }else if(diffMins > 0){
          if (diffMins > 1){
            time+= diffMins+" minute"
          }else{
            time+= diffMins+" minutes"
          }
        }else{
          time+= "just now"
        }

        // alert(diffDays + " days, " + diffHrs + " hours, " + diffMins + " minutes, " + diffSecs + " seconds");

        element = "<a class='bq-"+m_type+" dropdown-item waves-effect waves-light' href='"+url+"'>"
        element+=   "<i class='fas fa-"+icon+" mr-2' aria-hidden='true'></i>"
        element+=     "<span>"+from+"</span>"
        element+=     "<br><span>"+message+"</span><br>"
        element+=     "<p class='span float-right'>"
        element+=       "<small>"+time+"</small>"
        element+=     "</p></a>"
        $("#notification_list").append(element);
      }
      element = "<a class='dropdown-item' href='/notifications'>"
      element+=  "<p class='span text-center'>"
      element+=    "Semua Notifikasi"
      element+=  "</p></a>"
      $("#notification_list").append(element);
    }
}

function removeThisRow(params){
	var row_idx = params.parentNode.parentNode.rowIndex;
	var table = document.getElementById("myTable");
	if(table.rows.length > 1){
		table.deleteRow(row_idx);
	}
}

    // SideNav Initialization
$(".button-collapse").sideNav();

var container = document.querySelector('.custom-scrollbar');
var ps = new PerfectScrollbar(container, {
  wheelSpeed: 2,
  wheelPropagation: true,
  minScrollbarLength: 20
});

// Data Picker Initialization
$('.datepicker').pickadate();


// Tooltips Initialization
$(function () {
  $('[data-toggle="tooltip"]').tooltip()
})

// Small chart
$(function () {
  $('.min-chart#chart-sales').easyPieChart({
    barColor: "#FF5252",
    onStep: function (from, to, percent) {
      $(this.el).find('.percent').text(Math.round(percent));
    }
  });
});


var timeout = null;

function getData(table_types) {
   clearTimeout(timeout);
   timeout = setTimeout(function() {
     var item_id = document.getElementById("itemId").value;
     if(table_types=="complain"){
        var item_qty = document.getElementById("searchqty").value;
        $.ajax({
         method: "GET",
         cache: false,
         url: "/api/trx?search=" + item_id +"&qty=" + item_qty,
         success: function(result_arr) {
            if(result_arr == ""){
              document.getElementById("itemId").value = "";
              alert("Data Barang Tidak Ditemukan")
              return
            }else{
              addNewRowComplain(result_arr, item_qty);
            }
         },
         error: function(error) {
             document.getElementById("itemId").value = "";
             document.getElementById("searchqty").value = 1;
             document.getElementById("itemId").focus();
         }
       });
     }else{
      $.ajax({
         method: "GET",
         cache: false,
         url: "/api/order?search=" + item_id,
         success: function(result_arr) {
            if(result_arr == ""){
              document.getElementById("itemId").value = "";
              alert("Data Barang Tidak Ditemukan")
              return
            }else{
               if (table_types == "order"){
                addNewRowOrder(result_arr);
               }
               else if(table_types == "retur"){
                addNewRowRetur(result_arr);
               }else if (table_types == "transfer"){
                addNewRowTransfer(result_arr);
               }
             }
         },
         error: function(error) {
             document.getElementById("itemId").value = "";
             document.getElementById("item_qty").value = 1;
             document.getElementById("itemId").focus();
         }
       });
    }
   }, 300);
};

function addNewRowOrder(result_arr){
   var table = document.getElementById("myTable");
   var result = result_arr[0];
   var qty = 1;
   var total = parseFloat(qty) * (parseFloat(result[3]) - parseFloat("100"));
   
   var row = table.insertRow(-1);
   var cell1 = row.insertCell(0);
   var cell2 = row.insertCell(1);
   var cell3 = row.insertCell(2);
   var cell4 = row.insertCell(3);
   var cell5 = row.insertCell(4);
   var cell6 = row.insertCell(5);


   let id = "<input style='display: none;' type='text' class='md-form form-control' value='"+result[4]+"' readonly name='order[order_items]["+add_counter+"][item_id]'/>";
   let code = id+"<input type='text' class='md-form form-control' value='"+result[0]+"' readonly name='order[order_items]["+add_counter+"][code]'/>";
   let name = "<input type='text' class='md-form form-control' value='"+result[1]+"' readonly name='order[order_items]["+add_counter+"][name]'/>";
   let cat = "<input type='text' class='md-form form-control' value='"+result[2]+"' readonly name='order[order_items]["+add_counter+"][item_cat]'/>";
   let quantity = "<input type='number' min=1 class='md-form form-control' value='1' name='order[order_items]["+add_counter+"][quantity]'/>";
   let price = "<input type='number' class='md-form form-control' value='"+result[3]+"' min=100 name='order[order_items]["+add_counter+"][price]'/>";
   let desc = "<input type='text' class='md-form form-control' value=''  name='order[order_items]["+add_counter+"][description]'/>";
   let remove = "<i class='fa fa-trash text-danger' onclick='removeThisRow(this)'></i>"; 
   cell1.innerHTML = code;
   cell2.innerHTML = name;
   cell3.innerHTML = cat;
   cell4.innerHTML = quantity;
   cell5.innerHTML = desc;
   cell6.innerHTML = remove;
   add_counter++;
   document.getElementById("itemId").value = "";
}

function addNewRowRetur(result_arr){
   var table = document.getElementById("myTable");
   var result = result_arr[0];
   var qty = 1;
   var total = parseFloat(qty) * (parseFloat(result[3]) - parseFloat("100"));
   
   var row = table.insertRow(-1);
   var cell1 = row.insertCell(0);
   var cell2 = row.insertCell(1);
   var cell3 = row.insertCell(2);
   var cell4 = row.insertCell(3);
   var cell5 = row.insertCell(4);
   var cell6 = row.insertCell(5);


   let id = "<input style='display: none;' type='text' class='md-form form-control' value='"+result[4]+"' readonly name='retur[retur_items]["+add_counter+"][item_id]'/>";
   let code = id+"<input type='text' class='md-form form-control' value='"+result[0]+"' readonly name='retur[retur_items]["+add_counter+"][code]'/>";
   let name = "<input type='text' class='md-form form-control' value='"+result[1]+"' readonly name='retur[retur_items]["+add_counter+"][name]'/>";
   let cat = "<input type='text' class='md-form form-control' value='"+result[2]+"' readonly name='retur[retur_items]["+add_counter+"][item_cat]'/>";
   let quantity = "<input type='number' min=1 class='md-form form-control' value='1' name='retur[retur_items]["+add_counter+"][quantity]'/>";
   let desc = "<input type='text' class='md-form form-control' value=''  name='retur[retur_items]["+add_counter+"][description]'/>";
   let remove = "<i class='fa fa-trash text-danger' onclick='removeThisRow(this)'></i>"; 
   cell1.innerHTML = code;
   cell2.innerHTML = name;
   cell3.innerHTML = cat;
   cell4.innerHTML = quantity;
   cell5.innerHTML = desc;
   cell6.innerHTML = remove;
   add_counter++;
   document.getElementById("itemId").value = "";
}

function addNewRowTransfer(result_arr){
   var table = document.getElementById("myTable");
   var result = result_arr[0];
   var qty = 1;
   var total = parseFloat(qty) * (parseFloat(result[3]) - parseFloat("100"));
   
   var row = table.insertRow(-1);
   var cell1 = row.insertCell(0);
   var cell2 = row.insertCell(1);
   var cell3 = row.insertCell(2);
   var cell4 = row.insertCell(3);
   var cell5 = row.insertCell(4);
   var cell6 = row.insertCell(5);


   let id = "<input style='display: none;' type='text' class='md-form form-control' value='"+result[4]+"' readonly name='transfer[transfer_items]["+add_counter+"][item_id]'/>";
   let code = id+"<input type='text' class='md-form form-control' value='"+result[0]+"' readonly />";
   let name = "<input type='text' class='md-form form-control' value='"+result[1]+"' readonly />";
   let cat = "<input type='text' class='md-form form-control' value='"+result[2]+"' readonly />";
   let quantity = "<input type='number' min=1 class='md-form form-control' value='1' name='transfer[transfer_items]["+add_counter+"][quantity]'/>";
   let desc = "<input type='text' class='md-form form-control' value=''  name='transfer[transfer_items]["+add_counter+"][description]'/>";
   let remove = "<i class='fa fa-trash text-danger' onclick='removeThisRow(this)'></i>"; 
   cell1.innerHTML = code;
   cell2.innerHTML = name;
   cell3.innerHTML = cat;
   cell4.innerHTML = quantity;
   cell5.innerHTML = desc;
   cell6.innerHTML = remove;
   add_counter++;
   document.getElementById("itemId").value = "";
}
     

$(function () {
  $('#dark-mode').on('click', function (e) {

    e.preventDefault();
    $('h4, button').not('.check').toggleClass('dark-grey-text text-white');
    $('.list-panel a').toggleClass('dark-grey-text');

    $('footer, .card').toggleClass('dark-card-admin');
    $('body, .navbar').toggleClass('white-skin navy-blue-skin');
    $(this).toggleClass('white text-dark btn-outline-black');
    $('body').toggleClass('dark-bg-admin');
    $('h6, .card, p, td, th, i, li a, h4, input, label').not(
      '#slide-out i, #slide-out a, .dropdown-item i, .dropdown-item').toggleClass('text-white');
    $('.btn-dash').toggleClass('grey blue').toggleClass('lighten-3 darken-3');
    $('.gradient-card-header').toggleClass('white black lighten-4');
    $('.list-panel a').toggleClass('navy-blue-bg-a text-white').toggleClass('list-group-border');

  });
});


// var add_counter = gon.inv_count;
var add_counter = 0

var ctxP = document.getElementById("higher_sales").getContext('2d');
var myPieChart = new Chart(ctxP, {
  type: 'doughnut',
  data: {
    labels: gon.higher_item_cats_label,
    datasets: [{
      data: gon.higher_item_cats_data,
      backgroundColor: ["#F7464A", "#46BFBD", "#FDB45C", "#949FB1", "#4D5360"],
      hoverBackgroundColor: ["#FF5A5E", "#5AD3D1", "#FFC870", "#A8B3C5", "#616774"]
    }]
  },
  options: {
    responsive: true
  }
});

var ctxP = document.getElementById("lower_sales").getContext('2d');
var myPieChart = new Chart(ctxP, {
  type: 'doughnut',
  data: {
    labels: gon.lower_item_cats_label,
    datasets: [{
      data: gon.lower_item_cats_data,
      backgroundColor: ["rgba(255, 99, 132, 0.2)", "rgba(255, 159, 64, 0.2)",
        "rgba(255, 205, 86, 0.2)", "rgba(75, 192, 192, 0.2)", "rgba(54, 162, 235, 0.2)",
        "rgba(153, 102, 255, 0.2)", "rgba(201, 203, 207, 0.2)"
      ],
      hoverBackgroundColor: ["#FF5A5E", "#5AD3D1", "#FFC870", "#A8B3C5", "#616774"]
    }]
  },
  options: {
    responsive: true
  }
});


