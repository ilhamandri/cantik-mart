// setInterval(get_notification, 10000);

var separator = '<p class="medium">===========================================================</p>';

var header_cirata = '<!DOCTYPE html> <html> <head> <meta content="text/html;charset=utf-8" http-equiv="Content-Type"> <meta content="utf-8" http-equiv="encoding"> <style type="text/css"> table {table-layout:auto; width:100%;} td { font-size: 15px; padding: 0 !important; border-top: none !important;} </style> <title></title> </head> <body> ' + '<table widht: "100%;" ><tr><td style="text-align: left; vertical-align: middle;"><img src="/images/logo.png" style="width: 150px"/></td><td style="text-align: right;font-size: 12px !important;">' + 'PT. Cantik Berkah Sejahtera <br>' + 'NPWP: 53.925.657.9-409.000 <br>' +  'Jl. Cirata - Cilangkap, Ds. Cadassari<br> Kec. Tegalwaru, Kabupaten Purwakarta,<br>Jawa Barat'+'</td></tr></table>'+separator;

var header_plered = '<!DOCTYPE html> <html> <head> <meta content="text/html;charset=utf-8" http-equiv="Content-Type"> <meta content="utf-8" http-equiv="encoding"> <style type="text/css"> table {table-layout:auto; width:100%;} td { font-size: 15px; padding: 0 !important; border-top: none !important;} </style> <title></title> </head> <body> ' + '<table widht: "100%;" ><tr><td style="text-align: left; vertical-align: middle;"><img src="/images/logo.png" style="width: 150px"/></td><td style="text-align: right;font-size: 12px !important;">' + 'PT. Cantik Berkah Sejahtera <br>' + 'NPWP: 53.925.657.9-409.000 <br>' + 'Jl. Raya Plered, Purwakarta <br> Kec. Plered, Kabupaten Purwakarta, <br>Jawa Barat'+'</td></tr></table>'+separator;

var header_bendul = '<!DOCTYPE html> <html> <head> <meta content="text/html;charset=utf-8" http-equiv="Content-Type"> <meta content="utf-8" http-equiv="encoding"> <style type="text/css"> table {table-layout:auto; width:100%;} td { font-size: 15px; padding: 0 !important; border-top: none !important;} </style> <title></title> </head> <body> ' + '<table widht: "100%;" ><tr><td style="text-align: left; vertical-align: middle;"><img src="/images/logo.png" style="width: 150px"/></td><td style="text-align: right;font-size: 12px !important;">' + 'PT. Cantik Berkah Sejahtera <br>' + 'NPWP: 53.925.657.9-409.000 <br>' + 'Pasar Anyar Sukatani, Purwakarta <br> Kec. Sukatani, Kabupaten Purwakarta, <br>Jawa Barat'+'</td></tr></table>'+separator;

var head = ' <div class="col-sm-12 text-left"><table class="table">';

function printShift(total, cashier, time, cash, debit, n_trx, store_id,store_name){
  var data = "";  
  if (store_id == 2){
    data += header_cirata;
  } else if (store_id == 7){
    data += header_bendul;
  }else{
    data += header_plered;
  }
  data += '<table><tr><td style="text-align: center; font-size: 15px;">LAPORAN SHIFT</td></tr></table>'+separator;
  data += '<table><tr><td>Kasir</td> <td>:</td> <td>'+cashier+'</td></tr>';
  data += '<tr><td>Toko</td> <td>:</td> <td>'+store_name+'</td></tr>';
  data += '<tr><td>Waktu</td> <td>:</td> <td>'+time+'</td></tr>';
  data += '<tr><td>Jumlah Struk</td> <td>:</td> <td>'+n_trx+' x</td></tr>';
  data += '<tr><td colspan=3>'+separator+'</td></tr>';
  data += '<tr><td>TUNAI</td> <td>:</td> <td>'+splitRibuan(cash)+'</td></tr>';
  data += '<tr><td>DEBIT</td> <td>:</td> <td>'+splitRibuan(debit)+'</td></tr>';
  data += '<tr><td>TOTAL</td> <td>:</td> <td>'+splitRibuan(total)+'</td></tr>';
  data += '<tr><td>SELISIH</td> <td>:</td> <td><br><br><br></td></tr>';
  data += '</table>';
  data += separator;
  data += '<table><tr><td style="text-align: center;">TTD<br><br><br><br><br>Kepala Toko</td>';
  data += '<td style="text-align: center;">TTD<br><br><br><br><br>'+cashier+'</td></tr></table>';

  printHTML(data);
                 
}

function printHTML(html) {
  var wnd = window.open("about:blank", "", "_blank");
  wnd.document.write(html);
  wnd.print();
}


function splitRibuan(total){
  var bilangan = total;
 
 var reverse = bilangan.toString().split('').reverse().join(''),
 ribuan = reverse.match(/\d{1,3}/g);
 ribuan = ribuan.join('.').split('').reverse().join('');
 return ribuan;
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

function changePriceNormalEditItem(){
  buy = parseInt($("#buy").val().replaceAll(".",""));
  margin = parseFloat($("#margin").val());
  tax = parseInt($("#tax").val());

  base_price = buy + (buy*margin/100.0);
  ppn = base_price * tax / 100.0;
  new_price = base_price + ppn;
  var new_sell = formatangka_titik(Math.ceil(new_price/100)*100);
  
  $("#normal_sell").val(new_sell); 
  changeDiscountEditItem();
}

function changeDiscountEditItem(){
  buy = parseInt($("#buy").val().replaceAll(".",""));
  normal_sell = parseInt($("#normal_sell").val().replaceAll(".",""));
  margin = parseFloat($("#margin").val());
  tax = parseInt($("#tax").val());
  discount = parseInt($("#discount").val());

  base_price = buy + (buy*margin/100.0);
  if (discount < 100){
    discount = base_price * discount / 100.0;
  }

  new_price = normal_sell - discount;
  var new_sell = formatangka_titik(Math.ceil(new_price/100)*100);

  $("#sell").val(new_sell); 
}

function changePrice(id) {
  ppn_type = parseInt($("#ppn_type").val());

  var ids = gon.ids
  var receive = $("#"+id+"Receive").val();
  var price = $("#"+id+"Price").val();
  var disc_1 = $("#"+id+"Disc1").val();
  var disc_2 = $("#"+id+"Disc2").val();
  var margin = $("#"+id+"Margins").val();
  var ppn = $("#ppn").val();
  var globalDisc = $("#globalDisc").val();

  if(disc_1 <= 99){
    disc_1 = parseFloat(price * disc_1 / 100);
    price -= disc_1;
  }else{
    price -= disc_1/receive;
  }

  if(disc_2 <= 99){
    disc_2 = parseFloat(price * disc_2 / 100);
    price -= disc_2;
  }else{
    price -= disc_2/receive;
  }

  var price_supp = 0;
  if(ppn_type==2){
    price_supp = (receive * (price + parseFloat(price*ppn/100)));
  }else{
    price_supp = receive * price;
  }
  $("#"+id+"Total").val(formatangka_titik(parseInt(price_supp)));

  base_price = price;
  var price_before_tax = base_price+(base_price*margin/100);
  var price_after_tax = price_before_tax + (price_before_tax*ppn/100);
  var new_sell = formatangka_titik(Math.ceil(price_after_tax/100)*100);

  $("#"+id+"Sell").val(new_sell);  

  g_total = 0
  for (i = 0; i < ids.length; i++) {
    g_total += parseInt($("#"+ids[i]+"Total").val().replaceAll(".",""));
  } 
  if(globalDisc<=99){
    g_total -= parseInt(g_total * globalDisc / 100 );
    new_sell -= parseInt(new_sell * globalDisc / 100 );
  }else{
    g_total -= globalDisc;
  }


  $("#grand_total_all").html(formatangka_titik(parseInt(g_total)));
}

function codePrice(){
  var alphabet = gon.alphabet;
  code = $("#code").val().toUpperCase();
  price = "";
  for(var i=0; i < code.length; i++){
    code_val = alphabet[code.charAt(i)];
    if(code_val==undefined){
      $("#price").html("- - E R R O R - -");
      return 
    }
    price += code_val;
  }
  int_price = parseInt(price);
  qty = $("#qty").val();
  if(qty>1){
    sell = Math.ceil((int_price / qty) / 100 )*100;
    $("#price").html(formatangka_titik(int_price) + " / " + formatangka_titik(sell))
  }else{
    $("#price").html(formatangka_titik(int_price));
  }
}

function changeSalary(){
  if(gaji==0){
    return false;
  }

  pay_receivable = parseInt($("#pay_receivable").val());
  pay_kasbon = parseInt($("#pay_kasbon").val());
  bonus = parseInt($("#bonus").val());

  jht = 0;
  // 2% dari gaji
  if($('#jht').is(':checked')){
    jht = 0.02 * gaji;
  }

  jp = 0
  // 1% dari gaji
  if($('#jp').is(':checked')){
    jp = 0.01 * gaji;
  }

  receive = gaji - pay_kasbon - pay_receivable + bonus - jht - jp;
  $("#receive").html("TOTAL : " + formatangka_titik(receive));
}

var gaji = 0;
function getUserSalary(user) {
  var user_id = user.value
  $.ajax({ 
    type: 'GET', 
    url: '/api/get_user_salary?id='+user_id, 
    success: function (result) { 
      gaji = parseFloat(result[0].replaceAll(".",""));
      $("#salary").html("GAJI : "+result[0]);
      $("#debt").html("HUTANG : "+result[1]);
      $("#kasbon").html("KASBON : "+result[2]);

      if(result[1]==0){
        $("#pay_receivable").val(0);
        $('#pay_receivable').attr('readonly', true);
      }else{
        debt = parseInt(result[1].replaceAll(".",""));
        if(debt > gaji){
          $('#pay_receivable').attr('max', gaji);
        }else{
          $('#pay_receivable').attr('max', debt);
        }
      }

      if(result[2]==0){
        $("#pay_kasbon").val(0);
        $('#pay_kasbon').attr('readonly', true);
      }else{
        kasbon = parseInt(result[2].replaceAll(".",""));
        if(kasbon > gaji){
          $('#pay_receivable').attr('max', gaji);
        }else{
          $('#pay_receivable').attr('max', kasbon);
        }
      }

      changeSalary();
    }
  });
}


function returTotal(input){
  var table = document.getElementById("myTable");
  var table_length = table.rows.length;
  var total = 0;
  for (var i = 1; i < table_length; i++) {
    total += parseInt(table.rows[i].cells[4].childNodes[1].value);
  }
  var total_text = formatangka_titik(total);
  document.getElementById("total").innerHTML = total_text;
}

function changeSellOrder(id){
  var totals = parseInt($("#"+id+"Total").html());
  var receive = $("#"+id+"Receive").val();
  var base_price = parseInt(totals / receive);
  var new_sell = $("#"+id+"Sell").val();
  if(new_sell<base_price){
    changePrice(id);
    alert("Harga JUAL : HARUS LEBIH BESAR dari harga BELI")
  }
}



function complain_check(index){
  var qty = parseInt($("#quantity"+index).val());
  var complain = parseInt($("#complain"+index).val());
  var replace = parseInt($("#replace"+index).val());
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
    total_text.innerHTML = "TAMBAH : Rp. "+formatangka_titik(new_total)+",00";
  }else if (new_total==0){
    total_text.style.color = "black";
    total_text.innerHTML = "TIDAK ADA TAMBAHAN";
  }else{
    total_text.style.color = "red";
    total_text.innerHTML = "KURANG : Rp. "+formatangka_titik(new_total)+",00";
  }

  if(new_total>=0){
    $("#submitButton").show();
  }else{
    $("#submitButton").hide();
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
   
   var row = table.insertRow(1);
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
   let quantity = "<input step='0.05' type='number' readonly min=1 class='md-form form-control' value='"+qty+"' name='complain[new_complain_items]["+add_counter+"][quantity]'/>"
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
     var store_id = $("#storeId").val();
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
     }else if (table_types == "transfer") {
      $.ajax({
         method: "GET",
         cache: false,
         url: "/api/transfer?search=" + item_id+"&target="+store_id,
         success: function(result_arr) {
            if(result_arr == ""){
              document.getElementById("itemId").value = "";
              alert("Data Barang Tidak Ditemukan / Barang merupakan barang lokal")
              return
            }else{
                addNewRowTransfer(result_arr);
             }
         },
         error: function(error) {
             document.getElementById("itemId").value = "";
             document.getElementById("item_qty").value = 1;
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
              alert("Data Barang Tidak Ditemukan / Barang merupakan barang lokal")
              return
            }else{
               if (table_types == "order"){
                addNewRowOrder(result_arr);
               }
               else if(table_types == "retur"){
                addNewRowRetur(result_arr);
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
   
   var row = table.insertRow(1);
   var cell1 = row.insertCell(0);
   var cell2 = row.insertCell(1);
   var cell3 = row.insertCell(2);
   var cell4 = row.insertCell(3);
   var cell5 = row.insertCell(4);
   var cell6 = row.insertCell(5);


   let id = "<input style='display: none;' type='text' class='md-form form-control' value='"+result[4]+"' readonly name='order[order_items]["+add_counter+"][item_id]'/>";
   let code = id+result[0]+"<input style='display:none;' type='text' class='md-form form-control' value='"+result[0]+"' readonly name='order[order_items]["+add_counter+"][code]'/>";
   let name = result[1]+"<input style='display: none;' type='text' class='md-form form-control' value='"+result[1]+"' readonly name='order[order_items]["+add_counter+"][name]'/>";
   let cat = result[2]+"<input style='display: none;' type='text' class='md-form form-control' value='"+result[2]+"' readonly name='order[order_items]["+add_counter+"][item_cat]'/>";
   let quantity = "<input type='number' min=1 class='md-form form-control' value='1' name='order[order_items]["+add_counter+"][quantity]'/>";
   let price = "<input type='number' class='md-form form-control' value='"+result[3]+"' min=100 name='order[order_items]["+add_counter+"][price]'  step='0.05'/>";
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
   
   var row = table.insertRow(1);
   var cell1 = row.insertCell(0);
   var cell2 = row.insertCell(1);
   var cell3 = row.insertCell(2);
   var cell4 = row.insertCell(3);
   var cell5 = row.insertCell(4);
   var cell6 = row.insertCell(5);


   let id = "<input style='display: none;' type='text' class='md-form form-control' value='"+result[4]+"' readonly name='retur[retur_items]["+add_counter+"][item_id]'/>";
   let code = id+result[0]+"<input type='text' style='display:none;' class='md-form form-control' value='"+result[0]+"' readonly name='retur[retur_items]["+add_counter+"][code]'/>";
   let name = result[1]+"<input type='text' style='display: none' class='md-form form-control' value='"+result[1]+"' readonly name='retur[retur_items]["+add_counter+"][name]'/>";
   let cat = result[2]+"<input style='display: none;' type='text' class='md-form form-control' value='"+result[2]+"' readonly name='retur[retur_items]["+add_counter+"][item_cat]'/>";
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
   
   var row = table.insertRow(1);
   var cell1 = row.insertCell(0);
   var cell2 = row.insertCell(1);
   var cell3 = row.insertCell(2);
   var cell4 = row.insertCell(3);
   var cell5 = row.insertCell(4);
   var cell6 = row.insertCell(5);
   var cell7 = row.insertCell(6);


   let id = "<input style='display: none;' type='text' class='md-form form-control' value='"+result[4]+"' readonly name='transfer[transfer_items]["+add_counter+"][item_id]'/>";
   let code = id+result[0]+"<input style='display: none;' type='text' class='md-form form-control' value='"+result[0]+"' readonly />";
   let name = result[1]+"<input style='display: none;' type='text' class='md-form form-control' value='"+result[1]+"' readonly />";
   let cat = result[2]+"<input style='display: none;' type='text' class='md-form form-control' value='"+result[2]+"' readonly />";
   let stock = result[6]+"<input style='display: none;' type='text' class='md-form form-control' value='"+result[6]+"' />";
   let quantity = "<input type='number' min=1 class='md-form form-control' value='1' name='transfer[transfer_items]["+add_counter+"][quantity]'/>";
   let desc = "<input type='text' class='md-form form-control' value=''  name='transfer[transfer_items]["+add_counter+"][description]'/>";
   let remove = "<i class='fa fa-trash text-danger' onclick='removeThisRow(this)'></i>"; 
   cell1.innerHTML = code;
   cell2.innerHTML = name;
   cell3.innerHTML = cat;
   cell4.innerHTML = stock;
   cell5.innerHTML = quantity;
   cell6.innerHTML = desc;
   cell7.innerHTML = remove;
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




